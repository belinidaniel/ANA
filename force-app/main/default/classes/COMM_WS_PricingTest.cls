/**
 * @author Ricardo Dias
 * @description COMM_WS_Pricing test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024		100            Original version
 * Ricardo Dias    08/04/2024       100            Update tests
 **/
@IsTest
private class COMM_WS_PricingTest {
    @IsTest
    static void testDoPostFailure() {
        // Simulate an invalid request JSON payload (e.g., missing required fields)
        String jsonBody = '{ }';

        // Setup RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://example.com/services/apexrest/pricing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        // Start test execution
        Test.startTest();

        // Call the method under test
        COMM_WS_Pricing.doPost();

        // Stop test execution
        Test.stopTest();

        // Asserts - Expecting a failure response
        System.assertNotEquals(200, RestContext.response.statusCode, 'Expected a non-200 HTTP status code due to invalid input.');
    }

    @IsTest
    static void testDoPostDateFailure() {
        // Simulate an invalid request JSON payload with wrong Date Format
        String jsonBody = '{"product":[{"startDate":"2023-01-01","endDate":"2023-01-31","productId": "p1"}]}';

        // Setup RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://example.com/services/apexrest/pricing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        // Start test execution
        Test.startTest();

        // Call the method under test
        COMM_WS_Pricing.doPost();

        // Stop test execution
        Test.stopTest();
        Map<String, Object> requestMap = COMM_RestServices_Utility.parseRequest(res.responseBody.toString());
        List<Object> errorList = (List<Object>) requestMap.get('error');
        // Assert the list is not empty
        System.assert(!errorList.isEmpty(), 'The list should not be empty');
    }

    @IsTest
    static void testDoPostSuccess() {
        // Simulate a successful request JSON payload
        String jsonBody = '{"product":[{"startDate":"2023-12-15T00:00:00.000Z","endDate":"2023-12-16T02:00:00.000Z","productId": "p1"}]}';

        // Setup RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://example.com/services/apexrest/pricing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        // Start test execution
        Test.startTest();

        // Call the method under test
        COMM_WS_Pricing.doPost();

        // Stop test execution
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Expected HTTP 200 status code');
    }
}