/**
 * @author Diogo Gonçalves
 * @description Web Service to pre reserve products and create/cancel Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  05/05/2024       Original version - initial mock
 **/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
@RestResource(urlMapping='/reseller/orders/v1/')
global with sharing class COMM_WS_ResellerOrder {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description Method to create a reseller order
     */
    @HttpPost
    global static void doPost() {
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        try {
            COMM_WS_ResellerOrderInput input = COMM_WS_ResellerOrderInput.parse(RestContext.request.requestBody.toString());
            COMM_WS_ResellerOrderOutput output = COMM_SL_WS_ResellerOrder.createResellerOrder(input);
            setResponse(response, 200, JSON.serialize(output));
        } catch (COMM_SL_ResellerOrderException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_ResellerOrder');
            setResponse(response, 400, JSON.serialize(errorResp));
        } catch (Exception e) {
            errorResp.errorCode = COMM_OCI_Constants.ERROR_EXCEPTION_FOUND; //TODO should I use OCI constants?
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_ResellerOrder');
            setResponse(response, 500, JSON.serialize(errorResp));
        }
    }

    /**
     * @description Prepares a response for a REST API call.
     * @param res The response object to update
     * @param response The data to include in the response, formatted as a map
     */
    private static void setResponse(RestResponse res, Integer statusCode, String responseBody) {
        //TODO move this to a Util class?
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = statusCode;
        if (!String.isBlank(responseBody)) {
            res.responseBody = Blob.valueOf(responseBody);
        }
    }
}