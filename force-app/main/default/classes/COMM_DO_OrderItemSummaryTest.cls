/**
 * @author           Daniel Reto
 * @description      COMM_DO_OrderItemSummary test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024      100            Original version
 **/
@isTest
private class COMM_DO_OrderItemSummaryTest {

    @isTest
    static void getFilterStatusCodesTest() {

        Test.startTest();
        Integer statusCode = COMM_DO_OrderItemSummary.getFilterStatusCodes(COMM_DO_OrderItemSummary.FULFILLED_STATUS);
        Test.stopTest();

        Assert.areEqual(2, statusCode, 'expected value was "2"');
    }
}