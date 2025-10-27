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
private class COMM_WS_SearchInvoicesInputTest {
    @IsTest
    static void testParseMethod() {
        String json =
            '{"accountId":"ACC123","page":1,"pageSize":10,"invoiceStartDate":"2023-01-01",' +
            '"invoiceEndDate":"2023-01-31","invoiceNumber":"INV001","orderNumber":"ORD001",' +
            '"status":["Open","Closed"],"invoiceExtraFilter":"None"}';

        Test.startTest();
        COMM_WS_SearchInvoicesInput result = COMM_WS_SearchInvoicesInput.parse(json);
        Test.stopTest();

        System.assertEquals('ACC123', result.accountId);
        System.assertEquals(1, result.page);
        System.assertEquals(10, result.pageSize);
        System.assertEquals(Date.newInstance(2023, 1, 1), result.invoiceStartDate);
        System.assertEquals(Date.newInstance(2023, 1, 31), result.invoiceEndDate);
        System.assertEquals('INV001', result.invoiceNumber);
        System.assertEquals('ORD001', result.orderNumber);
        System.assertEquals(2, result.status.size());
        System.assertEquals('Open', result.status[0]);
        System.assertEquals('Closed', result.status[1]);
        System.assertEquals('None', result.invoiceExtraFilter);
    }

    @IsTest
    static void checkRulesBothDatesNull() {
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.accountId = 'ACC123';
        input.page = 1;
        input.pageSize = 10;
        input.invoiceStartDate = null;
        input.invoiceEndDate = null;

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(true, 'No exception expected when both dates are null');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assert(false, 'No exception expected but got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void checkRulesOnlyStartDateProvided() {
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.invoiceStartDate = Date.today();
        input.invoiceEndDate = null;

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(false, 'Exception was expected but not thrown');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals('When \'invoiceStartDate\' or \'invoiceEndDate\' are set, both parameters are required!', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void checkRulesOnlyEndDateProvided() {
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.invoiceStartDate = null;
        input.invoiceEndDate = Date.today();

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(false, 'Exception was expected but not thrown');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals('When \'invoiceStartDate\' or \'invoiceEndDate\' are set, both parameters are required!', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void checkRulesStartDateAfterEndDate() {
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.invoiceStartDate = Date.today().addDays(5);
        input.invoiceEndDate = Date.today();

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(false, 'Exception was expected but not thrown');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assertEquals('\'invoiceStartDate\' must be equal or greater than \'invoiceEndDate\'!', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void checkRulesValidDateRange() {
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.invoiceStartDate = Date.today();
        input.invoiceEndDate = Date.today().addDays(5);

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(true, 'No exception expected with valid date range');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assert(false, 'No exception expected but got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void checkRulesEqualDates() {
        Date testDate = Date.today();
        COMM_WS_SearchInvoicesInput input = new COMM_WS_SearchInvoicesInput();
        input.invoiceStartDate = testDate;
        input.invoiceEndDate = testDate;

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesInput.checkInputRequestRules(input);
            System.assert(true, 'No exception expected with equal dates');
        } catch (COMM_WS_SearchInvoicesInput.COMM_SL_WS_SearchCustomerInvoicesException e) {
            System.assert(false, 'No exception expected but got: ' + e.getMessage());
        }
        Test.stopTest();
    }
}