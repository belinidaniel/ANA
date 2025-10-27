/**
 * @author Jose Passos
 * @description Web Service to pre reserve the availability of product - version 2
 *              Delete only releases temporary reservations instead of permanent reservations.
 *              To release permanent reservations either the PATCH is used (with an expirationSeconds of 1)
 *              or the deleve from v1 is used.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      24/05/2024       Original version
 * Jose Passos      24/05/2024       httpDel will be used to release temporary reservations by calling the reserve with 0 expiration seconds
 **/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
@RestResource(urlMapping='/oci/reserve/v2/*')
global with sharing class COMM_WS_OCIReservations_v2 {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to create a temporary or permanent stock reservation in OCI
     * Use case: add a product to the shopping cart in Commerce
     */
    @HttpPost
    global static void reserve() {
        RestResponse res = RestContext.response;

        try {
            // Parse the request
            COMM_WS_ReservationInput inputRequest = COMM_WS_ReservationInput.parse(RestContext.request.requestBody.toString());
            Boolean calculatePrices = true;

            // Reserve stock and list the reserved products
            COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();
            List<COMM_WS_ReservationOutput> outputProductList = reservationService.reserve(
                inputRequest,
                calculatePrices,
                COMM_OCI_Utils.DATETIME_LOCAL_STRING
            );
            COMM_OCI_Utils.setResponse(res, 201, JSON.serialize(outputProductList));
        } catch (COMM_WS_OCIException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 400, JSON.serialize(errorResp));
        } catch (Exception e) {
            errorResp.errorCode = COMM_OCI_Constants.ERROR_EXCEPTION_FOUND;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }

    /**
     * @description HTTP Method to force release a previous temporary stock reservation in OCI without having to wait for the full time
     * It requires the same previous reservationID and actionRequestIds and updates the expiration time for 1 sec
     * Use case: remove a product from the shopping cart in Commerce
     */
    @HttpDelete
    global static void releaseTemporaryReservation() {
        RestResponse res = RestContext.response;

        try {
            // Parse the request
            COMM_WS_ReservationInput inputRequest = COMM_WS_ReservationInput.parse(RestContext.request.requestBody.toString());
            Boolean calculatePrices = true;

            // Release reservations
            COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();
            // force time to 1 second
            inputRequest.expirationSeconds = 1;
            reservationService.reserve(inputRequest, calculatePrices, COMM_OCI_Utils.DATETIME_LOCAL_STRING);
            COMM_OCI_Utils.setResponse(res, 201, null);
        } catch (COMM_WS_OCIException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 400, JSON.serialize(errorResp));
        } catch (Exception e) {
            errorResp.errorCode = COMM_OCI_Constants.ERROR_EXCEPTION_FOUND;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }

    /**
     * @description HTTP Method to patch a previous reservation.
     * This will release a permanent reservation and create a new temporary reservation with the new expiration time
     * It requires a new reservationID and actionRequestIDs since once a reservation is set to permanent it cannot be updated.
     * Use case: recreate the shopping cart in Commerce if there was an issue on checkout.
     */
    @HttpPatch
    global static void revertPermanentReservation() {
        RestResponse res = RestContext.response;

        try {
            // Parse the request
            COMM_WS_ReservationInput inputRequest = COMM_WS_ReservationInput.parse(RestContext.request.requestBody.toString());

            // Reserve stock and list the reserved products
            COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();
            List<COMM_WS_ReservationOutput> outputProductList = reservationService.revertPermanentReservation(
                inputRequest,
                true,
                COMM_OCI_Utils.DATETIME_LOCAL_STRING
            );
            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(outputProductList));
        } catch (COMM_WS_OCIException e) {
            errorResp.errorCode = e.errorCode;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 400, JSON.serialize(errorResp));
        } catch (Exception e) {
            errorResp.errorCode = COMM_OCI_Constants.ERROR_EXCEPTION_FOUND;
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_OCIReservation');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}