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
        List<Invoice> listInvoices = [SELECT Id, COMM_SAPDocumentId__c, Status, Balance, DueDate FROM Invoice WHERE ReferenceEntityId = :orderSummary.Id LIMIT 1];
        System.debug('listInvoices: '+listInvoices);
        for (Invoice invoice : listInvoices) {
            ids.add(invoice.Id);
        }
        Test.startTest();
        List<Invoice> invoices = invoiceRep.getForSAPInvoice(ids, 'CreatedDate = N_MONTHS_AGO:0');
        Test.stopTest();
        System.debug('invoices: '+invoices);
        System.assertEquals(0, invoices.size(), 'Number of invoices should be 0 due Balance Field');
    }
}