/**
 * @author Daniel Lascas
 * @description COMM_LCC_InvoiceViewer test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024      100            ECOMM-194: Original version
 * Daniel Reto      08/07/2024      100            New Test Classes
 **/
@isTest
private class COMM_LCC_InvoiceViewerTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_SL_SAPFinancialDocument FINANCIAL_SL = (COMM_SL_SAPFinancialDocument) MOCKS.mock(COMM_SL_SAPFinancialDocument.class);
    private final static COMM_IREP_SubscriptionInvoice SUBSCRIPTION_INVOICE_REP = (COMM_REP_SubscriptionInvoice) MOCKS.mock(COMM_REP_SubscriptionInvoice.class);
    private final static COMM_IREP_Invoice INVOICE_REP = (COMM_REP_Invoice) MOCKS.mock(COMM_REP_Invoice.class);
    private final static COMM_IREP_CreditMemo CREDITMEMO_REP = (COMM_REP_CreditMemo) MOCKS.mock(COMM_REP_CreditMemo.class);

    @isTest
    static void interfaceTest() {
        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_LCC_InvoiceViewer.getFileData(null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void getFileBySubscriptionInvoiceTest() {
        //Generate a mocked Subscription Invoice Record
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
                'COMM_SAPNumber__c' => 'test_sap',
                'COMM_IssuanceDate__c' => Date.today()
            }
        );

        Blob testData = Blob.valueOf('Test File Mocked Data');

        //Generate a mocked Attachment file
        Attachment financialDoc = (Attachment) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Attachment',
            new Map<String, Object>{ 'Name' => 'financialDoc', 'Body' => testData }
        )[0];

        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(SUBSCRIPTION_INVOICE_REP.getSubInvoiceByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(invoiceList);
        MOCKS.when(FINANCIAL_SL.getFinancialDocument(fflib_Match.anyString(), fflib_Match.anyDate(), fflib_Match.anyString()))
            .thenReturn(financialDoc);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
        worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
        String resultingData = worker.handleGetFileData(invoiceList[0].Id);
        Test.stopTest();

        Assert.areEqual(EncodingUtil.base64Encode(testData), resultingData, 'data does not match expected');
    }

    @isTest
    static void getFileBySubscriptionInvoiceExceptionTest() {

        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(SUBSCRIPTION_INVOICE_REP.getSubInvoiceByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<COMM_SubscriptionInvoice__c>());
        MOCKS.stopStubbing();
        String errorMessage = '';

        Test.startTest();
        try {
            COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
            worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
            String resultingData = worker.handleGetFileData(fflib_IdGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType));
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(errorMessage, System.Label.COMM_SUBSCRIPTION_INVOICE_NOT_GENERATED_ERROR, 'An error should have occured!');
    }

    @isTest
    static void getFileByInvoiceTest() {
        //Generate a mocked Subscription Invoice Record
        List<Invoice> invoiceList = (List<Invoice>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Invoice',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Invoice.sObjectType),
                'COMM_SAPDocumentId__c' => 'test_sap',
                'COMM_IssuanceDate__c' => Date.today()
            }
        );

        Blob testData = Blob.valueOf('Test File Mocked Data');

        //Generate a mocked Attachment file
        Attachment financialDoc = (Attachment) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Attachment',
            new Map<String, Object>{ 'Name' => 'financialDoc', 'Body' => testData }
        )[0];

        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(INVOICE_REP.getByIds((List<String>) fflib_Match.anyObject())).thenReturn(invoiceList);
        MOCKS.when(FINANCIAL_SL.getFinancialDocument(fflib_Match.anyString(), fflib_Match.anyDate(), fflib_Match.anyString()))
            .thenReturn(financialDoc);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
        worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
        String resultingData = worker.handleGetFileData(invoiceList[0].Id);
        Test.stopTest();

        Assert.areEqual(EncodingUtil.base64Encode(testData), resultingData, 'data does not match expected');
    }

    @isTest
    static void getFileByInvoiceExceptionTest() {
        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(INVOICE_REP.getByIds((List<String>) fflib_Match.anyObject())).thenReturn(new List<Invoice>());
        MOCKS.stopStubbing();
        String errorMessage = '';

        Test.startTest();
        try {
            COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
            worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
            String resultingData = worker.handleGetFileData(fflib_IdGenerator.generate(Invoice.sObjectType));
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(errorMessage, System.Label.COMM_SUBSCRIPTION_INVOICE_NOT_GENERATED_ERROR, 'An error should have occured!');
    }

    @isTest
    static void getFileByCreditMemoTest() {
        //Generate a mocked Subscription Invoice Record
        List<CreditMemo> creditMemoList = (List<CreditMemo>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'CreditMemo',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(CreditMemo.sObjectType),
                'COMM_SAPDocumentId__c' => 'test_sap',
                'COMM_IssuanceDate__c' => Date.today()
            }
        );

        Blob testData = Blob.valueOf('Test File Mocked Data');

        //Generate a mocked Attachment file
        Attachment financialDoc = (Attachment) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Attachment',
            new Map<String, Object>{ 'Name' => 'financialDoc', 'Body' => testData }
        )[0];

        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(CREDITMEMO_REP.getByIds((List<String>) fflib_Match.anyObject())).thenReturn(creditMemoList);
        MOCKS.when(FINANCIAL_SL.getFinancialDocument(fflib_Match.anyString(), fflib_Match.anyDate(), fflib_Match.anyString()))
            .thenReturn(financialDoc);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
        worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
        String resultingData = worker.handleGetFileData(creditMemoList[0].Id);
        Test.stopTest();

        Assert.areEqual(EncodingUtil.base64Encode(testData), resultingData, 'data does not match expected');
    }

    @isTest
    static void getFileByCreditMemoExceptionTest() {
        //Mock Queries and calls
        MOCKS.startStubbing();
        MOCKS.when(CREDITMEMO_REP.getByIds((List<String>) fflib_Match.anyObject())).thenReturn(new List<CreditMemo>());
        MOCKS.stopStubbing();
        String errorMessage = '';

        Test.startTest();
        try {
            COMM_LCC_InvoiceViewer worker = new COMM_LCC_InvoiceViewer();
            worker = new COMM_LCC_InvoiceViewer(FINANCIAL_SL, SUBSCRIPTION_INVOICE_REP, INVOICE_REP, CREDITMEMO_REP);
            String resultingData = worker.handleGetFileData(fflib_IdGenerator.generate(CreditMemo.sObjectType));
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(errorMessage, System.Label.COMM_CREDIT_MEMO_NOT_GENERATED_ERROR, 'An error should have occured!');
    }
}