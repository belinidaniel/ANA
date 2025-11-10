/**
 * @author Diogo Gonçalves
 * @description COMM_REP_InvoiceLine Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves  17/04/2024    100           ECOMM-105: Original version
 **/
@isTest
private class COMM_REP_InvoiceLineTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testGetInvoiceLinesByFamilyAndType() {
        Map<Id, Invoice> invoicesById = new Map<Id, Invoice>([SELECT Id FROM Invoice LIMIT 1]);
        List<Id> invoiceIds = new List<Id>((Set<Id>) invoicesById.keySet());
        List<String> productFamilies = new List<String>{ 'Lounge', 'Fast Track' };
        String entityItemType = 'Order Product';
        List<InvoiceLine> invoiceLines = [
            SELECT Id, ReferenceEntityItemId
            FROM InvoiceLine
            WHERE InvoiceId IN :invoiceIds AND Product2.Family IN :productFamilies AND ReferenceEntityItemType = :entityItemType
        ];

        Test.startTest();
        COMM_REP_InvoiceLine invoiceLine = new COMM_REP_InvoiceLine();
        List<InvoiceLine> result = invoiceLine.getInvoiceLinesByFamilyAndType(invoiceIds, productFamilies, entityItemType);
        Test.stopTest();
        Assert.areEqual(invoiceLines, result, 'Lists should be equal');
    }
}