/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      4/06/2025      Original version
 **/

@isTest
private class COMM_WS_SearchCustomerInvoicesTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void searchCustomerInvoicesSuccessTest() {
        Account accRecord = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/invoices/customer/';
        req.httpMethod = 'POST';

        String requestBody = '{' + '    \"accountId\": \"' + accRecord.Id + '\",' + '    \"page\": 0,' + '    \"pageSize\": 10' + '}';

        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SearchCustomerInvoices.searchCustomerInvoices();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

        System.assertEquals(200, res.statusCode, 'Expected 200 status code for successful request');

        System.assert(responseMap.containsKey('data'), 'Response should contain data array');
        System.assert(responseMap.containsKey('page'), 'Response should contain page information');
        System.assert(responseMap.containsKey('pageSize'), 'Response should contain pageSize information');
        System.assert(responseMap.containsKey('count'), 'Response should contain count information');
    }

    @isTest
    static void searchCustomerInvoicesErrorMissingAccountIdTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/invoices/customer/';
        req.httpMethod = 'POST';

        String requestBody =
            '{' +
            '    \"accountId\": null,' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"startDate\": \"' +
            String.valueOf(DateTime.now().addDays(-30)).left(10) +
            '\",' +
            '    \"endDate\": \"' +
            String.valueOf(DateTime.now()).left(10) +
            '\",' +
            '    \"invoiceNumber\": null,' +
            '    \"status\": [\"PAID\", \"PENDING\"]' +
            '}';

        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SearchCustomerInvoices.searchCustomerInvoices();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

        System.assertEquals(500, res.statusCode, 'Expected 500 status code for error request');

        System.assertEquals('ERROR_FOUND', responseMap.get('errorCode'), 'Error code should be ERROR_FOUND');
        System.assert(responseMap.containsKey('message'), 'Response should contain error message');
    }

    @isTest
    static void searchCustomerInvoicesErrorInvalidJsonTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/invoices/customer/';
        req.httpMethod = 'POST';
        String requestBody = 'This is not valid JSON';

        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SearchCustomerInvoices.searchCustomerInvoices();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

        System.assertEquals(500, res.statusCode, 'Expected 500 status code for error request');

        System.assertEquals('ERROR_FOUND', responseMap.get('errorCode'), 'Error code should be ERROR_FOUND');
        System.assert(responseMap.containsKey('message'), 'Response should contain error message');
    }
}