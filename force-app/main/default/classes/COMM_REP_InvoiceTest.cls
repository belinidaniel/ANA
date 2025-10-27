/**
 * @author Rui Salgado
 * @description COMM_REP_InvoiceTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100           Original version
 * Daniel Reto      18/06/2024    100           New test method
 **/
@isTest
private class COMM_REP_InvoiceTest {
    private static COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();
    /**
     * @description Test COMM_REP_Invoice.getByIds. SeeAllData must be true to use ConnectAPI
     */
    @IsTest //(SeeAllData=true)
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void shouldGetByIds() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            WHERE OriginalOrderId = :orderId
            LIMIT 1
        ];

        FulfillmentOrder fo = [SELECT ID FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        fo.Status = 'Fulfilled';
        update fo;

        //ConnectApi.FulfillmentOrderInvoiceInputRepresentation invoiceInput = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        //ConnectAPI.FulfillmentOrderInvoiceOutputRepresentation output = ConnectApi.FulfillmentOrder.createInvoice(fo.Id, invoiceInput);

        List<Id> ids = new List<ID>();
        List<Invoice> listInvoices = [SELECT Id FROM Invoice WHERE ReferenceEntityId = :orderSummary.Id LIMIT 1];
        for (Invoice invoice : listInvoices) {
            ids.add(invoice.Id);
        }
        Test.startTest();
        List<Invoice> invoices = invoiceRep.getByIds(ids);
        Test.stopTest();
        System.assertEquals(ids.size(), invoices.size(), 'Number of invoices should be ' + ids.size());
        System.assert(invoices.size() > 0, 'Number of invoices should be greater than 0');
    }

    /**
     * @description Test COMM_REP_Invoice.getForCPMS. SeeAllData must be true to use ConnectAPI
     */
    @IsTest //(SeeAllData=true)
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void shouldGetForCPMS() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            WHERE OriginalOrderId = :orderId
            LIMIT 1
        ];

        FulfillmentOrder fo = [SELECT ID FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        fo.Status = 'Fulfilled';
        update fo;

        //ConnectApi.FulfillmentOrderInvoiceInputRepresentation invoiceInput = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        //ConnectAPI.FulfillmentOrderInvoiceOutputRepresentation output = ConnectApi.FulfillmentOrder.createInvoice(fo.Id, invoiceInput);

        List<Id> ids = new List<ID>();
        List<Invoice> listInvoices = [SELECT Id FROM Invoice WHERE ReferenceEntityId = :orderSummary.Id LIMIT 1];
        for (Invoice invoice : listInvoices) {
            ids.add(invoice.Id);
        }
        Test.startTest();
        List<Invoice> invoices = invoiceRep.getForCPMS(ids, 'Parking', 'Order Product');
        Test.stopTest();
        System.assertEquals(ids.size(), invoices.size(), 'Number of invoices should be ' + ids.size());
        System.assert(invoices.size() > 0, 'Number of invoices should be greater than 0');
    }

    /**
     * @description Test COMM_REP_Invoice.getForSAPInvoice. SeeAllData must be true to use ConnectAPI
     */
    @IsTest //(SeeAllData=true)
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void shouldGetForSAPInvoice() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            WHERE OriginalOrderId = :orderId
            LIMIT 1
        ];

        FulfillmentOrder fo = [SELECT ID FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        fo.Status = 'Fulfilled';
        update fo;

        //ConnectApi.FulfillmentOrderInvoiceInputRepresentation invoiceInput = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        //ConnectAPI.FulfillmentOrderInvoiceOutputRepresentation output = ConnectApi.FulfillmentOrder.createInvoice(fo.Id, invoiceInput);

        List<Id> ids = new List<ID>();
        List<Invoice> listInvoices = [SELECT Id FROM Invoice WHERE ReferenceEntityId = :orderSummary.Id LIMIT 1];
        for (Invoice invoice : listInvoices) {
            ids.add(invoice.Id);
        }
        Test.startTest();
        List<Invoice> invoices = invoiceRep.getForSAPInvoice(ids);
        Test.stopTest();
        System.assertEquals(ids.size(), invoices.size(), 'Number of invoices should be ' + ids.size());
        System.assert(invoices.size() > 0, 'Number of invoices should be greater than 0');
    }

    /**
     * @description Test COMM_REP_Invoice.getForSAPInvoice.
     */
    @IsTest
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void getForSAPInvoiceTest() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            WHERE OriginalOrderId = :orderId
            LIMIT 1
        ];

        FulfillmentOrder fo = [SELECT ID FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        fo.Status = 'Fulfilled';
        update fo;

        Set<Id> ids = new Set<ID>();
        List<Invoice> listInvoices = [
            SELECT Id, COMM_SAPDocumentId__c, Status, Balance, DueDate
            FROM Invoice
            WHERE ReferenceEntityId = :orderSummary.Id
            LIMIT 1
        ];
        for (Invoice invoice : listInvoices) {
            ids.add(invoice.Id);
        }
        Test.startTest();
        List<Invoice> invoices = invoiceRep.getForSAPInvoice(ids, 'CreatedDate = N_MONTHS_AGO:0');
        Test.stopTest();
        System.assertEquals(0, invoices.size(), 'Number of invoices should be 0 due Balance Field');
    }

    /**
     * @description Test COMM_REP_Invoice.getForSearchInvoice.
     */
    @IsTest
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void shouldGetForSearchInvoice() {
        // Setup test data
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        OrderSummary orderSummary = [
            SELECT Id, OrderedDate
            FROM OrderSummary
            WHERE OriginalOrderId = :orderId
            LIMIT 1
        ];

        FulfillmentOrder fo = [SELECT ID FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        fo.Status = 'Fulfilled';
        update fo;

        // Get invoice from created data
        Invoice testInvoice = [
            SELECT Id, Status, DocumentNumber, InvoiceDate, BillingAccountId
            FROM Invoice
            WHERE ReferenceEntityId = :orderSummary.Id
            LIMIT 1
        ];

        // Create search input with all parameters
        COMM_WS_SearchInvoicesInput searchInput = new COMM_WS_SearchInvoicesInput();
        searchInput.invoiceStartDate = Date.today().addDays(-1);
        searchInput.invoiceEndDate = Date.today().addDays(1);
        searchInput.invoiceNumber = testInvoice.DocumentNumber;
        searchInput.status = new List<String>{ testInvoice.Status };

        Test.startTest();

        // Test with all parameters
        List<Invoice> invoicesAllParams = invoiceRep.getForSearchInvoice(searchInput, null);

        // Test with invoice number only
        COMM_WS_SearchInvoicesInput searchByInvoiceNumber = new COMM_WS_SearchInvoicesInput();
        searchByInvoiceNumber.invoiceNumber = testInvoice.DocumentNumber;
        List<Invoice> invoicesByNumber = invoiceRep.getForSearchInvoice(searchByInvoiceNumber, null);

        // Test with status only
        COMM_WS_SearchInvoicesInput searchByStatus = new COMM_WS_SearchInvoicesInput();
        searchByStatus.status = new List<String>{ testInvoice.Status };
        List<Invoice> invoicesByStatus = invoiceRep.getForSearchInvoice(searchByStatus, null);

        // Test with extra filter
        String extraFilter = 'BillingAccountId = \'' + testInvoice.BillingAccountId + '\'';
        List<Invoice> invoicesWithFilter = invoiceRep.getForSearchInvoice(new COMM_WS_SearchInvoicesInput(), extraFilter);

        Test.stopTest();

        // Verify results
        System.assert(invoicesAllParams.size() > 0, 'Should find invoices with all parameters');
        for (Invoice inv : invoicesAllParams) {
            if (inv.Id == testInvoice.Id) {
                System.assertEquals(testInvoice.DocumentNumber, inv.DocumentNumber, 'Document number should match');
                System.assertEquals(testInvoice.Status, inv.Status, 'Status should match');
            }
        }

        System.assert(invoicesByNumber.size() > 0, 'Should find invoices by invoice number');
        System.assertEquals(testInvoice.DocumentNumber, invoicesByNumber[0].DocumentNumber, 'Should find invoice with matching document number');

        System.assert(invoicesByStatus.size() > 0, 'Should find invoices by status');
        System.assertEquals(testInvoice.Status, invoicesByStatus[0].Status, 'Should find invoice with matching status');

        System.assert(invoicesWithFilter.size() > 0, 'Should find invoices with extra filter');
        System.assertEquals(testInvoice.Id, invoicesWithFilter[0].Id, 'Should find the specific invoice with extra filter');
    }
}