/**
 * @author Diogo Gonçalves
 * @description Web Service to cancel reseller orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  15/05/2024       Original version - initial mock
 * Daniel Reto      05/11/2024       ECOMM-327
 **/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
@RestResource(urlMapping='/reseller/orders/cancellations/v1/')
global with sharing class COMM_WS_CancelResellerOrder {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description Method to cancel a reseller order
     */
    @HttpPost
    global static void doPost() {
        COMM_SL_WS_CancelResellerOrder cancelResellerOrderInstance = new COMM_SL_WS_CancelResellerOrder();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        RestContext.response.addHeader('Content-Type', 'application/json');
        try {
            // Parse the request body to a map
            Map<String, Object> requestMap = COMM_RestServices_Utility.parseRequest(req.requestBody.toString());
            //Retrives the calculatePricingResponse from Pricing SL Class
            Map<String, Object> responseMap = cancelResellerOrderInstance.cancelOrder(requestMap);
            COMM_RestServices_Utility.setSuccessResponse(res, responseMap);
        } catch (COMM_SL_ResellerOrderException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_CancelResellerOrder');
            COMM_RestServices_Utility.setErrorResponse(res, COMM_RestServices_Utility.BAD_REQUEST, JSON.serialize(errorResp));
        } catch (Exception e) {
            // Log and respond with an error in case of exceptions
            COMM_GEN_Utility.logError(e, 'Cancel Reseller Order Error', 'COMM_WS_CancelResellerOrder');
            COMM_RestServices_Utility.setErrorResponse(res, COMM_RestServices_Utility.BAD_REQUEST, '{"message": "' + e.getMessage() + '"}');
        }
    }
}