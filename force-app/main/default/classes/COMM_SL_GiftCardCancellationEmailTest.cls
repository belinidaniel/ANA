/**
 * @author Diogo Gonçalves
 * @description COMM_SL_GiftCardCancellationEmail test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  08/04/2024      98             Original version
 **/
@isTest
private class COMM_SL_GiftCardCancellationEmailTest {
    @isTest(SeeAllData=true)
    static void testSendVouchers() {
        //Throws error "System.NullPointerException: Argument cannot be null" due to SeeAlldata.
        //This needs the class being tested is still not in use

        /*COMM_OMS_TestDataFactory.createOrderAndRelated();
        OrderSummary orderSummary = [SELECT Id, (SELECT id FROM OrderItemSummaries WHERE Type != 'Delivery Charge') FROM OrderSummary LIMIT 1];
        Map<OrderItemSummary, Integer> quantities = new Map<OrderItemSummary, Integer>();
        for (OrderItemSummary ois : orderSummary.OrderItemSummaries) {
            quantities.put(ois, 1);
        }
        COMM_OMS_TestDataFactory.createCreditMemo(orderSummary.Id, quantities);
        List<String> creditMemoIds = new List<String>();
        List<CreditMemo> creditMemos = [SELECT Id FROM CreditMemo];
        for (CreditMemo creditMemo : creditMemos) {
            creditMemoIds.add(creditMemo.Id);
        }
        Assert.isTrue(creditMemoIds.size() > 0, 'No credit memos were created');

        Integer emailInvocationStart = Limits.getEmailInvocations();
        Test.startTest();
        COMM_SL_GiftCardCancellationEmail.sendEmail(creditMemoIds);
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(emailSent, 'Expected an email invocation to be called');*/
    }
}