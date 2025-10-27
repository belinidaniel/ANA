/**
 * @author Jose Passos
 * @description Web Service to verify the availability of products.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos    11/03/2024       Original version
 * Daniel Reto    07/05/2024       ECOMM-281
 **/
@RestResource(urlMapping='/oci/isAvailable/v1/*')
global with sharing class COMM_WS_OCIAvailability {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to get sotck available from OCI
     */
    @HttpPost
    global static void isAvailable() {
        RestResponse res = RestContext.response;

        try {
            // Parse payload request.
            COMM_WS_AvailabilityInput inputRequest = COMM_WS_AvailabilityInput.parse(RestContext.request.requestBody.toString());

            // List of product availability.
            COMM_SL_WS_OCIAvailability availabilityService = new COMM_SL_WS_OCIAvailability();
            COMM_WS_AvailabilityOutput output = availabilityService.checkAvailability(inputRequest, true, COMM_OCI_Utils.DATETIME_LOCAL_STRING);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (COMM_WS_OCIException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_OCIAvailability');
            COMM_OCI_Utils.setResponse(res, 400, JSON.serialize(errorResp));
        } catch (Exception e) {
            errorResp.errorCode = COMM_OCI_Constants.ERROR_EXCEPTION_FOUND;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_OCIAvailability');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}