/**
 * @author           José Passos
 * @description      COMM_REP_Payment test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * José Passos      07/11/2024      100            Original version
 **/
@isTest
private class COMM_REP_PaymentTest {
    private final static COMM_REP_Payment PAYMENT_REP = new COMM_REP_Payment();

    @isTest
    static void getPaymentsByIdTest() {
        Payment payment = COMM_OMS_TestDataFactory.createPayment(10, null);
        insert payment;
        Set<Id> orderPaymentIdSet = new Set<Id>();
        orderPaymentIdSet.add(payment.id);

        Test.startTest();
        List<Payment> paymentList = PAYMENT_REP.getPaymentsById(orderPaymentIdSet);
        Test.stopTest();

        Assert.isTrue(paymentList.size() > 0, 'Payments should exists. Payments found: ' + paymentList.size());
        Assert.areEqual(1, paymentList.size(), 'Payments should match.');
    }

    @isTest
    static void getForPaygateRefundTest() {
        Payment payment = COMM_OMS_TestDataFactory.createPayment(10, null);
        insert payment;
        Set<Id> orderPaymentIdSet = new Set<Id>();
        orderPaymentIdSet.add(payment.id);

        Test.startTest();
        List<Payment> paymentList = PAYMENT_REP.getForPaygateRefund(orderPaymentIdSet);
        Test.stopTest();

        // we cannot insert payments with a PaymentGateway because we cannot insert PaymentGatewayProviders
        Assert.areEqual(0, paymentList.size(), 'Payments should match.');
    }

    @isTest
    static void getPaymentsByOrderSummaryIdTest() {
        COMM_OMS_TestDataFactory.createOrderAndPaymentAuthorization();
        OrderSummary orderSummary = [
            SELECT Id
            FROM OrderSummary
            LIMIT 1
        ];

        Test.startTest();
        List<Payment> paymentList = PAYMENT_REP.getPaymentsByOrderSummaryId(
            new Set<Id>{ orderSummary.id },
            new List<String>{ COMM_OMS_Constants.GIFTCARD_GATEWAY_NAME }
        );
        Test.stopTest();

        // we cannot insert payments with a PaymentGateway because we cannot insert PaymentGatewayProviders
        Assert.areEqual(0, paymentList.size(), 'Payments should match.');
    }
}