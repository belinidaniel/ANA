/**
 * @author Daniel Reto
 * @description Web Service to update Case details changed on Subscription Form.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      23/10/2024       Original version
 **/
@RestResource(urlMapping='/postFormDetails/*')
global without sharing class COMM_WS_PostFormDetails {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to update case record
     */
    @HttpPost
    global static void postFormDetails() {
        RestResponse res = RestContext.response;

        try {
            // Parse payload request.
            COMM_WS_UpdateFormDetailsInput inputRequest = COMM_WS_UpdateFormDetailsInput.parse(RestContext.request.requestBody.toString());

            // Perform Case record update.
            COMM_SL_WS_PostFormDetails postFormDetailsService = new COMM_SL_WS_PostFormDetails();
            COMM_WS_UpdateFormDetailsOutput output = postFormDetailsService.updateSubscriptionRequest(inputRequest);
            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_PostFormDetails');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}