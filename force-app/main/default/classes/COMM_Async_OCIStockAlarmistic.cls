/**
 * @author Daniel Reto
 * @description Batch class to check Stock in OCI based on product COMM_Capacity__c
 * Each product can have multiple configurations.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto             07/05/2024		ECOMM-281: Original version
 **/
public with sharing class COMM_Async_OCIStockAlarmistic extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_NUMBER_OF_DAYS_TO_CHECK_PRIOR = 'NumberOfDaysToCheckPrior'; // 0
    @TestVisible
    private final static String PARAMETER_NUMBER_OF_DAYS_TO_CHECK_AFTER = 'NumberOfDaysToCheckAfter'; // 30
    @TestVisible
    private final static String PARAMETER_EMAILTEMPLATE = 'EmailTemplate'; // COMM_Internal_CapacityAlarmistic_pt_PT
    @TestVisible
    private final static String PARAMETER_QUEUE = 'QueueName'; // COMM_SubscriptionRequestANAAdmin

    private final static List<String> PRODUCT_FAMILY_TO_PROCESS_LIST = new List<String>{
        COMM_OCI_Constants.PRODUCT_FAMILY_PARKING,
        COMM_OCI_Constants.PRODUCT_FAMILY_LOUNGE,
        COMM_OCI_Constants.PRODUCT_FAMILY_FAST_TRACK,
        COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION
    };

    private COMM_IREP_ProductLocationStock productLocationsStockRep;
    private COMM_IREP_EmailTemplate emailTemplateRep;
    private COMM_IREP_OrgWideEmailAddress orgWideAddressNoReply;
    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OCIStockAlarmistic() {
        this.productLocationsStockRep = new COMM_REP_ProductLocationStock();
        this.emailTemplateRep = new COMM_REP_EmailTemplate();
        this.orgWideAddressNoReply = new COMM_REP_OrgWideEmailAddress();
    }

    @testVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_Async_OCIStockAlarmistic(
        COMM_IREP_ProductLocationStock productLocationsStockRep,
        COMM_IREP_EmailTemplate emailTemplateRep,
        COMM_IREP_OrgWideEmailAddress orgWideAddressNoReply,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.productLocationsStockRep = productLocationsStockRep;
        this.emailTemplateRep = emailTemplateRep;
        this.orgWideAddressNoReply = orgWideAddressNoReply;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field has a date set a specific number of months ago.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());
        FW_QueryBuilder query;

        try {
            query = new FW_QueryBuilder(COMM_Capacity__c.SObjectType)
            .selectFields(new List<String>{ 'Id', 'COMM_Product__c' })
            .selectParentFields(COMM_Capacity__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode })
            .whereEquals('COMM_Active__c', true)
            .whereEquals('COMM_ProcessStatus__c', COMM_DO_Capacity.PROCESS_STATUS_COMPLETED)
            .whereIn('COMM_Product__r.Family', PRODUCT_FAMILY_TO_PROCESS_LIST)
            .whereEquals('COMM_Product__r.IsActive', true);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error on Start: ', 'COMM_Async_OCIStockAlarmistic');
        }
        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param productsList List of Capacity records (distinct ProductCodes) that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<COMM_Capacity__c> capacityList) {
        
        Integer numberOfDaysToCheckPrior = Integer.valueOf(getParameterValue(PARAMETER_NUMBER_OF_DAYS_TO_CHECK_PRIOR));
        Integer numberOfDaysToCheckAfter = Integer.valueOf(getParameterValue(PARAMETER_NUMBER_OF_DAYS_TO_CHECK_AFTER));
        COMM_WS_AvailabilityInput input = new COMM_WS_AvailabilityInput();
        List<COMM_WS_AvailabilityInput.Product> productRecordInputList = new List<COMM_WS_AvailabilityInput.Product>();
        Map<String,String> productIdByProductCodeMap = new Map<String,String>();

        for(COMM_Capacity__c capacityRecord : capacityList){
            if(!productIdByProductCodeMap.containsKey(capacityRecord.COMM_Product__r.ProductCode)){
                COMM_WS_AvailabilityInput.Product productRecordInput = new COMM_WS_AvailabilityInput.Product();
                productRecordInput.productId = capacityRecord.COMM_Product__r.ProductCode;
                productRecordInput.startDate = DateTime.newInstanceGmt(System.today().year(), System.today().month(), System.today().day(),0,0,0).addDays(-numberOfDaysToCheckPrior);
                productRecordInput.endDate = DateTime.newInstanceGmt(System.today().year(), System.today().month(), System.today().day(),23,0,0).addDays(numberOfDaysToCheckAfter);
                productRecordInputList.add(productRecordInput);
                productIdByProductCodeMap.put(capacityRecord.COMM_Product__r.ProductCode, capacityRecord.COMM_Product__c);
            }
        }
        input.products = productRecordInputList;

        COMM_SL_WS_OCIAvailability ociAvailability = new COMM_SL_WS_OCIAvailability();
        COMM_WS_AvailabilityOutput output = ociAvailability.checkAvailability(input, false);
        List<COMM_ProductLocationStock__c> productLocationStockUpsertList = new List<COMM_ProductLocationStock__c>();

        for(COMM_WS_AvailabilityOutput.InventoryRecord inventoryRecord : output.inventory){
            for(COMM_WS_AvailabilityOutput.ProductRecord productRecord : inventoryRecord.productList){
                COMM_ProductLocationStock__c productLocationStockRecord = new COMM_ProductLocationStock__c();
                productLocationStockRecord.COMM_Product__c = productIdByProductCodeMap.get(inventoryRecord.productCode);
                productLocationStockRecord.COMM_ProductLocation__c = productRecord.externalId + '_' + productRecord.locationIdentifier;
                productLocationStockRecord.COMM_Location__c = productRecord.locationIdentifier;
                productLocationStockRecord.COMM_ReservedStock__c = productRecord.reserved;
                productLocationStockRecord.COMM_StockOnHand__c = productRecord.onHand;
                String dateString = productRecord.externalId.substringAfterLast('_');
                productLocationStockRecord.COMM_StockDate__c = Date.valueOf(dateString.subString(0, 4) + '-' + dateString.subString(4, 6) + '-' + dateString.subString(6, 8));
                productLocationStockUpsertList.add(productLocationStockRecord);
            }
        }

        List<COMM_ProductLocationStock__c> productLocationStockList = productLocationsStockRep.getProductLocationStockToErase(productIdByProductCodeMap.values(), System.now().dateGMT());

        if(!productLocationStockList.isEmpty() && productLocationStockList != null){
            productLocationsStockRep.deleteSObjects(productLocationStockList);
        }

        // update processed capacity records with JobId, Status and Status Message
        if (!productLocationStockUpsertList.isEmpty()) {
            productLocationsStockRep.upsertSObjects(productLocationStockUpsertList, COMM_ProductLocationStock__c.COMM_ProductLocation__c);
        }
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());

        List<Messaging.SingleEmailMessage> emailsToSendList = new List<Messaging.SingleEmailMessage>();
        List<COMM_ProductLocationStock__c> productLocationStockList = productLocationsStockRep.getProductLocationStockToErase();

        if(productLocationStockList != null && !productLocationStockList.isEmpty()){
            Map<Id, COMM_ProductLocationStock__c> productLocationStockByProductIdMap = new Map<Id, COMM_ProductLocationStock__c>();
            Map<String, Set<Id>> productIdListByProductFamilyMap = new Map<String, Set<Id>>();
            for(COMM_ProductLocationStock__c productLocationStockRecord : productLocationStockList){
                if(
                    !productLocationStockByProductIdMap.containsKey(productLocationStockRecord.COMM_Product__c)
                    ||
                    productLocationStockByProductIdMap.get(productLocationStockRecord.COMM_Product__c).COMM_Product__r.COMM_Alarmistic__c < productLocationStockRecord.COMM_Product__r.COMM_Alarmistic__c
                ){
                    productLocationStockByProductIdMap.put(productLocationStockRecord.COMM_Product__c, productLocationStockRecord);
                }
                if(!productIdListByProductFamilyMap.containsKey(productLocationStockRecord.COMM_Product__r.Family)){
                    productIdListByProductFamilyMap.put(productLocationStockRecord.COMM_Product__r.Family, new Set<Id>{ productLocationStockRecord.COMM_Product__c });
                } else {
                    productIdListByProductFamilyMap.get(productLocationStockRecord.COMM_Product__r.Family).add(productLocationStockRecord.COMM_Product__c);
                }
            }

            String emailTemplateBodyReplacement = '';

            for(String productFamily : productIdListByProductFamilyMap.keySet()){
                emailTemplateBodyReplacement += '<strong>' + productFamily + ':</strong><br /><br /><ul>';
                for(Id productId : productIdListByProductFamilyMap.get(productFamily)){
                    emailTemplateBodyReplacement += COMM_GEN_Utility.generateHrefEmailTemplate(productId, productLocationStockByProductIdMap.get(productId).COMM_Product__r.Name);
                }
                emailTemplateBodyReplacement += '<br /><br />';
            }

            if(String.isNotBlank(emailTemplateBodyReplacement)){

                //Generate Email from Template
                List<EmailTemplate> emailTemplateList = emailTemplateRep.getEmailTemplateByNames(new Set<String>{ getParameterValue(PARAMETER_EMAILTEMPLATE) });
                Id orgWideAddressNoReplyId = orgWideAddressNoReply.getDefaultNoReplyAddress()?.get(0)?.Id;
                Messaging.SingleEmailMessage emailFromTemplate = Messaging.renderStoredEmailTemplate(emailTemplateList.get(0).Id, null, null);

                emailFromTemplate.setSubject(emailFromTemplate.getSubject());
                //Send Email to Address. If empty, sent to User Record.
                emailFromTemplate.setToAddresses( Test.isRunningTest() ? new List<String> { 'test@test.com.invalid' } : COMM_GEN_Utility.getEmailsFromQueue(getParameterValue(PARAMETER_QUEUE)));
                if (String.isNotBlank(orgWideAddressNoReplyId)) {
                    //Send Email with Default No-Reply Org Wide Address if it was provided
                    emailFromTemplate.setOrgWideEmailAddressId(orgWideAddressNoReplyId);
                }
                emailFromTemplate.setSaveAsActivity(true);
                emailFromTemplate.setUseSignature(false);

                // Replate Email Template Body
                String htmlBody = emailFromTemplate.getHtmlBody();
                htmlBody = htmlBody.replace(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_LIST_PRODUCT_BY_FAMILY, emailTemplateBodyReplacement);
                emailFromTemplate.setHtmlBody(htmlBody);

                emailsToSendList.add(emailFromTemplate);
            }
        }
        if(!emailsToSendList.isEmpty()){
            Messaging.sendEmail(emailsToSendList, true);
        }
    }
}