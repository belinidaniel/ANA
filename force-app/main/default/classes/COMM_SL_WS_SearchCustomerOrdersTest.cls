/**
 * @author Daniel Reto
 * @description COMM_SL_WS_SearchCustomerOrders Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      25/06/2024    100           Original version
 * Daniel Reto      05/07/2024    100           Fix Outputs due REP OrderSummary Change
 * Daniel Reto      05/11/2024    100           Test Class Fix
 **/
@isTest
private class COMM_SL_WS_SearchCustomerOrdersTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void checkCustomerOrderExistenceTest() {
        Account accRecord = [SELECT Id FROM Account WHERE IsPersonAccount = true][0];
        OrderSummary orderSummaryRecord = [SELECT Id, OrderNumber FROM orderSummary][0];

        String inputRequestJson =
            '{' +
            '    \"accountId\": \"' +
            accRecord.Id +
            '\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"orderEndDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"reservationStartDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"reservationEndDate\": \"' +
            String.valueOf(DateTime.now()).left(10) +
            '\",' +
            '    \"orderNumber\": \"' +
            orderSummaryRecord.OrderNumber +
            '\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [2]' +
            '}';
        COMM_WS_SearchOrdersInput inputRequest = COMM_WS_SearchOrdersInput.parse(inputRequestJson);

        Test.startTest();
        COMM_SL_WS_SearchCustomerOrders searchCustomerOrdersService = new COMM_SL_WS_SearchCustomerOrders();
        COMM_WS_SearchOrdersOutput outputRequest = searchCustomerOrdersService.checkCustomerOrderExistence(inputRequest);
        Test.stopTest();

        // Assert
        Assert.areEqual(10, outputRequest.pageSize, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(0, outputRequest.page, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(1, outputRequest.count, 'The result should have the same value as the OrderSummary');
    }

    @isTest
    static void checkCustomerOrderExistenceExceptionAccountIdTest() {
        Account accRecord = [SELECT Id FROM Account][0];
        OrderSummary orderSummaryRecord = [SELECT Id, OrderNumber FROM orderSummary][0];

        String inputRequestJson =
            '{' +
            '    \"accountId\": null,' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"orderEndDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"reservationStartDate\": \"' +
            String.valueOf(DateTime.now().addDays(-10)).left(10) +
            '\",' +
            '    \"reservationEndDate\": \"' +
            String.valueOf(DateTime.now()).left(10) +
            '\",' +
            '    \"orderNumber\": \"' +
            orderSummaryRecord.OrderNumber +
            '\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [2]' +
            '}';
        COMM_WS_SearchOrdersInput inputRequest = COMM_WS_SearchOrdersInput.parse(inputRequestJson);
        String errorMessage = '';

        Test.startTest();
        try {
            COMM_SL_WS_SearchCustomerOrders searchCustomerOrdersService = new COMM_SL_WS_SearchCustomerOrders();
            COMM_WS_SearchOrdersOutput outputRequest = searchCustomerOrdersService.checkCustomerOrderExistence(inputRequest);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        Assert.areEqual('\'accountId\' is a required parameter!', errorMessage, 'Error didn\'t triggered the exception!');
    }
}