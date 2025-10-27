/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_RefRefundTransactionService class.
 *                  Referenced refund service class.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      Original version
 */
public class COMM_SL_RefRefundTransactionService extends COMM_SL_AbstractTransactionService {
    private final String REFERENCED_REFUND_ENDPOINT = '/api/DoRefund';
    private final String HTTP_OK = '200';

    public COMM_SL_RefRefundTransactionService(commercepayments.paymentGatewayContext gatewayContext) {
        super(gatewayContext);
    }

    /**
     * @description Function to build request for Referenced Refund Transaction
     *              Creates a new request and set request body, authorization parameters and other related fields
     * @return HttpRequest body to be sent to PayGate API
     */
    public override HttpRequest buildRequest() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(REFERENCED_REFUND_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(buildRefRefundRequestBody((commercepayments.ReferencedRefundRequest) gatewayContext.getPaymentRequest()));
        return req;
    }

    /**
     * @description Function to build gateway response for Referenced Refund Transaction
     *              The input is the response from gateway
     *              It creates and returns CptureGatewayResponse from the HttpResponse
     * @param response - HttpResponse received from PayGate API
     * @return - ReferencedRefundResponse object built
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response) {
        commercepayments.ReferencedRefundResponse refundResponse;
        String statusCode = String.valueOf(response.getStatusCode());
        Map<String, Object> responseBodyMap;
        try {
            responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        } catch (Exception e) {
            responseBodyMap = new Map<String, Object>();
        }

        //PayGate returns HTTP Status Code 200 even when Success = false. 400 on bad request.
        if (statusCode.equals(HTTP_OK)) {
            refundResponse = getReferencedRefundResponse(responseBodyMap);
        } else {
            String errorMessage = (String) responseBodyMap.get('title');
            return new commercepayments.GatewayErrorResponse(statusCode, errorMessage);
        }

        return refundResponse;
    }

    /**
     * @description Function to create gateway response for Refund Transaction
     * @param responseBodyMap Map with the response body from PayGate API
     * @return commercepayments.ReferencedRefundResponse
     */
    private commercepayments.ReferencedRefundResponse getReferencedRefundResponse(Map<String, Object> responseBodyMap) {
        commercepayments.ReferencedRefundResponse refundResponse = new commercepayments.ReferencedRefundResponse();
        Boolean isSuccess = responseBodyMap.get('Success') == true;
        String salesforceResultCode;
        refundResponse.setGatewayDate(System.now());
        refundResponse.setAmount(getAmountToRefund());
        refundResponse.setGatewayResultCode((String) responseBodyMap.get('ReturnCode'));
        refundResponse.setGatewayReferenceNumber(getGatewayRefNumberFromPayment());
        refundResponse.setGatewayResultCodeDescription((String) responseBodyMap.get('LongReturnMessage'));
        refundResponse.setGatewayReferenceDetails(getAdditionalPaymentInformation(responseBodyMap));
        if (isSuccess) {
            salesforceResultCode = SUCCESS_SALESFORCE_RESULT_CODE.name();
        } else {
            salesforceResultCode = DECLINE_SALESFORCE_RESULT_CODE.name();
        }
        refundResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(salesforceResultCode));
        return refundResponse;
    }

    /**
     * @description get from the gateway context the amount that was requested to refund
     * @return Double amount to refund
     */
    private Double getAmountToRefund() {
        return ((commercepayments.ReferencedRefundRequest) gatewayContext.getPaymentRequest()).amount;
    }

    /**
     * @description Fetch the Gateway Reference Number of the payment to refund.
     *              Uses the context to get the paymentId and run the query.
     * @return String - Gateway Reference Number of the payment to refund
     */
    private String getGatewayRefNumberFromPayment() {
        Id paymentId = ((commercepayments.ReferencedRefundRequest) gatewayContext.getPaymentRequest()).paymentId;
        Payment payment = getPayment(paymentId);
        return payment.GatewayRefNumber;
    }

    /**
     * @description Get additional payment information that can't be stored in the response object
     *
     * @param responseBodyMap - Map with the data returned in the PayGate response
     * @return JSON string with the additional information.
     */
    private String getAdditionalPaymentInformation(Map<String, Object> responseBodyMap) {
        Map<String, Object> additionalPaymentInformation = new Map<String, Object>();
        Set<String> additionalFields = new Set<String>{
            'OperationProgressStatus',
            'Success',
            'InProgress',
            'ShortReturnMessage',
            'SessionToken',
            'PaymentID',
            'TransactionID',
            'WalletID'
        };

        for (String key : responseBodyMap.keySet()) {
            if (additionalFields.contains(key)) {
                additionalPaymentInformation.put(key, responseBodyMap.get(key));
            }
        }

        return JSON.serialize(additionalPaymentInformation);
    }

    /**
     * @description Function to build request body for Referenced Refund Transaction
     * @param refundRequest - Referenced refund request  object
     * @return JSON string with the refund request body
     */
    private String buildRefRefundRequestBody(commercepayments.ReferencedRefundRequest refundRequest) {
        COMM_Paygate_Merchant_Settings__c paygateSettings = COMM_Paygate_Merchant_Settings__c.getInstance();
        String accessToken = paygateSettings.COMM_Access_Token__c;
        String merchantCode = paygateSettings.COMM_Merchant_Code__c;
        Payment paymentToRefund = getPayment(refundRequest.paymentId);

        return JSON.serialize(
            new Map<String, Object>{
                'ACCESS_TOKEN' => accessToken,
                'MERCHANT_CODE' => merchantCode,
                'PAYMENT_REF' => paymentToRefund.OrderPaymentSummary.OrderSummary.OrderNumber,
                'TRANSACTION_ID' => paymentToRefund.GatewayRefNumber,
                'CURRENCY' => 'EUR',
                'ORIGINAL_TOTAL_AMOUNT' => paymentToRefund.Amount,
                'REFUND_TOTAL_AMOUNT' => refundRequest.amount
            }
        );
    }

    /**
     * @description Fetches the Gateway Reference Number from a payment.
     * @param paymentId  - The Payment Id to be queried
     * @return  The Gateway Ref Number
     */
    private Payment getPayment(Id paymentId) {
        List<Payment> payments = new COMM_REP_Payment().getPaymentsById(new Set<Id>{ paymentId });
        if (!payments.isEmpty()) {
            return payments[0];
        } else {
            return new Payment();
        }
    }
}