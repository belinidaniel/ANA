/**
 * @author           Daniel Reto
 * @description      COMM_WS_SearchOrdersOutput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      24/06/2024      100            Original version
 * Daniel Reto      24/07/2024      97             Test Class Fix
 **/
@IsTest
public class COMM_WS_SearchOrdersOutputTest {
    @isTest
    static void testParse() {
        String json =
            '{' +
            '    \"pageSize\": 10,' +
            '    \"page\": 0,' +
            '    \"data\": [' +
            '        {' +
            '            \"status\": 3,' +
            '            \"productTypes\": [' +
            '                \"FASTTRACK\",' +
            '                \"LOUNGE\"' +
            '            ],' +
            '            \"price\": 291.39,' +
            '            \"orderNumber\": \"STU-100174\",' +
            '            \"orderDate\": \"2024-06-05\",' +
            '            \"currencyCode\": \"EUR\",' +
            '            \"airports\": [' +
            '                \"OPO\"' +
            '            ]' +
            '        }' +
            '    ],' +
            '    \"count\": 1' +
            '}';
        COMM_WS_SearchOrdersOutput obj = COMM_WS_SearchOrdersOutput.parse(json);
        Assert.isNotNull(obj, 'Objects should not be null.');
    }

    @isTest
    static void checkInputRequestRulesOrderStartDateTest() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();

        Account accRecord = [SELECT Id FROM Account][0];

        List<OrderSummary> orderSummaryList = [
            SELECT
            OrderNumber,
            OrderedDate,
            GrandTotalAmount,
            Status,
            COMM_MaxReservationEnd__c,
            COMM_IsLegacyOrder__c,
            (
                SELECT
                    Product2.Family,
                    Product2.COMM_Airport__c
                FROM
                    OrderItemSummaries
            )
            FROM
                OrderSummary
        ];
        
        String inputRequestjson =
            '{' +
            '    \"accountId\": \"' + accRecord.Id +'\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": null,' +
            '    \"orderEndDate\": null,' +
            '    \"reservationStartDate\": null,' +
            '    \"reservationEndDate\": null,' +
            '    \"orderNumber\": null,' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": null,' +
            '    \"airports\": null,' +
            '    \"status\": null' +
            '}';
        
        COMM_WS_SearchOrdersOutput outputRequest = new COMM_WS_SearchOrdersOutput();
        
        Test.startTest();
        COMM_WS_SearchOrdersOutput.buildOutputRequest(COMM_WS_SearchOrdersInput.parse(inputRequestjson), outputRequest, orderSummaryList);
        Test.stopTest();
        
        Assert.areEqual(10, outputRequest.pageSize, 'Wrong Request!');
        Assert.areEqual(0, outputRequest.page, 'Wrong Request!');
        Assert.areEqual(1, outputRequest.count, 'Wrong Request!');
        Assert.areEqual(2, outputRequest.data[0].status, 'Wrong Request!');
        List<String> productFamily = outputRequest.data[0].productTypes;
        productFamily.sort();
        Assert.areEqual(new List<String>{ 'FASTTRACK', 'GIFTCARD', 'PARKING', 'SUBSCRIPTION' }, productFamily, 'Wrong Request!');
        Assert.areEqual(4, outputRequest.data[0].price, 'Wrong Request!');
        Assert.areEqual(orderSummaryList[0].OrderNumber, outputRequest.data[0].orderNumber, 'Wrong Request!');
        Assert.areEqual(new List<String>{ 'LIS' }, outputRequest.data[0].airports, 'Wrong Request!');
    }
}