/**
 * @author Diogo Gonçalves
 * @description COMM_REP_CreditMemo test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  08/05/2024      100             Original version
 * Daniel Reto      18/06/2024      100             New test method
 **/
@isTest
private class COMM_REP_CreditMemoTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void getByIdsTest() {
        List<CreditMemo> creditMemos = [SELECT Id FROM CreditMemo WITH USER_MODE];
        List<String> creditMemoIds = new List<String>();
        for (CreditMemo cm : creditMemos) {
            creditMemoIds.add(cm.Id);
        }

        Test.startTest();
        COMM_REP_CreditMemo creditMemoRep = new COMM_REP_CreditMemo();
        List<CreditMemo> result = creditMemoRep.getByIds(creditMemoIds);
        Test.stopTest();

        Assert.areEqual(creditMemos.size(), result.size(), 'The returned result should have the same number of records as the input.');
    }

    @isTest
    static void getForSAPCreditMemoTest() {
        List<CreditMemo> creditMemos = [SELECT Id FROM CreditMemo WITH USER_MODE];
        List<String> creditMemoIds = new List<String>();
        for (CreditMemo cm : creditMemos) {
            creditMemoIds.add(cm.Id);
        }

        Test.startTest();
        COMM_REP_CreditMemo creditMemoRep = new COMM_REP_CreditMemo();
        List<CreditMemo> result = creditMemoRep.getForSAPCreditMemo(creditMemoIds);
        Test.stopTest();

        Assert.areEqual(creditMemos.size(), result.size(), 'The returned result should have the same number of records as the input.');
    }

    @isTest
    static void getForSAPCreditMemoWithTwoArgTest() {
        List<CreditMemo> creditMemos = [SELECT Id FROM CreditMemo WITH USER_MODE];
        Set<Id> creditMemoIds = new Set<Id>();
        for (CreditMemo cm : creditMemos) {
            creditMemoIds.add(cm.Id);
        }

        Test.startTest();
        COMM_REP_CreditMemo creditMemoRep = new COMM_REP_CreditMemo();
        List<CreditMemo> result = creditMemoRep.getForSAPCreditMemo(creditMemoIds, 'CreatedDate = N_MONTHS_AGO:0');
        Test.stopTest();

        Assert.areEqual(creditMemos.size(), result.size(), 'The returned result should have the same number of records as the input.');
    }
}