/**
 * @author Rui Salgado
 * @description COMM_OMS_CalloutUtilTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    91            Original version
 **/
@isTest
private class COMM_OMS_CalloutUtilTest {
    /**
     * @description Mock fail response class
     */
    public class COMM_OMS_RestFailMock implements HttpCalloutMock {
        /**
         * @description Http respond method
         * @param request HttpRequest object
         * @return HttpResponse object
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(COMM_OMS_Constants.HTTP_INTERNAL_ERROR_CODE);
            response.setBody('{ "success":false }');
            return response;
        }
    }

    /**
     * @description Mock success response class
     */
    public class COMM_OMS_RestSuccessMock implements HttpCalloutMock {
        /**
         * @description Http respond method
         * @param request HttpRequest object
         * @return HttpResponse object
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader(COMM_OMS_Constants.CONTENT_TYPE, COMM_OMS_Constants.APPLICATION_JSON);
            response.setStatusCode(COMM_OMS_Constants.HTTP_SUCCESS_CODE);
            response.setBody('{ "success":true }');
            return response;
        }
    }

    /**
     * @description Test method of COMM_OMS_CalloutUtil.createRequestLog
     */
    @isTest //(SeeAllData=true)
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void shouldCreateRequestLog() {
        Test.setMock(HttpCalloutMock.class, new COMM_OMS_RestSuccessMock());

        Map<String, String> headers = new Map<String, String>{ 'accept' => 'application/json' };

        Test.startTest();
        HttpResponse response = COMM_OMS_CalloutUtil.doCallout('.com/api/orders', COMM_OMS_Constants.POST, headers, '{ "go": true }');
        Id logId = COMM_OMS_CalloutUtil.insertHttpLogs()[0].getId();
        Test.stopTest();

        // Get response header
        List<String> headerKeys = response.getHeaderKeys();
        Map<String, String> responseHeaders = new Map<String, String>();
        for (String headerKey : headerKeys) {
            responseHeaders.put(headerKey, response.getHeader(headerKey));
        }

        COMM_OMS_HttpLog__c httpLog = [
            SELECT Endpoint__c, Method__c, RequestHeader__c, RequestBody__c, ResponseHeader__c, ResponseBody__c
            FROM COMM_OMS_HttpLog__c
            WHERE Id = :logId
        ];

        System.assertEquals('.com/api/orders', httpLog.Endpoint__c, 'Endpoint of log does not match');
        System.assertEquals(COMM_OMS_Constants.POST, httpLog.Method__c, 'Method of log does not match');
        System.assertEquals(JSON.serialize(headers), httpLog.RequestHeader__c, 'Request field of log does not match');
        System.assertEquals('{ "go": true }', httpLog.RequestBody__c, 'Request Body of log does not match');
        System.assertEquals(response.getBody(), httpLog.ResponseBody__c, 'Response Body of log does not match');
        System.assertEquals(JSON.serialize(responseHeaders), httpLog.ResponseHeader__c, 'Request Body of log does not match');
    }

    /**
     * @description Test method of COMM_OMS_CalloutUtil.doCallout (positive)
     */
    @isTest
    static void shouldSuccessCallout() {
        Test.setMock(HttpCalloutMock.class, new COMM_OMS_RestSuccessMock());

        Map<String, String> headers = new Map<String, String>{ 'accept' => 'application/json' };

        Test.startTest();
        HttpResponse response = COMM_OMS_CalloutUtil.doCallout('.com/api/orders', COMM_OMS_Constants.POST, headers, '{ "go": true }');
        Test.stopTest();

        System.assert(response.getStatusCode() == 200, 'Http status code of the response should 200 OK');
    }

    /**
     * @description Test method of COMM_OMS_CalloutUtil.doCallout (negative)
     */
    @isTest
    static void shouldFailCallout() {
        Test.setMock(HttpCalloutMock.class, new COMM_OMS_RestFailMock());

        Map<String, String> headers = new Map<String, String>{ 'accept' => 'application/json' };

        Test.startTest();
        HttpResponse response = COMM_OMS_CalloutUtil.doCallout('.com/api/orders', COMM_OMS_Constants.POST, headers, '{ "go": true }');
        Test.stopTest();

        System.assert(response.getStatusCode() == 500, 'Http status code of the response should 500');
    }
    /**
     * @description Test method of COMM_OMS_CalloutUtil.parseHeaders
     */
    @isTest
    static void shouldSucceedParseHeader() {
        String headers = 'Content-Type=>application/json;Accept=>application/json';

        Test.startTest();
        Map<String, String> mapHeaders = COMM_OMS_CalloutUtil.parseHeaders(headers);
        Test.stopTest();

        System.assertEquals('application/json', mapHeaders.get('Content-Type'), 'Content-type not correct');
        System.assertEquals('application/json', mapHeaders.get('Accept'), 'Accept not correct');
    }
}