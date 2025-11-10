/**
 * @author Ricardo Dias
 * @description COMM_RestServices_Utility test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024		100            Original version
 **/
@isTest
private class COMM_RestServices_UtilityTest {
    @isTest
    static void testParseRequest() {
        String jsonBody = '{"name":"Test","value":123}';
        Map<String, Object> result = COMM_RestServices_Utility.parseRequest(jsonBody);

        System.assertEquals(2, result.size(), 'The result map should contain two keys');
        System.assertEquals('Test', result.get('name'), 'The name key should equal "Test"');
        System.assertEquals(123, result.get('value'), 'The value key should equal 123');
    }

    @isTest
    static void testParseDatetime() {
        String validDateTime = '2023-01-01T12:00:00Z';
        Datetime expected = Datetime.newInstanceGmt(2023, 1, 1, 12, 0, 0);
        Datetime result = COMM_RestServices_Utility.parseDatetime(validDateTime);

        System.assertEquals(expected, result, 'The parsed datetime should match the expected value');

        // Test invalid datetime format
        String invalidDateTime = 'Not a date';
        result = COMM_RestServices_Utility.parseDatetime(invalidDateTime);

        System.assertEquals(null, result, 'Parsing an invalid datetime should return null');
    }

    @isTest
    static void testSetSuccessResponse() {
        RestResponse res = new RestResponse();
        Map<String, Object> responseContent = new Map<String, Object>{ 'status' => 'success' };

        Test.startTest();
        COMM_RestServices_Utility.setSuccessResponse(res, responseContent);
        Test.stopTest();

        System.assertEquals(COMM_RestServices_Utility.OK, res.statusCode, 'Status code should be 200');
        String responseBody = res.responseBody.toString();
        System.assertNotEquals(null, responseBody, 'Response body should not be null');
        System.assert(responseBody.contains('success'), 'Response body should contain the success status');
    }

    @isTest
    static void testSetErrorResponse() {
        RestResponse res = new RestResponse();
        Integer statusCode = 404;
        String errorMessage = 'Resource not found';

        Test.startTest();
        COMM_RestServices_Utility.setErrorResponse(res, statusCode, errorMessage);
        Test.stopTest();

        System.assertEquals(statusCode, res.statusCode, 'Status code should match the provided error code');
        String responseBody = res.responseBody.toString();
        System.assertEquals(errorMessage, responseBody, 'Response body should contain the provided error message');
    }
}