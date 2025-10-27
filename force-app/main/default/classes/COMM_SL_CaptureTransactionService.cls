/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_CaptureTransactionService class.
 *                  Capture service class.
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      100            Original version
 */
public class COMM_SL_CaptureTransactionService extends COMM_SL_AbstractTransactionService {
    private final String CAPTURE_ENDPOINT = '/api/CapturePreAuthPayment';
    private final String HTTP_OK = '200';

    public COMM_SL_CaptureTransactionService(commercepayments.paymentGatewayContext gatewayContext) {
        super(gatewayContext);
    }

    /**
     * @description Function to build request for Capture Transaction
     *              Creates a new request and set request body, authorization parameters and other related fields
     * @return HttpRequest with the data to be sent to Paygate API
     */
    public override HttpRequest buildRequest() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CAPTURE_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(buildCaptureRequestBody((commercepayments.CaptureRequest) gatewayContext.getPaymentRequest()));
        return req;
    }

    /**
     * @description Function to build gateway response for Capture Transaction
     *              The input is the response from gateway
     *              It creates and returns CptureGatewayResponse from the HttpResponse
     * @param response HttpResponse received from Paygate API
     * @return commercepayments.GatewayResponse
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response) {
        commercepayments.CaptureResponse captureResponse;
        String statusCode = String.valueOf(response.getStatusCode());
        Map<String, Object> responseBodyMap;
        try {
            responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        } catch (Exception e) {
            responseBodyMap = new Map<String, Object>();
        }

        if (statusCode.equals(HTTP_OK)) {
            captureResponse = getCaptureResponse(responseBodyMap);
        } else {
            String errorMessage = (String) responseBodyMap.get('title');
            return new commercepayments.GatewayErrorResponse(statusCode, errorMessage);
        }

        return captureResponse;
    }

    /**
     * @description Function to create gateway response for Capture Transaction
     * @param responseBodyMap Map with the response body from PayGate API
     * @return commercepayments.CaptureResponse
     */
    private commercepayments.CaptureResponse getCaptureResponse(Map<String, Object> responseBodyMap) {
        commercepayments.CaptureResponse captureResponse = new commercepayments.CaptureResponse();
        String salesforceResultCode;
        Boolean isSuccess = responseBodyMap.get('Success') == true;
        captureResponse.setGatewayDate(System.now());
        captureResponse.setAmount(getAmountToCapture());
        captureResponse.setGatewayResultCode((String) responseBodyMap.get('ReturnCode'));
        captureResponse.setGatewayReferenceNumber((String) responseBodyMap.get('TransactionID'));
        captureResponse.setGatewayResultCodeDescription((String) responseBodyMap.get('LongReturnMessage'));
        captureResponse.setGatewayReferenceDetails(getAdditionalPaymentInformation(responseBodyMap));
        if (isSuccess) {
            salesforceResultCode = SUCCESS_SALESFORCE_RESULT_CODE.name();
        } else {
            salesforceResultCode = DECLINE_SALESFORCE_RESULT_CODE.name();
        }
        captureResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(salesforceResultCode));

        return captureResponse;
    }

    /**
     * @description get from the gateway context the amount that was requested to capture
     * @return Double
     */
    private Double getAmountToCapture() {
        return ((commercepayments.CaptureRequest) gatewayContext.getPaymentRequest()).amount;
    }

    /**
     * @description get gateway reference number from gateway context that was requested to capture
     * @return String
     */
    private String getGatewayRefNumberFromAuthorization() {
        String paymentAuthorizationId = ((commercepayments.CaptureRequest) gatewayContext.getPaymentRequest()).paymentAuthorizationId;
        return getGatewayRefNumberFromAuthorization(paymentAuthorizationId);
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
     * @description Function to build request body for Capture Transaction
     * @param captureRequest  - The capture transaction request object
     * @return JSON string with the capture request body
     */
    private String buildCaptureRequestBody(commercepayments.CaptureRequest captureRequest) {
        COMM_Paygate_Merchant_Settings__c paygateSettings = COMM_Paygate_Merchant_Settings__c.getInstance();

        Map<String, Object> captureRequestBody = new Map<String, Object>{
            'ACCESS_TOKEN' => paygateSettings.COMM_Access_Token__c,
            'CAPTURE_AMOUNT' => captureRequest.amount,
            'LANGUAGE' => 'PT',
            'MERCHANT_CODE' => paygateSettings.COMM_Merchant_Code__c,
            'PAYMENT_REF' => getGatewayRefNumberFromAuthorization(captureRequest.paymentAuthorizationId)
        };

        return JSON.serialize(captureRequestBody);
    }

    /**
     * @description Fetch es the Gateway Reference Number from Authorization.
     * @param paymentAuthorizationId  - The Payment Authorization Id to be queried
     * @return  The Gateway Ref Number
     */
    private String getGatewayRefNumberFromAuthorization(Id paymentAuthorizationId) {
        List<PaymentAuthorization> paymentAuthorizations = new COMM_REP_PaymentAuthorization()
            .getPaymentAuthorizationsById(new Set<Id>{ paymentAuthorizationId });
        if (!paymentAuthorizations.isEmpty()) {
            return paymentAuthorizations[0].GatewayRefNumber;
        } else {
            return '';
        }
    }
}