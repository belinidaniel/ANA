/**
 * @author Daniel Reto
 * @description COMM_SL_WS_SearchGuestOrders Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      26/06/2024    100           Original version
 * Daniel Reto      05/07/2024    100           Fix Outputs due REP OrderSummary Change
 **/
@isTest
private class COMM_SL_WS_SearchGuestOrdersTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void checkGuestOrderExistenceTest() {
        Account accRecord = [SELECT Id FROM Account][0];
        OrderSummary orderSummaryRecord = [SELECT Id, BillingEmailAddress, BillingPostalCode, OrderNumber FROM orderSummary][0];

        String inputRequestJson =
            '{' +
            '    \"email\": \"' +
            orderSummaryRecord.BillingEmailAddress +
            '\",' +
            '    \"zipCode\": \"' +
            orderSummaryRecord.BillingPostalCode +
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
        COMM_SL_WS_SearchGuestOrders searchGuestOrdersService = new COMM_SL_WS_SearchGuestOrders();
        COMM_WS_SearchOrdersOutput outputRequest = searchGuestOrdersService.checkGuestOrderExistence(inputRequest);
        Test.stopTest();

        // Assert
        Assert.areEqual(10, outputRequest.pageSize, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(0, outputRequest.page, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(1, outputRequest.count, 'The result should have the same value as the OrderSummary');
    }

    @isTest
    static void checkGuestOrderExistenceExceptionEmailTest() {
        Account accRecord = [SELECT Id FROM Account][0];
        OrderSummary orderSummaryRecord = [SELECT Id, OrderNumber FROM orderSummary][0];

        String inputRequestJson =
            '{' +
            '    \"email\": null,' +
            '    \"zipCode\": \"13014\",' +
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
        String errorMessage;

        Test.startTest();
        try {
            COMM_SL_WS_SearchGuestOrders searchGuestOrdersService = new COMM_SL_WS_SearchGuestOrders();
            COMM_WS_SearchOrdersOutput outputRequest = searchGuestOrdersService.checkGuestOrderExistence(inputRequest);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        Assert.areEqual('\'email\' is a required parameter!', errorMessage, 'Error didn\'t triggered the exception!');
    }

    @isTest
    static void checkGuestOrderExistenceExceptionZipCodeTest() {
        Account accRecord = [SELECT Id FROM Account][0];
        OrderSummary orderSummaryRecord = [SELECT Id, OrderNumber FROM orderSummary][0];

        String inputRequestJson =
            '{' +
            '    \"email\": \"test.test@ana.pt.invalid\",' +
            '    \"zipCode\": null,' +
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
        String errorMessage;

        Test.startTest();
        try {
            COMM_SL_WS_SearchGuestOrders searchGuestOrdersService = new COMM_SL_WS_SearchGuestOrders();
            COMM_WS_SearchOrdersOutput outputRequest = searchGuestOrdersService.checkGuestOrderExistence(inputRequest);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        Assert.areEqual('\'zipCode\' is a required parameter!', errorMessage, 'Error didn\'t triggered the exception!');
    }

    @isTest
    static void checkGuestOrderExistenceExceptionOrderNumberTest() {
        Account accRecord = [SELECT Id FROM Account][0];

        String inputRequestJson =
            '{' +
            '    \"email\": \"test.test@ana.pt.invalid\",' +
            '    \"zipCode\": \"13014\",' +
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
            '    \"orderNumber\": null,' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [2]' +
            '}';
        COMM_WS_SearchOrdersInput inputRequest = COMM_WS_SearchOrdersInput.parse(inputRequestJson);
        String errorMessage;

        Test.startTest();
        try {
            COMM_SL_WS_SearchGuestOrders searchGuestOrdersService = new COMM_SL_WS_SearchGuestOrders();
            COMM_WS_SearchOrdersOutput outputRequest = searchGuestOrdersService.checkGuestOrderExistence(inputRequest);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        Assert.areEqual('\'orderNumber\' is a required parameter!', errorMessage, 'Error didn\'t triggered the exception!');
    }
}