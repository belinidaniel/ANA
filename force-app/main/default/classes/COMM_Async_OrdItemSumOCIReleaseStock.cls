/**
 * @author Daniel Reto
 * @description Batch class to release Stock in OCI for Order Item Products. This is to release stock from the Load Test Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      25/07/2024      Original version
 **/
public with sharing class COMM_Async_OrdItemSumOCIReleaseStock extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    private COMM_IREP_OrderItemSummary orderItemSummaryRep;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{
        Product2.COMM_ParentProduct__c,
        Product2.ProductCode,
        Product2.COMM_ParentProductCode__c
    };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OrdItemSumOCIReleaseStock() {
        this.orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    }

    @testVisible
    private COMM_Async_OrdItemSumOCIReleaseStock(
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
            .whereNotEquals('Status', COMM_DO_OrderItemSummary.RETURNED_STATUS)
            .whereEquals('COMM_SetupInitialStock__c', 'TO RELEASE');

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param orderItemSummaryList List of Order Item Summary records that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<OrderItemSummary> orderItemSummaryList) {
        // set input request to send for OCI
        COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
        input.expirationSeconds = 0;
        input.product = new List<COMM_WS_ReservationInput.Product>();
        // generate COMM_WS_ReservationInput wrapper for each Product being deactivated
        for (OrderItemSummary orderItemSummaryRecord : orderItemSummaryList) {
            COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
            product.productId = orderItemSummaryRecord.Product2.COMM_ParentProductCode__c != null
                ? orderItemSummaryRecord.Product2.COMM_ParentProductCode__c
                : orderItemSummaryRecord.Product2.ProductCode;
            product.startDate = orderItemSummaryRecord.COMM_ReservationStart__c > DateTime.now()
                ? orderItemSummaryRecord.COMM_ReservationStart__c
                : DateTime.now();
            product.endDate = orderItemSummaryRecord.COMM_ReservationEnd__c;
            input.product.add(product);
            orderItemSummaryRecord.COMM_SetupInitialStock__c = 'RELEASED';
        }
        // OCI capacity release
        COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
        if (!Test.isRunningTest()) {
            ociReservation.release(input);
        }
        // Update Order Item Summary records
        if (!input.product.isEmpty()) {
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