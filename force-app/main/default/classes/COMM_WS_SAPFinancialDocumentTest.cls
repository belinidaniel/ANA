/**
 * @author Daniel Lascas
 * @description COMM_WS_SAPFinancialDocument test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_WS_SAPFinancialDocumentTest {
    @isTest
    static void postDocumentTest() {
        //Scenario: Request to create a financial document in SAP is made
        //Expected: Request sent and response received

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new SAPDocumentPostHttpResponseGenerator());

        //Mocked Request Map
        Map<String, Object> requestBodyMap = new Map<String, Object>();

        Test.startTest();
        COMM_WS_SAPFinancialDocument worker = new COMM_WS_SAPFinancialDocument();
        HttpResponse result = worker.postFinancialDocument(requestBodyMap);
        Test.stopTest();

        Assert.areEqual(200, result.getStatusCode(), 'expected response with successfull status code (200)');
    }

    @isTest
    static void getDocumentTest() {
        //Scenario: Request to obtain a financial document in SAP is made
        //Expected: Request sent and response received

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new SAPDocumentGetHttpResponseGenerator());

        //Mocked Request Map
        Map<String, String> requestMap = new Map<String, String>();

        Test.startTest();
        COMM_WS_SAPFinancialDocument worker = new COMM_WS_SAPFinancialDocument();
        HttpResponse result = worker.getFinancialDocument(requestMap);
        Test.stopTest();

        Assert.areEqual(200, result.getStatusCode(), 'expected response with successfull status code (200)');
    }

    /**
     * @description Implements a mocked SAP server that responds with an expected
     * response when making GET call
     **/
    public class SAPDocumentGetHttpResponseGenerator implements HttpCalloutMock {
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
            response.setBody('{"fileName":"4187000039.pdf", "fileContent":"dGVzdCBmaWxl"}');
            response.setStatusCode(200);
            return response;
        }
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
            response.setBody('{"documentId":"4187000039"}');
            response.setStatusCode(200);
            return response;
        }
    }
}