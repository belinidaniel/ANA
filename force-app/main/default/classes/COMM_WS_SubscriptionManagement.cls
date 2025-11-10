/**
 * @author Daniel Lascas
 * @description Subscription Management Webservice class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/06/2024       Original version
 **/
@RestResource(urlMapping='/subscriptions/customer/*')
global with sharing class COMM_WS_SubscriptionManagement {
    private COMM_SL_WS_SubscriptionManagement subManagementSl;

    /**
     * @description Class constructor to initialize service layer
     */
    public COMM_WS_SubscriptionManagement() {
        this.subManagementSl = new COMM_SL_WS_SubscriptionManagement();
    }

    @TestVisible
    private COMM_WS_SubscriptionManagement(COMM_SL_WS_SubscriptionManagement subManagementSl) {
        this.subManagementSl = subManagementSl;
    }

    /**
     * @description Initiate handler for POST request for subscription management.
     */
    @HttpPost
    global static void doPost() {
        new COMM_WS_SubscriptionManagement().handleDoPost();
    }

    /**
     * @description Handles the POST request for subscription management.
     * On success, it returns customer's subscriptions based on filter (if no filter then returns all).
     * On failure, it logs the error and returns an error response
     */
    @TestVisible
    private void handleDoPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            // Parse the request body to a map
            System.debug(req.requestBody.toString());
            Map<String, Object> requestMap = COMM_RestServices_Utility.parseRequest(req.requestBody.toString());
            //Retrieve Account Id from URL
            String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

            //Retrives the calculatePricingResponse from Pricing SL Class
            Map<String, Object> responseMap = subManagementSl.searchSubscriptionList(accountId, requestMap);

            COMM_RestServices_Utility.setSuccessResponse(res, responseMap);
        } catch (Exception e) {
            // Log and respond with an error in case of exceptions
            COMM_GEN_Utility.logError(e, 'Subscription Management Error', 'COMM_WS_SubscriptionManagement');
            COMM_RestServices_Utility.setErrorResponse(res, COMM_RestServices_Utility.BAD_REQUEST, '{"message": "' + e.getMessage() + '"}');
        }
    }
}