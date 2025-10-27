/**
 * @author           Daniel Reto
 * @description      COMM_DO_OrderSummary test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      24/06/2024      100            Original version
 **/
@isTest
private class COMM_DO_OrderSummaryTest {

    @isTest
    static void getFilterStatusAPITest() {
        List<Integer> statusCodeList = new List<Integer>{ 1, 2, 3 };

        Test.startTest();
        List<String> statusValuesList = COMM_DO_OrderSummary.getFilterStatusAPI(statusCodeList);
        Test.stopTest();

        Assert.areEqual(COMM_DO_OrderSummary.CREATED_STATUS, statusValuesList.get(0), 'expected value was "' + COMM_DO_OrderSummary.CREATED_STATUS + '"');
        Assert.areEqual(COMM_DO_OrderSummary.PROCESSING_STATUS, statusValuesList.get(1), 'expected value was "' + COMM_DO_OrderSummary.PROCESSING_STATUS + '"');
        Assert.areEqual(COMM_DO_OrderSummary.PAID_STATUS, statusValuesList.get(2), 'expected value was "' + COMM_DO_OrderSummary.PAID_STATUS + '"');
    }

    @isTest
    static void getFilterStatusCodesTest() {

        Test.startTest();
        Integer statusCode = COMM_DO_OrderSummary.getFilterStatusCodes(COMM_DO_OrderSummary.PAID_STATUS);
        Test.stopTest();

        Assert.areEqual(3, statusCode, 'expected value was "3"');
    }
}