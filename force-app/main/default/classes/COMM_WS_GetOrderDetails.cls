/**
 * @author Daniel Reto
 * @description Web Service to search for Order details.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      27/06/2024       Original version
 **/
@RestResource(urlMapping='/orders/detail/*')
global with sharing class COMM_WS_GetOrderDetails {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to search for Customer Orders
     */
    @HttpGet
    global static void getOrderDetails() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            // get Order Number from URI
            String orderNumberValue = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            // List of Customer Orders.
            COMM_SL_WS_GetOrderDetails searchOrderDetails = new COMM_SL_WS_GetOrderDetails();
            COMM_WS_OrderDetailOutput output = searchOrderDetails.checkOrderDetails(orderNumberValue);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_GetOrderDetails');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}