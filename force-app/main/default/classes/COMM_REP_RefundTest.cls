/**
 * @author           José Passos
 * @description      COMM_REP_Refund test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * José Passos      07/11/2024      100            Original version
 **/
@isTest
private class COMM_REP_RefundTest {
    private final static COMM_REP_Refund REFUND_REP = new COMM_REP_Refund();

    @isTest
    static void getRefundsByOrderSummaryIdTest() {
        COMM_OMS_TestDataFactory.createOrderAndPaymentAuthorization();
        OrderSummary orderSummary = [
            SELECT Id
            FROM OrderSummary
            LIMIT 1
        ];

        COMM_OMS_TestDataFactory.createRefund(orderSummary.id, 1);

        Test.startTest();
        List<Refund> refundList = REFUND_REP.getRefundsByOrderSummaryId(
            new Set<Id>{ orderSummary.id },
            new List<String>{ COMM_OMS_Constants.GIFTCARD_GATEWAY_NAME }
        );
        Test.stopTest();

        // we cannot insert payments with a PaymentGateway because we cannot insert PaymentGatewayProviders
        Assert.areEqual(0, refundList.size(), 'Refund should match.');
    }
}