/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_GiftCardAdapter class.
 *                  Process payment requests for Gift Cards
 *
 *                  suppress reason: Adapter requires global access modifier
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date                Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  24/03/2024          Original version
 * Diogo Gonçalves  17/09/2024          ECOMM-481: Changed the API endpoint
 */
@suppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class COMM_SL_GiftCardAdapter implements commercepayments.PaymentGatewayAdapter {
    /**
     * @description Processes request
     * @param gatewayContext Payment Gateway context
     * @return PaymentGateway response
     */
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        if (gatewayContext == null) {
            return new commercepayments.GatewayErrorResponse('400', 'Gateway context cannot be null');
        }
        //Get the instance of service based on the request type
        COMM_SL_AbstractTransactionService service;
        if (requestType == commercepayments.RequestType.Capture) {
            return createCaptureResponse((commercepayments.CaptureRequest) gatewayContext.getPaymentRequest());
        } else if (requestType == commercepayments.RequestType.ReferencedRefund) {
            service = new COMM_SL_RefundGiftCardService(gatewayContext);
        }
        if (service != null) {
            return service.execute();
        } else {
            return new commercepayments.GatewayErrorResponse('400', 'Service not found');
        }
    }

    /**
     * @description Creates response for capture request
     * @param captureRequest Capture request
     * @return PaymentGateway response
     */
    public commercepayments.GatewayResponse createCaptureResponse(commercepayments.CaptureRequest captureRequest) {
        commercepayments.CaptureResponse captureResponse = new commercepayments.CaptureResponse();

        if (captureRequest.amount == null) {
            new commercepayments.GatewayErrorResponse('400', 'Required Field Missing : Amount');
        }

        captureResponse.setAmount(captureRequest.amount);
        captureResponse.setGatewayDate(System.now());
        captureResponse.setGatewayResultCode('00');
        captureResponse.setGatewayResultCodeDescription('Transaction Normal');
        captureResponse.setGatewayReferenceNumber('SF' + COMM_GEN_Utility.getRandomNumber(6));
        captureResponse.setSalesforceResultCodeInfo(new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success));
        return captureResponse;
    }
}