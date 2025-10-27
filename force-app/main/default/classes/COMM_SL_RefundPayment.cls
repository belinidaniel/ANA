/**
 * @author           Diogo Gonçalves
 * @description      Service class with an invocable method to make a refund
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    24/07/2024     ECOMM-1758: Original version
 **/
public inherited sharing class COMM_SL_RefundPayment {
    public static final String ACCOUNT_ID_KEY = 'accountId';
    public static final String EFFECTIVE_DATE_KEY = 'effectiveDate';
    public static final String COMMENTS_KEY = 'comments';
    public static final String AMOUNT_KEY = 'amount';
    public static final String IDEMPOTENCY_KEY = 'idempotencyKey';
    public static final String ERROR_CODE = 'errorCode';
    public static final String MESSAGE = 'message';

    @TestVisible
    private static Boolean isPaygateTest = false;
    @TestVisible
    private static Boolean isConnectAPIRequestSent = false;

    public class COMM_SL_RefundPaymentException extends Exception {
    }

    /**
     * @description Method to create a refund based on the payment
     *
     * NOTE: Using the method ConnectApi.Payments.refund(refundRequest, paymentId) would be the best approach but,
     * due to an internal error on Salesforce that is under investigation, we will use the Paygate API directly.
     *
     * @param refundInputs List of COMM_SL_RefundPaymentInput containing the information about the refund
     * @throws COMM_SL_RefundPaymentException
     */
    @InvocableMethod(category='OMS' label='Refund Payment' description='Refunds a payment via Connect API')
    public static List<String> refundPayment(List<COMM_SL_RefundPaymentInput> refundInputs) {
        COMM_IREP_Payment paymentRep = new COMM_REP_Payment();
        Map<Id, Payment> paygatePayments = new Map<Id, Payment>(paymentRep.getForPaygateRefund(getPaymentIds(refundInputs)));
        List<String> transactionIds = new List<String>();
        for (COMM_SL_RefundPaymentInput input : refundInputs) {
            String transactionId = '';
            Payment paygatePayment = paygatePayments.get(input.paymentId);
            if (paygatePayment != null || (Test.isRunningTest() && isPaygateTest)) {
                transactionId = handlePaygatePayments(input, paygatePayment);
            } else {
                handlePaymentsWithConnectAPI(input);
            }
            transactionIds.add(transactionId);
        }
        return transactionIds;
    }

    /**
     * @description Handle paygate payments
     * @param input COMM_SL_RefundPaymentInput
     * @param payment Payment
     * @throws COMM_SL_RefundPaymentException
     */
    private static String handlePaygatePayments(COMM_SL_RefundPaymentInput input, Payment payment) {
        COMM_Paygate_Merchant_Settings__c paygateSettings = COMM_Paygate_Merchant_Settings__c.getInstance();
        if (Test.isRunningTest() && isPaygateTest) {
            payment = new Payment(GatewayRefDetails = '{}', GatewayRefNumber = 'GatewayRefNumber', Amount = 10);
            paygateSettings.COMM_Access_Token__c = 'accessToken';
            paygateSettings.COMM_Merchant_Code__c = 'merchantCode';
        }
        COMM_SL_PaygateService paygate = new COMM_SL_PaygateService(paygateSettings.COMM_Access_Token__c, paygateSettings.COMM_Merchant_Code__c);
        Map<String, Object> paygateResponse = paygate.doRefund(input.getPaygateRefundRequest(payment));
        if (paygateResponse.get('Success') != true) {
            throw new COMM_SL_RefundPaymentException(String.valueOf(paygateResponse.get('LongReturnMessage')));
        } else {
            return String.valueOf(paygateResponse.get('TransactionID'));
        }
    }

    /**
     * @description Handle non-Paygate payments
     * @param input COMM_SL_RefundPaymentInput
     * @throws COMM_SL_RefundPaymentException
     */
    private static void handlePaymentsWithConnectAPI(COMM_SL_RefundPaymentInput refundInput) {
        ConnectApi.ReferencedRefundRequest refundRequest = refundInput.getConnectApiRefundRequest();
        ConnectApi.ReferencedRefundResponse refundResponse;
        if (!Test.isRunningTest()) {
            refundResponse = ConnectApi.Payments.refund(refundRequest, refundInput.paymentId);
        } else {
            isConnectAPIRequestSent = true;
        }
        if (refundResponse?.error != null) {
            throw new COMM_SL_RefundPaymentException(refundResponse.error.message);
        }
    }

    /**
     * @description Get paymentId from each RefunPaymentInput
     * @param refundInputs List of COMM_SL_RefundPaymentInput containing the information about the refund
     * @return Set of Payment Ids
     */
    private static Set<Id> getPaymentIds(List<COMM_SL_RefundPaymentInput> refundInputs) {
        Set<Id> paymentIds = new Set<Id>();
        for (COMM_SL_RefundPaymentInput input : refundInputs) {
            paymentIds.add(input.paymentId);
        }
        return paymentIds;
    }
}