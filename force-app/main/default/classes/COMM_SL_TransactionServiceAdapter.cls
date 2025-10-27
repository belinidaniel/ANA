/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_RefRefundTransactionService class.
 *                  The class to get the instance of a service based on the request type
 *                  The class stores the instance of each service statically to implement singleton pattern
 *                  Referenced refund service class.
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      Original version
 */
public class COMM_SL_TransactionServiceAdapter {
    private static COMM_SL_CaptureTransactionService captureTxnService;
    private static COMM_SL_RefRefundTransactionService refRefundTxnService;

    /**
     * @description Static method that returns the instance of a service based on the request type
     * @param gatewayContext Payment Gateway context
     * @return COMM_SL_AbstractTransactionService Service used for the request
     */
    public static COMM_SL_AbstractTransactionService getServiceInstance(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        //Capture Service
        if (requestType == commercepayments.RequestType.Capture) {
            if (captureTxnService == null) {
                captureTxnService = new COMM_SL_CaptureTransactionService(gatewayContext);
            }
            return captureTxnService;
        } else if (requestType == commercepayments.RequestType.ReferencedRefund) {
            if (refRefundTxnService == null) {
                refRefundTxnService = new COMM_SL_RefRefundTransactionService(gatewayContext);
            }
            return refRefundTxnService;
        } else {
            return null;
        }
    }
}