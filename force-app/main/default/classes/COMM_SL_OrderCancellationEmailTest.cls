/**
 * @author Diogo Gonçalves
 * @description COMM_SL_OrderCancellationEmail test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  05/09/2024      98             Original version
 **/
@isTest
private class COMM_SL_OrderCancellationEmailTest {
    @isTest(SeeAllData=true)
    static void testSendOrderCancellationEmail() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
        OrderSummary orderSummary = [SELECT Id FROM OrderSummary LIMIT 1];
        Map<OrderItemSummary, Integer> quantities = new Map<OrderItemSummary, Integer>();
        for (OrderItemSummary ois : orderSummary.OrderItemSummaries) {
            quantities.put(ois, 1);
        }

        Integer emailInvocationStart = Limits.getEmailInvocations();
        Test.startTest();
        COMM_SL_OrderCancellationEmail.sendEmail(new List<String>{ orderSummary.Id });
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(emailSent, 'Expected an email invocation to be called');
    }
}