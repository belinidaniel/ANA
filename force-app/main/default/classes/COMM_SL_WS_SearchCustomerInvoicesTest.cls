/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      10/06/2025      Original version
 **/

@isTest
private class COMM_SL_WS_SearchCustomerInvoicesTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testValidRequest() {
        Account accRecord = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.accountId = accRecord.Id;
        inputRequest.page = 0;
        inputRequest.pageSize = 10;

        COMM_SL_WS_SearchCustomerInvoices searchCustomerInvoicesService = new COMM_SL_WS_SearchCustomerInvoices();
        Test.startTest();
        COMM_WS_SearchInvoicesOutput result = searchCustomerInvoicesService.checkCustomerInvoiceExistence(inputRequest);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.page, 'Page should match the input');
        System.assertEquals(10, result.pageSize, 'Page size should match the input');
    }

    @isTest
    static void testMissingAccountId() {
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.page = 0;
        inputRequest.pageSize = 10;

        COMM_SL_WS_SearchCustomerInvoices service = new COMM_SL_WS_SearchCustomerInvoices();
        String expectedErrorMessage = '\'accountId\' is a required parameter!';

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesOutput result = service.checkCustomerInvoiceExistence(inputRequest);
            System.assert(false, 'Exception should have been thrown');
        } catch (COMM_SL_WS_SearchCustomerInvoices.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals(expectedErrorMessage, e.getMessage(), 'Exception message should match expected');
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidDateRange() {
        Account accRecord = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.accountId = accRecord.Id;
        inputRequest.invoiceStartDate = Date.today();
        inputRequest.invoiceEndDate = Date.today().addDays(-10);

        COMM_SL_WS_SearchCustomerInvoices service = new COMM_SL_WS_SearchCustomerInvoices();

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesOutput result = service.checkCustomerInvoiceExistence(inputRequest);
            System.assert(false, 'Exception should have been thrown');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals(
                '\'invoiceStartDate\' must be equal or greater than \'invoiceEndDate\'!',
                e.getMessage(),
                'Exception message should match expected'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testMissingEndDate() {
        Account accRecord = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.accountId = accRecord.Id;
        inputRequest.invoiceStartDate = Date.today();

        COMM_SL_WS_SearchCustomerInvoices service = new COMM_SL_WS_SearchCustomerInvoices();

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesOutput result = service.checkCustomerInvoiceExistence(inputRequest);
            System.assert(false, 'Exception should have been thrown');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals(
                'When \'invoiceStartDate\' or \'invoiceEndDate\' are set, both parameters are required!',
                e.getMessage(),
                'Exception message should match expected'
            );
        }
        Test.stopTest();
    }
}