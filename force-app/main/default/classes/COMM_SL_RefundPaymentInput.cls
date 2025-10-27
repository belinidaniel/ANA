/**
 * @author           Diogo Gonçalves
 * @description      Class to define the input for the invocable method in COMM_SL_RefundPayment
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    20/08/2024     ECOMM-1758: Original version
 **/
public inherited sharing class COMM_SL_RefundPaymentInput {
    @InvocableVariable(label='Payment Id' description='ID of the payment linked to the referenced refund request' required=true)
    public String paymentId;

    @InvocableVariable(label='Account Id' description='ID of the account linked to the referenced refund request' required=false)
    public String accountId;

    @InvocableVariable(label='Amount' description='Amount refunded' required=true)
    public Double amount;

    @InvocableVariable(label='Idempotency Key' description='Idempotency Key' required=false)
    public String idempotencyKey;

    @InvocableVariable(
        label='Client Context'
        description='Context for payment APIs. Used for a payment caller to re-establish context.'
        required=false
    )
    public String clientContext;

    @InvocableVariable(label='Comments' description='Optional comments for the refund.' required=false)
    public String comments;

    @InvocableVariable(label='Effective Date' description='Date when the refund becomes effective.' required=false)
    public Datetime effectiveDate;

    /**
     * @description Create instance of ConnectApi.ReferencedRefundRequest
     * @return ConnectApi.ReferencedRefundRequest
     */
    public ConnectApi.ReferencedRefundRequest getConnectApiRefundRequest() {
        ConnectApi.ReferencedRefundRequest refundRequest = new ConnectApi.ReferencedRefundRequest();
        refundRequest.accountId = this.accountId;
        refundRequest.amount = this.amount;
        refundRequest.comments = this.comments;
        refundRequest.effectiveDate = this.effectiveDate;
        refundRequest.idempotencyKey = this.idempotencyKey;
        return refundRequest;
    }

    /**
     * @description Function to build request for paygate
     * @param refundRequest - Paygate refund request object
     * @return JSON string with the refund request
     */
    public Map<String, Object> getPaygateRefundRequest(Payment paymentToRefund) {
        return new Map<String, Object>{
            'PAYMENT_REF' => paymentToRefund.OrderPaymentSummary.OrderSummary.OrderNumber,
            'TRANSACTION_ID' => paymentToRefund.GatewayRefNumber,
            'CURRENCY' => 'EUR',
            'ORIGINAL_TOTAL_AMOUNT' => paymentToRefund.Amount,
            'REFUND_TOTAL_AMOUNT' => this.amount
        };
    }
}