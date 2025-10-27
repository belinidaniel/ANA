/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_RefundGiftCardService class.
 *                  The class to get the instance of a service based on the request type
 *                  The class stores the instance of each service statically to implement singleton pattern
 *                  Referenced refund service class.
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      Original version
 * Diogo Gonçalves  17/09/2024      ECOMM-481: Changed the API endpoint
 */
public with sharing class COMM_SL_RefundGiftCardService extends COMM_SL_AbstractTransactionService {
    private final String HTTP_OK = '200';

    public COMM_SL_RefundGiftCardService(commercepayments.paymentGatewayContext gatewayContext) {
        super(gatewayContext);
    }

    /**
     * @description Function to build request for Referenced Refund Transaction
     *              Creates a new request and set request body, authorization parameters and other related fields
     * @return HttpRequest body to be sent to PayGate API
     */
    public override HttpRequest buildRequest() {
        COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();
        String configLabel = 'SCAPI_Create_Gift_Certificates';
        commercepayments.ReferencedRefundRequest refundRequest = (commercepayments.ReferencedRefundRequest) gatewayContext.getPaymentRequest();

        COMM_OMS_CalloutSettings__mdt calloutConfiguration = calloutSettingsRep.getCalloutSetting(configLabel);
        String endpoint = calloutConfiguration.Endpoint_URI__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(calloutConfiguration.HTTP_Method__c);
        req.setBody(buildRefundRequestBody(refundRequest));
        return req;
    }

    /**
     * @description Function to build gateway response for Referenced Refund Transaction
     *              The input is the response from gateway
     *              It creates and returns GatewayResponse from the HttpResponse
     * @param response - HttpResponse received from PayGate API
     * @return - ReferencedRefundResponse object built
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response) {
        commercepayments.ReferencedRefundResponse refundResponse;
        String statusCode = String.valueOf(response.getStatusCode());
        COMM_SL_GiftCertificateWrapper giftCertificateResponse;
        try {
            giftCertificateResponse = (COMM_SL_GiftCertificateWrapper) JSON.deserialize(response.getBody(), COMM_SL_GiftCertificateWrapper.class);
        } catch (Exception e) {
            giftCertificateResponse = new COMM_SL_GiftCertificateWrapper();
        }

        if (statusCode.equals(HTTP_OK)) {
            refundResponse = getReferencedRefundResponse(giftCertificateResponse);
        } else {
            new commercepayments.GatewayErrorResponse(statusCode, 'OCAPI returned an error updating the Gift Certificate');
        }

        return refundResponse;
    }

    /**
     * @description Function to create gateway response for Refund Transaction
     * @param responseBodyMap Map with the response body from PayGate API
     * @return commercepayments.ReferencedRefundResponse
     */
    private commercepayments.ReferencedRefundResponse getReferencedRefundResponse(COMM_SL_GiftCertificateWrapper giftCertificateResponse) {
        commercepayments.ReferencedRefundResponse refundResponse = new commercepayments.ReferencedRefundResponse();
        COMM_SL_GiftCertificateWrapper.GiftCertificate giftCertificate = giftCertificateResponse.created[0];
        String salesforceResultCode;
        refundResponse.setGatewayDate(System.now());
        refundResponse.setAmount(giftCertificate.amount);
        refundResponse.setGatewayReferenceNumber(giftCertificate.code);
        refundResponse.setGatewayReferenceDetails(JSON.serialize(giftCertificateResponse));
        salesforceResultCode = SUCCESS_SALESFORCE_RESULT_CODE.name();
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
     * @description Function to build request body for Refund Transaction
     * @param refundRequest - Referenced refund request  object
     * @return JSON string with the refund request body
     */
    private String buildRefundRequestBody(commercepayments.ReferencedRefundRequest refundRequest) {
        COMM_SL_GiftCertificateWrapper giftCertificateWrapper = new COMM_SL_GiftCertificateWrapper();
        COMM_SL_GiftCertificateWrapper.GiftCertificate giftCertificate = new COMM_SL_GiftCertificateWrapper.GiftCertificate();
        OrderSummary os = getOrderSummaryOfPayment(refundRequest.paymentId);
        giftCertificate.amount = refundRequest.amount;
        giftCertificate.orderNumber = os.OrderNumber;
        giftCertificate.recipientName = os.Account.Name;
        if (!os.OrderDeliveryGroupSummaries.isEmpty()) {
            giftCertificate.recipientEmail = os.OrderDeliveryGroupSummaries[0].EmailAddress;
        }
        giftCertificate.senderName = COMM_OMS_Constants.ANA_AEROPORTOS;
        giftCertificate.sendEmail = true;
        giftCertificateWrapper.addGiftCertificate(giftCertificate);
        return JSON.serialize(giftCertificateWrapper, true);
    }

    /**
     * @description Get the order summary of a given payment
     * @param paymentId  - The Payment Id to be queried
     * @return  The Order Summary
     */
    private OrderSummary getOrderSummaryOfPayment(Id paymentId) {
        if (Test.isRunningTest()) {
            return new OrderSummary();
        }
        COMM_IREP_OrderSummary orderSummaryRepo = new COMM_REP_OrderSummary();
        Payment payment = getPayment(paymentId);
        List<OrderSummary> orderSummariesList = orderSummaryRepo.getByIds(new List<Id>{ payment.OrderPaymentSummary.OrderSummaryId });
        if (!orderSummariesList.isEmpty()) {
            return orderSummariesList[0];
        } else {
            return null;
        }
    }

    /**
     * @description Fetches the Gateway Reference Number from a payment.
     * @param paymentId  - The Payment Id to be queried
     * @return  The Gateway Ref Number
     */
    private Payment getPayment(Id paymentId) {
        COMM_IREP_Payment paymentRepo = new COMM_REP_Payment();
        List<Payment> payments = paymentRepo.getPaymentsById(new Set<Id>{ paymentId });
        if (!payments.isEmpty()) {
            return payments[0];
        } else {
            return new Payment();
        }
    }
}