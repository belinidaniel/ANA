/**
 * @author Daniel Reto
 * @description Batch class to update the reservation on OCI
 * when a new Capacity with a hight ValidTo date is created and confirmed (Process Status = COMPLETED)
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      11/04/2024      ECOMM-204: Original version
 * Jose Passos      02/05/2024      Update ociReservation.reserve to request Prices as this is a parent product
 **/
public with sharing class COMM_Async_CapacityEndDateExtension extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_MINUTE_EXECUTE_SINCE = 'MinuteToExecute';
    @TestVisible
    private final static string PARAMETER_HOUR_EXECUTE_SINCE = 'HourToExecute';

    private COMM_IREP_Subscription subscriptionRep;

    private Integer minuteToExecute;
    private Integer hourToExecute;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_CapacityEndDateExtension() {
        this.subscriptionRep = new COMM_REP_Subscription();
    }

    @testVisible
    private COMM_Async_CapacityEndDateExtension(
        COMM_IREP_Subscription subscriptionRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.subscriptionRep = subscriptionRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field is set in the past.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        minuteToExecute = Integer.valueOf(getParameterValue(PARAMETER_MINUTE_EXECUTE_SINCE));
        hourToExecute = Integer.valueOf(getParameterValue(PARAMETER_HOUR_EXECUTE_SINCE));

        DateTime dateTimeToExecute = DateTime.newInstance(
                DateTime.now().year(),
                DateTime.now().month(),
                DateTime.now().day(),
                hourToExecute,
                minuteToExecute,
                0
            )
            .addDays(-1);

        FW_QueryBuilder queryCapacity = new FW_QueryBuilder(COMM_Capacity__c.SObjectType)
            .selectFields(COMM_REP_Capacity.CAPACITY_FIELDS)
            .selectParentFields(COMM_Capacity__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode })
            .setWhere('LastModifiedDate > ' + dateTimeToExecute.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'))
            .whereEquals('COMM_Active__c', true)
            .whereEquals('COMM_ProcessStatus__c', COMM_DO_Capacity.PROCESS_STATUS_COMPLETED)
            .whereEquals(
                'RecordTypeId',
                Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            );
            //.orderByAsc('COMM_ValidTo__c');

        List<COMM_Capacity__c> capacityList = Database.query(queryCapacity.getQuery());

        List<String> parentProductIds = new List<String>();
        for (COMM_Capacity__c capacityRecord : capacityList) {
            parentProductIds.add(capacityRecord.COMM_Product__c);
        }


        //Subscriptions
        //List<COMM_Subscription__c> subscriptionList = subscriptionRep.getSubscriptionsByParentProductIds(parentIdSet);

        FW_QueryBuilder querySubscriptions = new FW_QueryBuilder(COMM_Subscription__c.SObjectType)
            .selectFields(COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode, Product2.COMM_ParentProduct__c })
            .whereEquals('COMM_Active__c', true)
            .whereIn('COMM_Product__r.COMM_ParentProduct__c', parentProductIds)
            .whereEquals('COMM_Status__c', COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED);

        return executeQuery(querySubscriptions);
    }

    /**
     * @description Batch Execute Method. Updates the records active field to false that were obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param subscriptionList List of COMM_Subscription__c that will be renewed
     */
    public void execute(Database.BatchableContext bc, List<COMM_Subscription__c> subscriptionList) {
        Map<String, DateTime> valitToByParentIdMap = new Map<String, DateTime>();
        Map<Id, String> productCodeByParentIdMap = new Map<Id, String>();
        
        DateTime dateTimeToExecute = DateTime.newInstance(
                DateTime.now().year(),
                DateTime.now().month(),
                DateTime.now().day(),
                hourToExecute,
                minuteToExecute,
                0
            )
            .addDays(-1);

        List<Id> parentProductsIdSet = new List<Id>();
        for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
            parentProductsIdSet.add(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
        }

        FW_QueryBuilder query = new FW_QueryBuilder(COMM_Capacity__c.SObjectType)
            .selectFields(COMM_REP_Capacity.CAPACITY_FIELDS)
            .selectParentFields(COMM_Capacity__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode })
            .setWhere('LastModifiedDate > ' + dateTimeToExecute.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'))
            .whereEquals('COMM_Active__c', true)
            .whereEquals('COMM_ProcessStatus__c', COMM_DO_Capacity.PROCESS_STATUS_COMPLETED)
            .whereEquals(
                'RecordTypeId',
                Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            )
            .whereIn('COMM_Product__c', parentProductsIdSet)
            .orderByAsc('COMM_ValidTo__c');

        List<COMM_Capacity__c> capacityList = Database.query(query.getQuery());

        for (COMM_Capacity__c capacityRecord : capacityList) {
            valitToByParentIdMap.put(capacityRecord.COMM_Product__c, capacityRecord.COMM_ValidTo__c);
            productCodeByParentIdMap.put(capacityRecord.COMM_Product__c, capacityRecord.COMM_Product__r.ProductCode);
        }

        if (subscriptionList != null && !subscriptionList.isEmpty()) {
            COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
            input.expirationSeconds = 0;
            input.product = new List<COMM_WS_ReservationInput.Product>();

            for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
                DateTime ociEndDateValue = DateTime.newInstance(subscriptionRecord.COMM_OCIEndDate__c, Time.newInstance(0, 0, 0, 0)).addDays(1);
                if (valitToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c) > ociEndDateValue) {
                    COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
                    product.productId = productCodeByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                    product.startDate = ociEndDateValue;
                    product.endDate = valitToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c);
                    input.product.add(product);

                    subscriptionRecord.COMM_OCIEndDate__c = valitToByParentIdMap.get(subscriptionRecord.COMM_Product__r.COMM_ParentProduct__c).date();
                }
            }

            if (!input.product.isEmpty()) {
                COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
                ociReservation.reserve(input, false);
            }

            subscriptionRep.updateSObjects(subscriptionList);
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