/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Account_AirportUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      100            ECOMM-1602: Original version
 **/
@isTest
private class COMM_TW_Account_AirportUpdateTest {
    @isTest
    static void updateFieldTest() {
        //Scenario:	Account's Airport was Updated.
        //Expected: Airport Text Field is updated

        //Generate mocked Account
        Account oldAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Account.sObjectType), 'COMM_Airport__c' => 'LIS' }
        )[0];

        //Mocked Update where Airport is changed
        Account newAccount = oldAccount.clone(true);
        newAccount.COMM_Airport__c = 'LIS;OPO';

        Map<Id, Account> oldAccountMap = new Map<Id, Account>{ oldAccount.Id => oldAccount };
        List<Account> newAccountList = new List<Account>{ newAccount };

        Test.startTest();
        COMM_TW_Account_AirportUpdate worker = new COMM_TW_Account_AirportUpdate();
        worker.execute(newAccountList, oldAccountMap);
        Test.stopTest();

        Assert.areEqual(
            newAccount.COMM_Airport__c,
            newAccount.COMM_AirportTextList__c,
            'expected text airport field to be updated with multi-picklist airport fields value'
        );
    }
}