/**
 * @author Carlos Fusco
 * @description COMM_HttpCallout_Utility test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco   19/03/2024		100            Original version
 **/
@isTest
private class COMM_HttpCallout_UtilityTest {
    private static final String ENDPOINT = 'https://www.test.callout.com/object/001';
    private static final Map<String, String> HTTP_CONTENT_JSON_HEADER = new Map<String, String>{ 'Content-Type' => 'application/json' };
    private static final String HTTP_REQUEST_JSON_BODY = '{"short_description" : {"en-EN" : "Description"}}';

    /**
     * @description Mock class for HTTP Callouts
     */
    public class HttpResponseMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('Success');
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    static void testGetUrlQueryParameters() {
        Map<String, String> parameters = new Map<String, String>{ 'id' => 'object001' };

        Test.startTest();
        String url = ENDPOINT + COMM_HttpCallout_Utility.getUrlQueryParameters(parameters);
        Test.stopTest();

        Assert.areEqual(
            ENDPOINT + '?id=' + parameters.get('id'),
            url,
            'URL should match the junction of endpoint and parameters map provided for callout'
        );
    }

    @isTest
    static void testSetHttpRequest() {
        Test.startTest();
        HttpRequest httpRequest = COMM_HttpCallout_Utility.setHttpRequest(
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD,
            ENDPOINT,
            HTTP_CONTENT_JSON_HEADER
        );
        Test.stopTest();

        Assert.areEqual(ENDPOINT, httpRequest.getEndpoint(), 'HTTP Request endpoint should match provided endpoint for callout');
        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpRequest.getHeader('Content-Type'),
            'HTTP Request endpoint should match provided endpoint for callout'
        );
    }

    @isTest
    static void testDoCallout() {
        HttpRequest httpRequest = COMM_HttpCallout_Utility.setHttpRequest(
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD,
            ENDPOINT,
            HTTP_CONTENT_JSON_HEADER
        );
        httpRequest.setBody(HTTP_REQUEST_JSON_BODY);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        HttpResponse httpResponse = COMM_HttpCallout_Utility.doCallout(httpRequest);
        Test.stopTest();

        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpResponse.getHeader('Content-Type'),
            'HTTP Response header should be equal to application/json'
        );
        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response Status should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response Body should be Success');
    }

    @isTest
    static void testHttpGetCallout() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        HttpResponse httpResponse = COMM_HttpCallout_Utility.httpGetCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, null);
        Test.stopTest();

        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpResponse.getHeader('Content-Type'),
            'HTTP Response header should be equal to application/json'
        );
        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response Status should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response Body should be Success');
    }

    @isTest
    static void testHttpPostCallout() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        HttpResponse httpResponse = COMM_HttpCallout_Utility.httpPostCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, HTTP_REQUEST_JSON_BODY);
        Test.stopTest();

        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpResponse.getHeader('Content-Type'),
            'HTTP Response header should be equal to application/json'
        );
        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response Status should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response Body should be Success');
    }

    @isTest
    static void testHttpPutCallout() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        HttpResponse httpResponse = COMM_HttpCallout_Utility.httpPutCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, HTTP_REQUEST_JSON_BODY);
        Test.stopTest();

        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpResponse.getHeader('Content-Type'),
            'HTTP Response header should be equal to application/json'
        );
        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response Status should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response Body should be Success');
    }

    @isTest
    static void testHttpPatchCallout() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        HttpResponse httpResponse = COMM_HttpCallout_Utility.httpPatchCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, HTTP_REQUEST_JSON_BODY);
        Test.stopTest();

        Assert.areEqual(
            HTTP_CONTENT_JSON_HEADER.get('Content-Type'),
            httpResponse.getHeader('Content-Type'),
            'HTTP Response header should be equal to application/json'
        );
        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response Status should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response Body should be Success');
    }

    @isTest
    static void isHttpResponseSuccesfullTest() {
        HttpResponse mockedSucessResponse = new HttpResponse();
        mockedSucessResponse.setHeader('Content-Type', 'application/json');
        mockedSucessResponse.setBody('Success');
        mockedSucessResponse.setStatusCode(204);

        HttpResponse mockedErrorResponse = new HttpResponse();
        mockedErrorResponse.setHeader('Content-Type', 'application/json');
        mockedErrorResponse.setBody('Bad Request Error');
        mockedErrorResponse.setStatusCode(400);

        Test.startTest();
        Boolean successCheckResult = COMM_HttpCallout_Utility.isHttpResponseSuccesfull(mockedSucessResponse);
        Boolean failureCheckResult = COMM_HttpCallout_Utility.isHttpResponseSuccesfull(mockedErrorResponse);
        Test.stopTest();

        Assert.isTrue(successCheckResult, 'expected result to indicate success = true');
        Assert.isFalse(failureCheckResult, 'expected result to indicate success = false');
    }
}