/**
 * @author Hugo Manera
 * @description Test class for COMM_WS_SearchInvoicesOutput
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      10/06/2025      Original version
 **/

@isTest
private class COMM_WS_SearchInvoicesOutputTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testParseMethod() {
        String json =
            '{"count":3,"pageSize":10,"page":0,"data":[' +
            '{"invoiceNumber":"INV-001","status":"Open","orderNumber":"ORD-001","invoiceDate":"2023-06-15",' +
            '"invoiceLines":[{"invoiceLineNumber":"Line-1"},{"invoiceLineNumber":"Line-2"}]},' +
            '{"invoiceNumber":"INV-002","status":"Closed","orderNumber":"ORD-002","invoiceDate":"2023-06-16",' +
            '"invoiceLines":[{"invoiceLineNumber":"Line-3"}]}]}';

        Test.startTest();
        COMM_WS_SearchInvoicesOutput result = COMM_WS_SearchInvoicesOutput.parse(json);
        Test.stopTest();

        System.assertEquals(3, result.count, 'Count should be 3');
        System.assertEquals(10, result.pageSize, 'Page size should be 10');
        System.assertEquals(0, result.page, 'Page should be 0');
        System.assertEquals(2, result.data.size(), 'Should have 2 invoice summaries');

        COMM_WS_SearchInvoicesOutput.InvoiceSummary firstInvoice = result.data[0];
        System.assertEquals('INV-001', firstInvoice.invoiceNumber);
        System.assertEquals('Open', firstInvoice.status);
        System.assertEquals('ORD-001', firstInvoice.orderNumber);
        System.assertEquals(Date.newInstance(2023, 6, 15), firstInvoice.invoiceDate);
        System.assertEquals(2, firstInvoice.invoiceLines.size());
        System.assertEquals('Line-1', firstInvoice.invoiceLines[0].invoiceLineNumber);
        System.assertEquals('Line-2', firstInvoice.invoiceLines[1].invoiceLineNumber);

        COMM_WS_SearchInvoicesOutput.InvoiceSummary secondInvoice = result.data[1];
        System.assertEquals('INV-002', secondInvoice.invoiceNumber);
        System.assertEquals('Closed', secondInvoice.status);
        System.assertEquals('ORD-002', secondInvoice.orderNumber);
        System.assertEquals(Date.newInstance(2023, 6, 16), secondInvoice.invoiceDate);
        System.assertEquals(1, secondInvoice.invoiceLines.size());
        System.assertEquals('Line-3', secondInvoice.invoiceLines[0].invoiceLineNumber);
    }

    @isTest
    static void buildOutputRequestFirstPage() {
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.page = 0;
        inputRequest.pageSize = 2;

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            LIMIT 1
        ];

        COMM_WS_SearchInvoicesOutput outputRequest = new COMM_WS_SearchInvoicesOutput();
        List<Invoice> invoiceList = [
            SELECT
                Id,
                DocumentNumber,
                Status,
                InvoiceDate,
                TYPEOF ReferenceEntity
                    WHEN OrderSummary THEN OrderNumber
                END,
                (SELECT Name FROM invoiceLines)
            FROM Invoice
            WHERE ReferenceEntityId = :orderSummary.Id
            LIMIT 1
        ];

        Test.startTest();
        COMM_WS_SearchInvoicesOutput.buildOutputRequest(inputRequest, outputRequest, invoiceList);
        Test.stopTest();

        System.assertEquals(1, outputRequest.count, 'Total count should be 1');
        System.assertEquals(2, outputRequest.pageSize, 'Page size should be 2');
        System.assertEquals(0, outputRequest.page, 'Page should be 0');
        System.assertEquals(1, outputRequest.data.size(), 'Should have 1 record on this page');
    }

    @isTest
    static void buildOutputRequestEmptyList() {
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.page = 0;
        inputRequest.pageSize = 10;

        COMM_WS_SearchInvoicesOutput outputRequest = new COMM_WS_SearchInvoicesOutput();
        List<Invoice> invoiceList = new List<Invoice>();

        Test.startTest();
        COMM_WS_SearchInvoicesOutput.buildOutputRequest(inputRequest, outputRequest, invoiceList);
        Test.stopTest();

        System.assertEquals(0, outputRequest.count, 'Total count should be 0');
        System.assertEquals(10, outputRequest.pageSize, 'Page size should be 10');
        System.assertEquals(0, outputRequest.page, 'Page should be 0');
        System.assertEquals(0, outputRequest.data.size(), 'Should have 0 records');
    }

    @isTest
    static void buildOutputRequestNullPageValues() {
        COMM_WS_SearchInvoicesInput inputRequest = new COMM_WS_SearchInvoicesInput();
        inputRequest.page = null;
        inputRequest.pageSize = null;

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            LIMIT 1
        ];

        COMM_WS_SearchInvoicesOutput outputRequest = new COMM_WS_SearchInvoicesOutput();
        List<Invoice> invoiceList = [
            SELECT
                Id,
                DocumentNumber,
                Status,
                InvoiceDate,
                TYPEOF ReferenceEntity
                    WHEN OrderSummary THEN OrderNumber
                END,
                (SELECT Name FROM invoiceLines)
            FROM Invoice
            WHERE ReferenceEntityId = :orderSummary.Id
            LIMIT 1
        ];

        Test.startTest();
        try {
            COMM_WS_SearchInvoicesOutput.buildOutputRequest(inputRequest, outputRequest, invoiceList);
            System.assert(false, 'Expected an exception due to null page and pageSize');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected due to null page and pageSize');
        }
        Test.stopTest();
    }
}