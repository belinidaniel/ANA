/**
 * @author Daniel Reto
 * @description Batch class to create Stock in OCI for subscritions. This is to setup the initial stock of migrated subscriptions.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/05/2024      Original version
 * Daniel Reto      06/06/2024      Hotfix
 **/
public with sharing class COMM_Async_SubscOCICreateStock extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    // @TestVisible
    // private final static String PARAMETER_DAYS_TO_ADD = 'DaysToAdd'; // should be set with 15 days

    private COMM_IREP_Capacity capacityRep;
    private COMM_IREP_Subscription subscriptionRep;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{ Product2.COMM_ParentProduct__c, Product2.ProductCode };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SubscOCICreateStock() {
        this.capacityRep = new COMM_REP_Capacity();
        this.subscriptionRep = new COMM_REP_Subscription();
    }

    @testVisible
    private COMM_Async_SubscOCICreateStock(
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

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, PRODUCT_FIELDS)
            .whereEquals('COMM_Status__c', COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED)
            .whereEquals('COMM_Active__c', true)
            .whereEquals('COMM_SetupInitialStock__c', 'TO PROCESS');

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param productsList List of Capacity records (distinct ProductCodes) that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<COMM_Subscription__c> subscriptionList) {
        Set<String> productSet = new Set<String>();

        for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
            productSet.add(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
        }

        List<COMM_Capacity__c> capacityList = capacityRep.getCapacityByProductIds(productSet);

        Map<String, DateTime> validToByParentIdMap = new Map<String, DateTime>();
        Map<Id, String> productCodeByParentIdMap = new Map<Id, String>();

        for (COMM_Capacity__c capacityRecord : capacityList) {
            validToByParentIdMap.put(capacityRecord.COMM_Product__c, capacityRecord.COMM_ValidTo__c);
            productCodeByParentIdMap.put(capacityRecord.COMM_Product__c, capacityRecord.COMM_Product__r.ProductCode);
        }

        if (subscriptionList != null && !subscriptionList.isEmpty()) {
            COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
            input.expirationSeconds = 0;
            input.product = new List<COMM_WS_ReservationInput.Product>();

            for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
                DateTime ociEndDateValue = DateTime.now();
                if (validToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c) > ociEndDateValue) {
                    COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
                    product.productId = productCodeByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                    product.startDate = ociEndDateValue;
                    product.endDate = validToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                    input.product.add(product);
                }
                subscriptionRecord.COMM_OCIEndDate__c = validToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c).date();
                subscriptionRecord.COMM_SetupInitialStock__c = 'PROCESSED';
            }

            if (!input.product.isEmpty()) {
                COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
                ociReservation.reserve(input, false);
            }
            if (!subscriptionList.isEmpty()) {
                subscriptionRep.updateSObjects(subscriptionList);
            }
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