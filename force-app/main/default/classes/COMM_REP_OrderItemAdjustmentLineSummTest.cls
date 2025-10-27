/**
 * @author Daniel Lascas
 * @description COMM_REP_OrderItemAdjustmentLineSummary test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/08/2024      100            ECOMM-2078 - Original version
 **/
@isTest
private class COMM_REP_OrderItemAdjustmentLineSummTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_OrderItemAdjustmentLineSummary ORDERITEM_ADJUSTMENTLINESUMMARY_REP = new COMM_REP_OrderItemAdjustmentLineSummary();

    @isTest
    static void getOrderItemAdjustLineSumByOrderItemSummaryIdsTest() {
        Test.startTest();
        List<OrderItemAdjustmentLineSummary> resultList = ORDERITEM_ADJUSTMENTLINESUMMARY_REP.getOrderItemAdjustLineSumByOrderItemSummaryIds(
            new Set<Id>{ fflib_IDGenerator.generate(OrderItemSummary.sObjectType) }
        );
        Test.stopTest();

        Assert.areEqual(0, resultList.size(), 'expected query to return no records');
    }
}