/**
 * @author Daniel Reto
 * @description Batch class to free Stock in OCI after the End Date
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      13/05/2024      ECOMM-1126: Original version
 * Daniel Reto      17/06/2024      set new Parameters to be possible to reuse this batch
 **/
public with sharing class COMM_Async_SubscFreeStockOnEndDate extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_DAYS_BEFORE_END_DATE_OCI = 'Days To Add Before End Date - Free Stock';
    @TestVisible
    private final static String PARAMETER_DAYS_BEFORE_END_DATE_SUBSCRIPTION_UPDATE = 'Days To Add Before End Date - Update Subscription';
    @TestVisible
    private final static String PARAMETER_RECORD_TYPE_FILTER = 'Record Type';

    private COMM_IREP_Capacity capacityRep;
    private COMM_IREP_Subscription subscriptionRep;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{ Product2.COMM_ParentProduct__c, Product2.ProductCode, Product2.IsActive };
    public static final List<SObjectField> RECORDTYPE_FIELDS = new List<SObjectField>{ RecordType.DeveloperName };
    public static final List<SObjectField> CASE_FIELDS = new List<SObjectField>{ Case.Id, Case.Status };

    private Integer daysBeforeEndDateOCI;
    private Integer daysBeforeEndDateSubscriptionUpdate;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SubscFreeStockOnEndDate() {
        this.capacityRep = new COMM_REP_Capacity();
        this.subscriptionRep = new COMM_REP_Subscription();
    }

    @testVisible
    private COMM_Async_SubscFreeStockOnEndDate(
        COMM_IREP_Capacity capacityRep,
        COMM_IREP_Subscription subscriptionRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.capacityRep = capacityRep;
        this.subscriptionRep = subscriptionRep;
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

        SObjectType sobjType = Schema.getGlobalDescribe().get('COMM_Subscription__c');
        daysBeforeEndDateOCI = Integer.valueOf(getParameterValue(PARAMETER_DAYS_BEFORE_END_DATE_OCI));
        daysBeforeEndDateSubscriptionUpdate = Integer.valueOf(getParameterValue(PARAMETER_DAYS_BEFORE_END_DATE_SUBSCRIPTION_UPDATE));
        String recordTypeFilter = getParameterValue(PARAMETER_RECORD_TYPE_FILTER);
        FW_QueryBuilder parentQuery = new FW_QueryBuilder(Case.SObjectType)
            .selectFields(CASE_FIELDS)
            .selectParentFields(Case.RecordTypeId, new List<SObjectField>{ RecordType.DeveloperName });

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, PRODUCT_FIELDS)
            .selectParentFields(COMM_Subscription__c.RecordTypeId, RECORDTYPE_FIELDS)
            .selectFields(COMM_Subscription__c.COMM_ActiveSubscriptionRequest__c, parentQuery)
            .setWhere(
                '( COMM_Status__c = \'' +
                    COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED +
                    '\' OR COMM_Status__c = \'' +
                    COMM_DO_Subscription.STATUS_ARCHIEVED +
                    '\' ) AND (COMM_EndDate__c < ' +
                    String.valueOf(System.now().addDays(daysBeforeEndDateSubscriptionUpdate).dateGMT()).left(10) +
                    ' OR COMM_EndDate__c < ' +
                    String.valueOf(System.now().addDays(daysBeforeEndDateOCI).dateGMT()).left(10) +
                    ') AND RecordType.DeveloperName = \'' +
                    recordTypeFilter +
                    '\' AND COMM_OCIEndDate__c != null'
            )
            .whereEquals('COMM_Active__c', true);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param productsList List of Capacity records (distinct ProductCodes) that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<COMM_Subscription__c> subscriptionsList) {
        if (Test.isRunningTest()) {
            if (subscriptionsList[0].RecordType.DeveloperName == COMM_DO_Subscription.RECORDTYPE_PARTNER) {
                daysBeforeEndDateOCI = 0;
                daysBeforeEndDateSubscriptionUpdate = 0;
            } else if (subscriptionsList[0].RecordType.DeveloperName == COMM_DO_Subscription.RECORDTYPE_DIRECT_SALES) {
                daysBeforeEndDateOCI = 15;
                daysBeforeEndDateSubscriptionUpdate = 0;
            }
        }
        Set<String> parentProductIdSet = new Set<String>();
        Map<String, List<COMM_Subscription__c>> subscriptionListByProductCodeMap = new Map<String, List<COMM_Subscription__c>>();
        List<COMM_Capacity__c> capacitiesList = new List<COMM_Capacity__c>();
        Map<String, Date> validToByParentProductIdMap = new Map<String, Date>();
        // Boolean variable to identify if a update must happen to updated the related Subscription Records
        Boolean requiresSubscriptionUpdate = false;

        // create a list of Subscriptions by Parent Product Code, to be possible to send the correct capacity being released to OCI + update subscription records to be deactivated (Status and Active fields)
        for (COMM_Subscription__c subscriptionRecord : subscriptionsList) {
            // if subscription record type is Partner, the record will be updated + OCI stock will be free (only for Subscriptions with Status "Process Concluded")
            if (subscriptionRecord.RecordType.DeveloperName == COMM_DO_Subscription.RECORDTYPE_PARTNER) {
                if (subscriptionRecord.COMM_Status__c == COMM_DO_Subscription.STATUS_ARCHIEVED) {
                    subscriptionRecord.COMM_Active__c = false;
                    subscriptionRecord.COMM_OCIEndDate__c = subscriptionRecord.COMM_EndDate__c;
                    requiresSubscriptionUpdate = true;
                } else if (subscriptionRecord.COMM_Status__c == COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED) {
                    if(subscriptionRecord.COMM_Product__r.isActive){
                        if (subscriptionListByProductCodeMap.containsKey(subscriptionRecord.COMM_Product__r.ProductCode)) {
                            subscriptionListByProductCodeMap.get(subscriptionRecord.COMM_Product__r.ProductCode).add(subscriptionRecord);
                        } else {
                            subscriptionListByProductCodeMap.put(
                                subscriptionRecord.COMM_Product__r.ProductCode,
                                new List<COMM_Subscription__c>{ subscriptionRecord }
                            );
                        }
                        parentProductIdSet.add(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                    }
                    subscriptionRecord.COMM_Active__c = false;
                    subscriptionRecord.COMM_Status__c = COMM_DO_Subscription.STATUS_ARCHIEVED;
                    subscriptionRecord.COMM_OCIEndDate__c = subscriptionRecord.COMM_EndDate__c;
                    requiresSubscriptionUpdate = true;
                }
            }
            // if subscription record type is Direct Sales, the record will be updated (if the End Date is overdue) + OCI stock will be free (only if today date is End Date - daysBeforeEndDateOCI AND any case record is open to renew the subscription)
            if (subscriptionRecord.RecordType.DeveloperName == COMM_DO_Subscription.RECORDTYPE_DIRECT_SALES) {
                // only if there is no pending open case the subscription can be terminated and stock released
                if (
                    subscriptionRecord.COMM_ActiveSubscriptionRequest__c == null ||
                    subscriptionRecord.COMM_ActiveSubscriptionRequest__r.RecordType.DeveloperName !=
                    COMM_DO_Case.RECURRING_PUBLIC_SUBSCRIPTION_REQUEST_RT ||
                    (subscriptionRecord.COMM_ActiveSubscriptionRequest__r.RecordType.DeveloperName ==
                    COMM_DO_Case.RECURRING_PUBLIC_SUBSCRIPTION_REQUEST_RT &&
                    subscriptionRecord.COMM_ActiveSubscriptionRequest__r.Status != COMM_DO_Case.WAITING_CONCLUSION_STATUS)
                ) {
                    if (subscriptionRecord.COMM_EndDate__c < System.now().addDays(daysBeforeEndDateSubscriptionUpdate).dateGMT()) {
                        subscriptionRecord.COMM_Status__c = COMM_DO_Subscription.STATUS_ARCHIEVED;
                        subscriptionRecord.COMM_Active__c = false;
                        requiresSubscriptionUpdate = true;
                    }
                    if (
                        subscriptionRecord.COMM_OCIEndDate__c > subscriptionRecord.COMM_EndDate__c &&
                        subscriptionRecord.COMM_EndDate__c < System.now().addDays(daysBeforeEndDateOCI).dateGMT()
                    ) {
                        if(subscriptionRecord.COMM_Product__r.isActive){
                            if (subscriptionListByProductCodeMap.containsKey(subscriptionRecord.COMM_Product__r.ProductCode)) {
                                subscriptionListByProductCodeMap.get(subscriptionRecord.COMM_Product__r.ProductCode).add(subscriptionRecord);
                            } else {
                                subscriptionListByProductCodeMap.put(
                                    subscriptionRecord.COMM_Product__r.ProductCode,
                                    new List<COMM_Subscription__c>{ subscriptionRecord }
                                );
                            }
                            parentProductIdSet.add(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                        }
                        subscriptionRecord.COMM_OCIEndDate__c = subscriptionRecord.COMM_EndDate__c;
                        requiresSubscriptionUpdate = true;
                    }
                }
            }
        }

        List<Error_Log__c> errorListToWrite = new List<Error_Log__c>();

        // if at least one Parent Product Code is found we must release the capacity on OCI
        if (!parentProductIdSet.isEmpty()) {
            // get capacity related records
            capacitiesList = capacityRep.getCapacityByProductIds(parentProductIdSet);

            // map Valid to date on each Capacity for each Parent Product, to be able to identify the End date of each Parent Product
            for (COMM_Capacity__c capacityRecord : capacitiesList) {
                validToByParentProductIdMap.put(capacityRecord.COMM_Product__c, capacityRecord.COMM_ValidTo__c.date());
            }

            // set input request to send for OCI
            COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
            input.expirationSeconds = 0;
            input.product = new List<COMM_WS_ReservationInput.Product>();

            // generate COMM_WS_ReservationInput wrapper for each Subscription being deactivated
            for (String productCode : subscriptionListByProductCodeMap.keySet()) {
                for (COMM_Subscription__c subscriptionRecord : subscriptionListByProductCodeMap.get(productCode)) {
                    COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
                    product.productId = productCode;
                    product.startDate = COMM_GEN_Utility.generateDateTimeDataType(subscriptionRecord.COMM_EndDate__c.addDays(1));
                    product.endDate = COMM_GEN_Utility.generateDateTimeDataType(
                        validToByParentProductIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c)
                    );
                    input.product.add(product);
                }
            }

            // OCI capacity release
            if(!input.product.isEmpty()){
                try{
            COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
            ociReservation.release(input);
                }
                catch (Exception e){                    
                    Error_Log__c error = new Error_Log__c();
                    error.Job_Execution__c = bc.getJobId();
                    error.Error_Message__c = e.getMessage();
                    error.StackTraceString__c = e.getStackTraceString();
                    error.Category__c = 'Apex_Batch';
                    error.Exception_Type_Name__c = e.getTypeName();
                    error.Job_Scope__c = (new Map<Id,COMM_Subscription__c>(subscriptionsList)).keySet().toString();
                }
            }
        }

        //Subscription update
        if (requiresSubscriptionUpdate) {
            subscriptionRep.updateSObjects(subscriptionsList);
        }

        //insert errors
        if(!errorListToWrite.isEmpty()){
            FW_REP_ErrorLog errorRepository = new FW_REP_ErrorLog();
            errorRepository.insertSObjects(errorListToWrite);
        }
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}