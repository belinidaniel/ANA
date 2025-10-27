/**
 * @author Diogo Gonçalves
 * @description Web Service for product details and availability
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  05/05/2024       Original version - initial mock
 * Daniel Lascas    06/06/2024       ECOMM-386: First Implementation
 **/
@RestResource(urlMapping='/reseller/products/v1/*')
global with sharing class COMM_WS_ResellerProducts {
    private COMM_SL_WS_ResellerProducts resellerSl;

    /**
     * @description Constructor to inicialize SL class
     */
    public COMM_WS_ResellerProducts() {
        this.resellerSl = new COMM_SL_WS_ResellerProducts();
    }

    @TestVisible
    private COMM_WS_ResellerProducts(COMM_SL_WS_ResellerProducts resellerSl) {
        this.resellerSl = resellerSl;
    }

    /**
     * @description Method to create a reseller product
     */
    @HttpPost
    global static void doPost() {
        new COMM_WS_ResellerProducts().processRequest();
    }

    /**
     * @description Method to process request received to obtain available stock for resellers.
     */
    @TestVisible
    private void processRequest() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            // Parse the request body to a map
            String requestBody = req.requestBody.toString();

            //Retrives the Reseller Data from SL Class
            COMM_SL_WS_ResellerSearchResponse responseObject = resellerSl.getResellerStock(requestBody);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(responseObject));
        } catch (Exception e) {
            // Log and respond with an error in case of exceptions
            COMM_GEN_Utility.logError(e, 'Reseller Availability Service Error', 'COMM_WS_ResellerAvailability');

            ErrorWrapper errorResponse = new ErrorWrapper();
            errorResponse.errorCode = 'ERROR';
            errorResponse.errorMessage = e.getMessage();

            COMM_RestServices_Utility.setErrorResponse(res, COMM_RestServices_Utility.BAD_REQUEST, JSON.serialize(errorResponse));
        }
    }

    /**
     * @description Wrapper with expected structure for server errors
     */
    private class ErrorWrapper {
        public String errorCode;
        public String errorMessage;
    }
}