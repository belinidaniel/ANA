/**
 * @author Daniel Lascas
 * @description COMM_SL_SAPFinancialDocument test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024      100            ECOMM-194: Original version
 * Daniel Lascas    05/09/2024      100            Updated tests for CR-41 logic
 **/
@isTest
private class COMM_SL_SAPFinancialDocumentTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IDO_SAPMapping SAP_MAPPING_DO = (COMM_DO_SAPMapping) MOCKS.mock(COMM_DO_SAPMapping.class);
    private final static COMM_IWS_SAPFinancialDocument SAP_WS = (COMM_WS_SAPFinancialDocument) MOCKS.mock(COMM_WS_SAPFinancialDocument.class);

    @isTest
    static void getDocumentTest() {
        //Scenario: Request to obtain financial document from SAP is made
        //Expected: Attachment instance with file data from SAP

        String documentType = COMM_SL_SAPFinancialDocument.DOCUMENT_TYPE_INVOICE;
        Date documentDate = System.today();
        String documentNumber = 'testNumber';

        //Mock expected response from SAP
        HttpResponse mockedResponse = new HttpResponse();
        mockedResponse.setBody('{"fileName":"testInvoice.pdf", "fileContent":"dGVzdCBmaWxl"}');

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SAP_WS.getFinancialDocument((Map<String, String>) fflib_Match.anyObject())).thenReturn(mockedResponse);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_SAPFinancialDocument worker = new COMM_SL_SAPFinancialDocument();
        worker = new COMM_SL_SAPFinancialDocument(SAP_MAPPING_DO, SAP_WS);
        Attachment resultFile = worker.getFinancialDocument(documentType, documentDate, documentNumber);
        Test.stopTest();

        Assert.isNotNull(resultFile, 'expected a non-null file');
        Assert.areEqual('dGVzdCBmaWxl', EncodingUtil.base64Encode(resultFile.Body), 'attachment body does not match expected fileContent');
        Assert.areEqual('testInvoice.pdf', resultFile.Name, 'attachment name does not match expected filename');
    }

    @isTest
    static void getDocumentFailureTest() {
        //Scenario: Request to obtain financial document from SAP is made. File doesn't exist in SAP so response is an error.
        //Expected: Exception is throwed and a error log is created

        String documentType = COMM_SL_SAPFinancialDocument.DOCUMENT_TYPE_INVOICE;
        Date documentDate = System.today();
        String documentNumber = 'testNumber';

        //Mock expected response from SAP
        HttpResponse mockedResponse = new HttpResponse();
        mockedResponse.setBody('{"resultCode":"002", "resultDesc":"Não existem ficheiros que correspondem aos parâmetros"}');

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SAP_WS.getFinancialDocument((Map<String, String>) fflib_Match.anyObject())).thenReturn(mockedResponse);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_SAPFinancialDocument worker = new COMM_SL_SAPFinancialDocument();
            worker = new COMM_SL_SAPFinancialDocument(SAP_MAPPING_DO, SAP_WS);
            worker.getFinancialDocument(documentType, documentDate, documentNumber);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Integer errorNumber = [SELECT COUNT() FROM Error_Log__c];

        Assert.isTrue(errorOccured, 'expected an error to be caught');
        Assert.areEqual(1, errorNumber, 'expected one error log to be generated');
    }

    @isTest
    static void postDocumentTest() {
        //Scenario: Request to generate financial document in SAP is made
        //Expected: Number of generated document from SAP

        String clientEmail = 'test.client@test.invalid';
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'BillingCountryCode' => 'PT',
                'BillingStreet' => 'Avenida Teste'
            }
        )[0];
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
                'COMM_SubscriptionAmount__c' => 100.00
            }
        );

        invoiceList[0] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[0],
            new Map<String, Object>{ 'COMM_TotalAmount__c' => 100 }
        );

        invoiceList[1] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[1],
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType), 'COMM_TotalAmount__c' => 100 }
        );

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new SAPDocumentPostHttpResponseGenerator());

        //Mocked Mapping (Account Data)
        Map<String, Object> mappedData = new Map<String, Object>{
            'billingName' => 'Test Company for SAP integration testing',
            'billingCountryCode' => 'PT',
            'billingAddress' => 'Avenida Teste'
        };

        //Mocked Mapping (Invoice Data)
        Map<String, Object> mappedDataInvoice = new Map<String, Object>{
            'taxAmout' => 23.00,
            'totalNetAmount' => 100.00,
            'description' => 'test invoice item sent to sap'
        };

        //Mocked Mapping (Invoice Card Data)
        Map<String, Object> mappedDataInvoiceCard = new Map<String, Object>{
            'taxAmout' => 6.9,
            'totalNetAmount' => 30.00,
            'productId' => 'card-id',
            'description' => 'test invoice card item sent to sap'
        };

        //Mocked Mapping (Invoice 2 Data)
        Map<String, Object> mappedDataInvoice2 = new Map<String, Object>{
            'taxAmout' => 23.00,
            'totalNetAmount' => 100.00,
            'description' => 'test invoice item sent to sap'
        };

        //Mocked Mapping (Invoice 2 Card Data)
        Map<String, Object> mappedDataInvoiceCard2 = new Map<String, Object>{
            'taxAmout' => 6.9,
            'totalNetAmount' => 30.00,
            'productId' => 'card-id',
            'description' => 'test invoice card item sent to sap'
        };

        COMM_MonthlyFiscalDocumentControl__c controlRecord = new COMM_MonthlyFiscalDocumentControl__c();
        controlRecord.Id = fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType);

        Date invoiceDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(testAccount, new Map<String, Object>(), false)).thenReturn(mappedData);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[0], new Map<String, Object>(), false)).thenReturn(mappedDataInvoice);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[0], new Map<String, Object>(), true)).thenReturn(mappedDataInvoiceCard);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[1], new Map<String, Object>(), false)).thenReturn(mappedDataInvoice2);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[1], new Map<String, Object>(), true)).thenReturn(mappedDataInvoiceCard2);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_SAPFinancialDocument worker = new COMM_SL_SAPFinancialDocument();
        worker = new COMM_SL_SAPFinancialDocument(SAP_MAPPING_DO, SAP_WS);
        COMM_SL_SAPDocumentResponse result = worker.createFinancialDocument(clientEmail, controlRecord, testAccount, invoiceDate, 23, invoiceList);
        Test.stopTest();

        Assert.areEqual('4187000039', result.documentId, 'expected document id does not match expected');
    }

    @isTest
    static void postDocumentWithExeptionTest() {
        //Scenario: Request to generate financial document in SAP is made. Invoice has three items with two being exempt from payment (discount 100%)
        //Expected: Number of generated document from SAP

        String clientEmail = 'test.client@test.invalid';
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'BillingCountryCode' => 'PT',
                'BillingStreet' => 'Avenida Teste'
            }
        )[0];
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            3,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
                'COMM_SubscriptionAmount__c' => 100.00
            }
        );
        invoiceList[1].Id = fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType);
        invoiceList[1].COMM_ExemptPayment__c = true;
        invoiceList[2].Id = fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType);
        invoiceList[2].COMM_ExemptPayment__c = true;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new SAPDocumentPostHttpResponseGenerator());

        //Mocked Mapping (Account Data)
        Map<String, Object> mappedData = new Map<String, Object>{
            'billingName' => 'Test Company with a really looooooooooooooooooooooong name to test truncation',
            'billingCountryCode' => 'PT',
            'billingAddress' => 'Avenida Teste'
        };

        //Mocked Mapping (Invoice Data)
        Map<String, Object> mappedDataInvoice = new Map<String, Object>{
            'productId' => 'testProd',
            'taxAmout' => 23.00,
            'totalNetAmount' => 100.00,
            'description' => 'test invoice item sent to sap'
        };

        //Mocked Mapping
        Map<String, Object> mappedDataInvoiceException = new Map<String, Object>{
            'productId' => 'testProd',
            'taxAmout' => 23.00,
            'totalNetAmount' => 100.00,
            'description' => 'test invoice item sent to sap with price exemption',
            'exemptPayment' => true
        };

        //Mocked Mapping
        Map<String, Object> mappedDataInvoiceException2 = new Map<String, Object>{
            'productId' => 'testProd',
            'taxAmout' => 23.00,
            'totalNetAmount' => 100.00,
            'description' => 'test invoice item sent to sap with price exemption',
            'exemptPayment' => true
        };

        COMM_MonthlyFiscalDocumentControl__c controlRecord = new COMM_MonthlyFiscalDocumentControl__c();
        controlRecord.Id = fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType);
        Date invoiceDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(testAccount, new Map<String, Object>(), false)).thenReturn(mappedData);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[0], new Map<String, Object>(), false)).thenReturn(mappedDataInvoice);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[0], new Map<String, Object>(), true)).thenReturn(new Map<String, Object>());
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[1], new Map<String, Object>(), false)).thenReturn(mappedDataInvoiceException);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[1], new Map<String, Object>(), true)).thenReturn(new Map<String, Object>());
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[2], new Map<String, Object>(), false)).thenReturn(mappedDataInvoiceException2);
        MOCKS.when(SAP_MAPPING_DO.mapJsonFromSObject(invoiceList[2], new Map<String, Object>(), true)).thenReturn(new Map<String, Object>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_SAPFinancialDocument worker = new COMM_SL_SAPFinancialDocument();
        worker = new COMM_SL_SAPFinancialDocument(SAP_MAPPING_DO, SAP_WS);
        COMM_SL_SAPDocumentResponse result = worker.createFinancialDocument(clientEmail, controlRecord, testAccount, invoiceDate, 23, invoiceList);
        Test.stopTest();

        Assert.areEqual('4187000039', result.documentId, 'expected document id does not match expected');
    }

    /**
     * @description Implements a mocked SAP server that responds with an expected
     * response when making POST call
     **/
    public class SAPDocumentPostHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from SAP
         *
         * @param req HTTP Request that SAP receives from Salesforce
         * @return HTTP Response expected from SAP
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"documentId":"4187000039", "resultCode":"200", "resultDesc":"Document Generated with success"}');
            response.setStatusCode(200);
            return response;
        }
    }
}