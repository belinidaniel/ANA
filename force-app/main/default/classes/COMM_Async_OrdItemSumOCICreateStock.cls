/**
 * @author Daniel Reto
 * @description Batch class to create Stock in OCI for Order Item Summaries. This is to setup the initial stock of migrated Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      18/07/2024      Original version
 **/
public with sharing class COMM_Async_OrdItemSumOCICreateStock extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    private COMM_IREP_OrderItemSummary orderItemSummaryRep;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{
        Product2.COMM_ParentProduct__c,
        Product2.ProductCode,
        Product2.COMM_ParentProductCode__c
    };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OrdItemSumOCICreateStock() {
        this.orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    }

    @testVisible
    private COMM_Async_OrdItemSumOCICreateStock(
        COMM_IREP_OrderItemSummary orderItemSummaryRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.orderItemSummaryRep = orderItemSummaryRep;
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

        SObjectType sobjType = Schema.getGlobalDescribe().get('OrderItemSummary');

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(COMM_REP_OrderItemSummary.ORDERITEMSUMMARY_FIELDS)
            .selectParentFields(OrderItemSummary.Product2Id, PRODUCT_FIELDS)
            .setWhere('COMM_ReservationEnd__c > TODAY')
            .whereNotEquals('Status', COMM_DO_OrderItemSummary.RETURNED_STATUS)
            .whereEquals('COMM_SetupInitialStock__c', 'TO PROCESS');

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the records obtained in the start method's query and Reserve Stock.
     *
     * @param bc Context Information of the executed batch
     * @param orderItemSummaryList List of Order Item Summary records that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<OrderItemSummary> orderItemSummaryList) {
        COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
        input.expirationSeconds = 0;
        input.product = new List<COMM_WS_ReservationInput.Product>();

        for (OrderItemSummary orderItemSummaryRecord : orderItemSummaryList) {
            DateTime ociStartDateValue = orderItemSummaryRecord.COMM_ReservationStart__c > DateTime.now()
                ? orderItemSummaryRecord.COMM_ReservationStart__c
                : DateTime.now();
            COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
            product.productId = orderItemSummaryRecord.Product2.COMM_ParentProductCode__c != null
                ? orderItemSummaryRecord.Product2.COMM_ParentProductCode__c
                : orderItemSummaryRecord.Product2.ProductCode;
            product.startDate = ociStartDateValue;
            product.endDate = orderItemSummaryRecord.COMM_ReservationEnd__c;
            input.product.add(product);
            orderItemSummaryRecord.COMM_SetupInitialStock__c = 'PROCESSED';
        }

        if (!input.product.isEmpty()) {
            COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
            if (!Test.isRunningTest()) {
                ociReservation.reserve(input, false);
            }
        }
        if (!orderItemSummaryList.isEmpty()) {
            orderItemSummaryRep.updateSObjects(orderItemSummaryList);
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