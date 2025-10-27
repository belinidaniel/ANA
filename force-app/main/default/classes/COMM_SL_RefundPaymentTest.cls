/**
 * @author           Diogo Gonçalves
 * @description      Test class for COMM_SL_RefundPayment
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Code Coverage   Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  24/07/2024      94              ECOMM-1758: Original version
 **/
@isTest
private class COMM_SL_RefundPaymentTest {
    @isTest
    static void shouldReceivePaygateSuccess() {
        COMM_SL_RefundPayment.isPaygateTest = true;
        Payment payment = COMM_OMS_TestDataFactory.createPayment(10, null);
        insert payment;
        COMM_SL_RefundPaymentInput input = new COMM_SL_RefundPaymentInput();
        input.paymentId = payment.Id;
        input.amount = payment.Amount;
        List<String> transactionIds = new List<String>();

        Test.setMock(HttpCalloutMock.class, new COMM_SL_PaygateServiceMock());
        Test.startTest();
        transactionIds = COMM_SL_RefundPayment.refundPayment(new List<COMM_SL_RefundPaymentInput>{ input });
        Assert.areEqual(1, Limits.getCallouts(), 'Callout to paygate was not made');
        Test.stopTest();
        Assert.isFalse(transactionIds.isEmpty(), 'No transaction Id returned');
        Assert.isTrue(String.isNotBlank(transactionIds[0]), 'Transaction Id should not be blank');
    }

    @isTest
    static void shouldReceiveConnectAPISuccess() {
        Payment payment = COMM_OMS_TestDataFactory.createPayment(10, null);
        insert payment;
        COMM_SL_RefundPaymentInput input = new COMM_SL_RefundPaymentInput();
        input.paymentId = payment.Id;
        input.amount = payment.Amount;

        Test.setMock(HttpCalloutMock.class, new COMM_SL_PaygateServiceMock());
        Test.startTest();
        COMM_SL_RefundPayment.refundPayment(new List<COMM_SL_RefundPaymentInput>{ input });
        Test.stopTest();
        Assert.isTrue(COMM_SL_RefundPayment.isConnectAPIRequestSent, 'Connect API was not made');
    }
}