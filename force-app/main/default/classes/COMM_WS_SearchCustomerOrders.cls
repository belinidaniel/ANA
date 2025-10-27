/**
 * @author Daniel Reto
 * @description Web Service to search Customer Orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
@RestResource(urlMapping='/orders/customer/*')
global with sharing class COMM_WS_SearchCustomerOrders {
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
            COMM_SL_WS_SearchCustomerOrders searchOrdersService = new COMM_SL_WS_SearchCustomerOrders();
            COMM_WS_SearchOrdersOutput output = searchOrdersService.checkCustomerOrderExistence(inputRequest);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_SearchCustomerOrders');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}