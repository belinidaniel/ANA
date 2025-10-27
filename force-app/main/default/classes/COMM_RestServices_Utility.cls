/**
 * @author Ricardo Dias
 * @description RestServices Util Class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024		Original version
 **/
public class COMM_RestServices_Utility {
    public final static string UNEXPECTED_ERROR = 'An unexpected error occurred';
    public final static Integer BAD_REQUEST = 400;
    public final static Integer OK = 200;

    /**
     * @description  Converts a JSON string into a map for easy access to its data
     *
     * @param requestBody The JSON string representing the request body to be parsed
     * @return A map containing the JSON data as key-value pairs
     */
    public static Map<String, Object> parseRequest(String requestBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(requestBody);
    }

    /**
     * @description Parses a datetime string into a Datetime object
     *
     * @param dateTimeStr The datetime string in ISO 8601 format to convert
     * @return Datetime The converted Datetime object, or null if there's an error
     */
    public static Datetime parseDatetime(String dateTimeStr) {
        try {
            Integer endIndex = dateTimeStr.length() <= 19 ? dateTimeStr.length() : 19;
            String formattedDateTimeStr = dateTimeStr.replace('Z', '').replace('T', ' ').substring(0, endIndex);
            return Datetime.valueOfGmt(formattedDateTimeStr);
        } catch (Exception e) {
            // Log the error and return null or handle it as needed
            COMM_GEN_Utility.logError(e, 'Rest Services parseDatetime', 'COMM_RestServices_Utility');
            return null;
        }
    }

    /**
     * @description Prepares a success response for a REST API call. It sets the response status to OK (200) and converts the response data into JSON format
     *
     * @param res The response object to update
     * @param response The data to include in the response, formatted as a map
     */
    public static void setSuccessResponse(RestResponse res, Map<String, Object> response) {
        res.statusCode = OK;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    /**
     * @description Sets an error response for a REST API call. It assigns a specific status code to indicate the error type and includes a custom error message
     *
     * @param res The response object to update with error details
     * @param statusCode The HTTP status code to represent the type of error (e.g., 404 for Not Found, 500 for Internal Server Error)
     * @param message The error message to be sent in the response body
     */
    public static void setErrorResponse(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(message);
    }

    /**
     * @description Class to represent an Exception throwed during processing of REST services
     */
    public class RestServiceException extends Exception {
    }
}