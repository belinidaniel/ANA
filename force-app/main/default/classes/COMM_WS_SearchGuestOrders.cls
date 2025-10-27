/**
 * @author Daniel Reto
 * @description Web Service to search guest Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      25/06/2024       Original version
 **/
@RestResource(urlMapping='/orders/guest/*')
global with sharing class COMM_WS_SearchGuestOrders {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to search for Customer Orders
     */
    @HttpPost
    global static void searchCustomerOrders() {
        RestResponse res = RestContext.response;
        try {
            // adjust date fields with empty string
            String requestBody = RestContext.request.requestBody.toString();
            requestBody = requestBody.replaceAll('""', 'null');
            // Parse payload request.
            COMM_WS_SearchOrdersInput inputRequest = COMM_WS_SearchOrdersInput.parse(requestBody);
            // List of Customer Orders.
            COMM_SL_WS_SearchGuestOrders searchOrdersService = new COMM_SL_WS_SearchGuestOrders();
            COMM_WS_SearchOrdersOutput output = searchOrdersService.checkGuestOrderExistence(inputRequest);
            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_SearchGuestOrders');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}