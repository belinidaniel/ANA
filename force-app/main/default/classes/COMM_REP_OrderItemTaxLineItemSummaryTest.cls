/**
 * @author Daniel Reto
 * @description COMM_REP_OrderItemTaxLineItemSummary Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      08/08/2024    100           ECOMM-1971: Original version
 **/
@isTest
private class COMM_REP_OrderItemTaxLineItemSummaryTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_OrderItemTaxLineItemSummary ORDERITEMTAXLINEITEMSUMMARY_REP = (COMM_REP_OrderItemTaxLineItemSummary) MOCKS.mock(COMM_REP_OrderItemTaxLineItemSummary.class);

    @isTest
    static void getOrderItemTaxLineItemSummaryByOrderSummaryNumberTest() {
        Test.startTest();
        COMM_IREP_OrderItemTaxLineItemSummary orderItemTaxLineItemSummaryRep = new COMM_REP_OrderItemTaxLineItemSummary();
        List<OrderItemTaxLineItemSummary> result = orderItemTaxLineItemSummaryRep.getOrderItemTaxLineItemSummaryByOrderSummaryNumber('STU-100429');
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'The result should have the same number of records as the input');
    }
}