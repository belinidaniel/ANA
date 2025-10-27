/**
 * @author Daniel Reto
 * @description Batch class to free Stock in OCI based on Susbscription cancelation
 * Each product can have multiple configurations. All Product configurations need to be processed within the same thread.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      09/04/2024      ECOMM-192: Original version
 * Daniel Reto      17/06/2024      New Parameter added
 **/
public with sharing class COMM_Async_SubscriptionCancelFreeStock extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_DAYS_TO_ADD = 'DaysToAdd'; // should be set with 15 days
    @TestVisible
    private final static String PARAMETER_RECORD_TYPE = 'RecordType'; // should be set COMM_Partner or COMM_DirectSales

    private COMM_IREP_Capacity capacityRep;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{ Product2.COMM_ParentProduct__c, Product2.ProductCode };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SubscriptionCancelFreeStock() {
        this.capacityRep = new COMM_REP_Capacity();
    }

    @testVisible
    private COMM_Async_SubscriptionCancelFreeStock(
        COMM_IREP_Capacity capacityRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.capacityRep = capacityRep;
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
        Integer daysToAdd = Integer.valueOf(getParameterValue(PARAMETER_DAYS_TO_ADD));
        String cancellationDateValue = String.valueOf(Date.today().addDays(-daysToAdd)).split(' ').get(0);

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, PRODUCT_FIELDS)
            .setWhere('COMM_CancellationDate__c = ' + cancellationDateValue)
            .whereEquals('RecordType.DeveloperName', getParameterValue(PARAMETER_RECORD_TYPE));

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
        // Add all product Codes into a List
        Set<String> parentProductIdSet = new Set<String>();
        Map<String, List<COMM_Subscription__c>> subscriptionByProductCodeMap = new Map<String, List<COMM_Subscription__c>>();
        List<COMM_Capacity__c> capacitiesList = new List<COMM_Capacity__c>();
        Map<String, Date> validToByParentProductIdMap = new Map<String, Date>();

        // create a list of Subscriptions by Parent Product Code, to be possible to send the correct capacity being released to OCI
        for (COMM_Subscription__c subscriptionRecord : subscriptionsList) {
            if (subscriptionRecord.COMM_Status__c == COMM_DO_Subscription.STATUS_ARCHIEVED) {
                if(subscriptionByProductCodeMap.containsKey(subscriptionRecord.COMM_Product__r.ProductCode)){
                    subscriptionByProductCodeMap.get(subscriptionRecord.COMM_Product__r.ProductCode).add(subscriptionRecord);
                } else {
                    subscriptionByProductCodeMap.put(subscriptionRecord.COMM_Product__r.ProductCode, new List<COMM_Subscription__c>{ subscriptionRecord });
                }
                parentProductIdSet.add(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
            }
        }

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
            for (String productCode : subscriptionByProductCodeMap.keySet()) {
                for(COMM_Subscription__c subscriptionRecord : subscriptionByProductCodeMap.get(productCode)){
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
            COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
            ociReservation.release(input);
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