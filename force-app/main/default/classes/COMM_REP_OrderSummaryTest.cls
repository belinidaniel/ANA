/**
 * @author Diogo Gonçalves
 * @description COMM_REP_OrderSummary Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves  17/04/2024    100           ECOMM-105: Original version
 * Diogo Gonçalves  01/07/2024    100           ECOMM-1557: Added testGetForVoucherPDFService
 * Daniel Reto		03/07/2024    100           Added getOrderSummaryByOrderIdTest
 * Daniel Reto		06/11/2024    100           Added getOrderSummaryByCOMMSalesforceOrderIdTest
 **/
@isTest
private class COMM_REP_OrderSummaryTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testGetByIds() {
        List<String> orderSummaryIds = new List<String>();
        List<OrderSummary> orderSummaries = [SELECT Id FROM OrderSummary WITH USER_MODE LIMIT 1];
        for (OrderSummary os : orderSummaries) {
            orderSummaryIds.add(os.Id);
        }
        Test.startTest();
        COMM_REP_OrderSummary orderSummary = new COMM_REP_OrderSummary();
        List<OrderSummary> result = orderSummary.getByIds(orderSummaryIds);
        Test.stopTest();

        Assert.areEqual(orderSummaries.size(), result.size(), 'The result should have the same number of records as the input');
    }

    @isTest
    static void testGetForVoucherPDFService() {
        List<String> orderNumbers = new List<String>();
        List<OrderSummary> orderSummaries = [SELECT Id, OrderNumber FROM OrderSummary WITH USER_MODE LIMIT 1];
        for (OrderSummary os : orderSummaries) {
            orderNumbers.add(os.OrderNumber);
        }
        Test.startTest();
        COMM_REP_OrderSummary orderSummary = new COMM_REP_OrderSummary();
        List<OrderSummary> result = orderSummary.getForVoucherPDFService(orderNumbers);
        Test.stopTest();

        Assert.areEqual(orderSummaries.size(), result.size(), 'The result should have the same number of records as the input');
    }

    @isTest
    static void getForSearchOrderTest() {
        String inputRequestJson =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": \"2024-06-05\",' +
            '    \"reservationStartDate\": \"2024-06-05\",' +
            '    \"reservationEndDate\": \"2024-06-05\",' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": \"AA-11-AA\",' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        COMM_WS_SearchOrdersInput inputRequest = COMM_WS_SearchOrdersInput.parse(inputRequestJson);

        Account accRecord = [SELECT Id FROM Account][0];

        String orderSummaryExtraFilter = 'AccountId = \'' + accRecord.Id + '\'';

        Test.startTest();
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        List<OrderSummary> orderSummaryList = orderSummaryRep.getForSearchOrder(inputRequest, orderSummaryExtraFilter);
        Test.stopTest();

        // Assert
        Assert.areEqual(0, orderSummaryList.size(), 'The result should have the same number of records as the input');
    }

    @isTest
    static void getOrderSummaryByOrderNumberTest() {
        OrderSummary orderSummaries = [SELECT Id, OrderNumber FROM OrderSummary WITH USER_MODE LIMIT 1][0];
        Test.startTest();
        COMM_REP_OrderSummary orderSummary = new COMM_REP_OrderSummary();
        List<OrderSummary> result = orderSummary.getOrderSummaryByOrderNumber(orderSummaries.OrderNumber);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'The result should have the same number of records as the input');
    }

    @isTest
    static void getOrderSummaryByCOMMSalesforceOrderIdTest() {
        OrderSummary orderSummaries = [SELECT Id, OrderNumber, OriginalOrderId, AccountId, Account.COMM_ResellerId__c FROM OrderSummary LIMIT 1][0];
        Account accRecord = new Account(
        	Id = orderSummaries.AccountId,
            COMM_ResellerId__c = '12345'
        );
        update accRecord;
        Test.startTest();
        COMM_REP_OrderSummary orderSummary = new COMM_REP_OrderSummary();
        List<OrderSummary> result = orderSummary.getOrderSummaryByCOMMSalesforceOrderId(accRecord.COMM_ResellerId__c,  accRecord.COMM_ResellerId__c + '-' + orderSummaries.OriginalOrderId);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'The result should have the same number of records as the input');
    }
}