/**
 * @author Jose Passos
 * @description This class is a mock payment adapter shared by Salesforce.
 * This will simulate Credit payments for affiliates customers that will be billed in SAP in the end of month.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      25/03/2024       Original version
 */
@suppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_SL_CreditPaymentAdapter implements commercepayments.PaymentGatewayAdapter {
    private static final commercepayments.SalesforceResultCodeInfo SUCCESS_SALESFORCE_RESULT_CODE_INFO = new commercepayments.SalesforceResultCodeInfo(
        commercepayments.SalesforceResultCode.Success
    );
    private static final commercepayments.SalesforceResultCodeInfo DECLINE_SALESFORCE_RESULT_CODE_INFO = new commercepayments.SalesforceResultCodeInfo(
        commercepayments.SalesforceResultCode.Decline
    );

    /**
     * @description Processes request
     * @param gatewayContext PaymentGateway context
     * @return PaymentGateway response
     */
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.GatewayResponse response;

        try {
            if (requestType == commercepayments.RequestType.Capture) {
                response = createCaptureResponse((commercepayments.CaptureRequest) gatewayContext.getPaymentRequest());
            } else if (requestType == commercepayments.RequestType.ReferencedRefund) {
                response = createRefundResponse((commercepayments.ReferencedRefundRequest) gatewayContext.getPaymentRequest());
            }
            return response;
        } catch (COMM_SL_CreditPaymentAdapterException e) {
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_SL_CreditPaymentAdapter');
            commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('400', e.getMessage());
            return error;
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
            throw new COMM_SL_CreditPaymentAdapterException('Required Field Missing : Amount');
        }

        captureResponse.setAmount(captureRequest.amount);
        captureResponse.setGatewayDate(System.now());
        captureResponse.setGatewayResultCode('00');
        captureResponse.setGatewayResultCodeDescription('Transaction Normal');
        captureResponse.setGatewayReferenceNumber('SF' + COMM_GEN_Utility.getRandomNumber(6));
        captureResponse.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        return captureResponse;
    }

    /**
     * @description Creates response for refund request
     * @param refundRequest Refund request
     * @return PaymentGateway response
     */
    public commercepayments.GatewayResponse createRefundResponse(commercepayments.ReferencedRefundRequest refundRequest) {
        commercepayments.ReferencedRefundResponse refundResponse = new commercepayments.ReferencedRefundResponse();

        if (refundRequest.amount == null) {
            throw new COMM_SL_CreditPaymentAdapterException('Required Field Missing : Amount');
        }

        refundResponse.setAmount(refundRequest.amount);
        refundResponse.setGatewayResultCode('00');
        refundResponse.setGatewayDate(System.now());
        refundResponse.setGatewayResultCodeDescription('Transaction Normal');
        refundResponse.setGatewayReferenceNumber('SF' + COMM_GEN_Utility.getRandomNumber(6));
        refundResponse.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        return refundResponse;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_CreditPaymentAdapterException extends Exception {
    }
}