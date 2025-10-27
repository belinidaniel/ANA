/**
 * @author Jose Passos
 * @description Web Service to pre reserve the availability of product.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 * Jose Passos      24/05/2024       httpDel will be used to release temporary reservations by calling the reserve with 0 expiration seconds
 **/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
@RestResource(urlMapping='/oci/reserve/v1/*')
global with sharing class COMM_WS_OCIReservations {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to reserve stock in OCI
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
     * @description HTTP Method to release a previous stock reservation in OCI
     */
    @HttpDelete
    global static void release() {
        RestResponse res = RestContext.response;

        try {
            // Parse the request
            COMM_WS_ReservationInput inputRequest = COMM_WS_ReservationInput.parse(RestContext.request.requestBody.toString());

            // Release reservations
            COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();
            reservationService.release(inputRequest, COMM_OCI_Utils.DATETIME_LOCAL_STRING);
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
     * This will release the previous reserved stock and reserve it again with the new expiration time
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