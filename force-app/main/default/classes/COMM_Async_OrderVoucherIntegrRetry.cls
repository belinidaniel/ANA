/**
 * @author Daniel Reto
 * @description Batch class to retry  Order Voucher Integration
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      30/10/2024      ECOMM-327: Original version
 **/
public with sharing class COMM_Async_OrderVoucherIntegrRetry extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_MAX_ATTEMPTS = 'Max Attempts';
    @TestVisible
    private final static String PARAMETER_RETRY_CYCLE = 'Retry Cycle';

    private COMM_IREP_OrderSummary orderSummaryRep;

    public static final List<SObjectField> ACCOUNT_FIELDS = new List<SObjectField>{ Account.COMM_ResellerId__c };
    
    private static String orderIdRequestParam = 'orderId';
    private static String orderSummaryIdRequestParam = 'orderSummaryId';
    private static String resellerIdRequestParam = 'resellerId';
    private static String salesforceOrderIdRequestParam = 'salesforceOrderId';

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OrderVoucherIntegrRetry() {
        this.orderSummaryRep = new COMM_REP_OrderSummary();
    }

    @testVisible
    private COMM_Async_OrderVoucherIntegrRetry(
        COMM_IREP_OrderSummary orderSummaryRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.orderSummaryRep = orderSummaryRep;
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

        SObjectType sobjType = Schema.getGlobalDescribe().get('OrderSummary');

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(COMM_REP_OrderSummary.ORDERSUMMARY_FIELDS)
            .selectParentFields(OrderSummary.AccountId, ACCOUNT_FIELDS)
            .whereIn('COMM_ResellerVoucherStatus__c', new List<String>{ COMM_DO_OrderSummary.ERROR_RESELLER_VOUCHER_STATUS, COMM_DO_OrderSummary.SENT_RESELLER_VOUCHER_STATUS });

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param productsList List of Capacity records (distinct ProductCodes) that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<OrderSummary> orderSummaryList) {
        Integer maxAttemptParam = Integer.valueOf(getParameterValue(PARAMETER_MAX_ATTEMPTS));
        Integer retryCyleParam = Integer.valueOf(getParameterValue(PARAMETER_RETRY_CYCLE));
        // List of Order Voucher Platform Event to Create
        List<Map<String, Object>> orderVoucherPlatformEventToCreateList = new List<Map<String, Object>>();
        // List of Platform Event to Create
        List<COMM_OrderVouchers__e> platformEventToCreateList = new List<COMM_OrderVouchers__e>();
        // Exact time to use on comparation criteria
        DateTime dateTimeToExecute = DateTime.newInstance(
                System.now().year(),
                System.now().month(),
                System.now().day(),
                System.now().hour(),
                0,
                0
            );
        for(OrderSummary orderSummaryRecord : orderSummaryList){
            if(orderSummaryRecord.COMM_ResellerVoucherStatusDate__c > dateTimeToExecute.addHours(-(retryCyleParam*maxAttemptParam))){
                Map<String, Object> platformEventDataMap = new Map<String, Object>();
                platformEventDataMap.put(orderIdRequestParam, orderSummaryRecord.OriginalOrderId);
                platformEventDataMap.put(orderSummaryIdRequestParam, orderSummaryRecord.Id);
                platformEventDataMap.put(resellerIdRequestParam, orderSummaryRecord.Account.COMM_ResellerId__c);
                platformEventDataMap.put(salesforceOrderIdRequestParam, orderSummaryRecord.COMM_SalesforceOrderId__c);
                orderVoucherPlatformEventToCreateList.add(platformEventDataMap);
                orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.SENT_RESELLER_VOUCHER_STATUS;
            } else {
                orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.RETRY_EXHAUSTED_RESELLER_VOUCHER_STATUS;
            }
        }
        // Generate Order Vouchers Platform Events
        for(Map<String, Object> platformEventDataMap : orderVoucherPlatformEventToCreateList){
            COMM_OrderVouchers__e orderVoucherEvent = COMM_SL_GenerateResellerOrderVoucher.generateOrderVoucher((String) platformEventDataMap.get(orderIdRequestParam), (String) platformEventDataMap.get(orderSummaryIdRequestParam), (String) platformEventDataMap.get(resellerIdRequestParam), (String) platformEventDataMap.get(salesforceOrderIdRequestParam));
            platformEventToCreateList.add(orderVoucherEvent);
        }
        // Publish Platform Events
        if (!platformEventToCreateList.isEmpty()) {
            EventBus.publish(platformEventToCreateList);
        }
        // Update Order Summary records
        orderSummaryRep.updateSObjects(orderSummaryList);
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