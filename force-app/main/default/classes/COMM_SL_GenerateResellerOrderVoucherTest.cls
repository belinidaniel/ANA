/**
 * @author Daniel Reto
 * @description COMM_SL_GenerateResellerOrderVoucher Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      30/10/2024    100           Original version - ECOMM-327
 **/
@isTest
private class COMM_SL_GenerateResellerOrderVoucherTest {
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();

    @testSetup
    static void setup() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void testGenerateOrderVoucherOnFlow() {
        OrderSummary orderSummaryRecord = [SELECT Id, OriginalOrderId, AccountId FROM OrderSummary LIMIT 1][0];
        Account accountRecord = new Account(
            Id = orderSummaryRecord.AccountId,
            COMM_ResellerId__c = '1234'
        );
        Boolean errorOccured = false;

        COMM_SL_GenerateResellerOrderVoucher.InputWrapper testWrapper = new COMM_SL_GenerateResellerOrderVoucher.InputWrapper();
        testWrapper.orderId = orderSummaryRecord.OriginalOrderId;
        testWrapper.orderSummaryId = orderSummaryRecord.Id;
        testWrapper.resellerId = '1234';

        
        try {
            Test.startTest();
            COMM_SL_GenerateResellerOrderVoucher.generateOrderVoucherOnFlow(new List<COMM_SL_GenerateResellerOrderVoucher.InputWrapper>{ testWrapper });
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        Assert.isFalse(errorOccured, 'No error expected');
    }
}