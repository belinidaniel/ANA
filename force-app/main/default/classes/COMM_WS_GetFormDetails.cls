/**
 * @author Daniel Reto
 * @description Web Service to search for Case details to use on Subscription Form.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      21/10/2024       Original version
 **/
@RestResource(urlMapping='/getFormDetails/*')
global without sharing class COMM_WS_GetFormDetails {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to search for Customer Orders
     */
    @HttpGet
    global static void getFormDetails() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            // get Case Id from URI
            String encryptedCase = req.requestURI.substring(req.requestURI.lastIndexOf('getFormDetails/')+15);
            if(encryptedCase.contains('&')){
                encryptedCase = encryptedCase.replace('&','/');
            }
            String caseIdValue = COMM_GEN_Utility.decryptRecordIdentifier(encryptedCase, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);

            // List of Case Details.
            COMM_SL_WS_GetFormDetails searchFormDetails = new COMM_SL_WS_GetFormDetails();
            COMM_WS_FormDetailsOutput output = searchFormDetails.checkFormDetails(caseIdValue);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_GetFormDetails');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}