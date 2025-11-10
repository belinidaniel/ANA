/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_PayGateAdapter class.
 *                  Process payment requests for PayGate Multibanco/MBWay
 *
 *                  suppress reason: Adapter requires global access modifier
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      100            Original version
 */
@suppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_SL_PayGateAdapter implements commercepayments.PaymentGatewayAdapter {
    /**
     * @description Processes request
     * @param gatewayContext Payment Gateway context
     * @return PaymentGateway response
     */
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType;
        if (gatewayContext == null) {
            return new commercepayments.GatewayErrorResponse('400', 'Gateway context cannot be null');
        }
        //Get the instance of service based on the request type
        COMM_SL_AbstractTransactionService service = COMM_SL_TransactionServiceAdapter.getServiceInstance(gatewayContext);
        if (service != null) {
            return service.execute();
        } else {
            return new commercepayments.GatewayErrorResponse('400', 'Service not found');
        }
    }
}