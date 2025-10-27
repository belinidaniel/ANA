/**
 * @author Daniel Reto
 * @description Web Service to cancel Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024       Original version
 **/
@RestResource(urlMapping='/orders/cancel/*')
global with sharing class COMM_WS_CancelOrders {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();
    /**
     * @description HTTP Method to search for Customer Orders
     */
    @HttpPost
    global static void cancelOrder() {
        RestResponse res = RestContext.response;
        try {
            // adjust date fields with empty string
            String requestBody = RestContext.request.requestBody.toString();
            requestBody = requestBody.replaceAll('""', 'null');
            // Parse payload request.
            COMM_WS_CancelOrdersInput inputRequest = COMM_WS_CancelOrdersInput.parse(requestBody);
            // List of Customer Orders.
            COMM_SL_WS_CancelOrders cancelOrdersService = new COMM_SL_WS_CancelOrders();
            COMM_WS_CancelOrdersOutput output = cancelOrdersService.cancelOrder(inputRequest);
            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_CancelOrders');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}