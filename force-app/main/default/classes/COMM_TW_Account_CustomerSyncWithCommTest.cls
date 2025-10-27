/**
 * @author Daniel Lascas
 * @description COMM_TW_Account_CustomerSyncWithCommerce test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    17/06/2024      100            Original version
 **/
@isTest
private class COMM_TW_Account_CustomerSyncWithCommTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IDO_CustomerSyncMapping CUSTOMER_SYNC_MAPPING_DO = (COMM_DO_CustomerSyncMapping) MOCKS.mock(
        COMM_DO_CustomerSyncMapping.class
    );

    @isTest
    static void syncTest() {
        //Scenario: One of the mapped fields in Account is updated
        //Expected: Integration Map is generated and queueable is launched

        //Generate mocked Account
        Account oldAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.sObjectType), 'COMM_IndividualStaff__c' => false }
        )[0];
        oldAccount = (Account) COMM_TestDataFactory.setField(oldAccount, new Map<String, Object>{ 'IsPersonAccount' => true });

        Account newAccount = oldAccount.clone(true);
        newAccount.COMM_IndividualStaff__c = true;

        List<Account> newAccountList = new List<Account>{ newAccount };
        Map<Id, Account> oldAccountMap = new Map<Id, Account>{ oldAccount.Id => oldAccount };

        //Mock DO Calls
        MOCKS.startStubbing();
        MOCKS.when(CUSTOMER_SYNC_MAPPING_DO.getCoreFieldList(fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(new Set<String>{ 'COMM_IndividualStaff__c' });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Account_CustomerSyncWithCommerce worker = new COMM_TW_Account_CustomerSyncWithCommerce();
        worker = new COMM_TW_Account_CustomerSyncWithCommerce(CUSTOMER_SYNC_MAPPING_DO);
        worker.execute(newAccountList, oldAccountMap);
        Integer dmlExecuted = Limits.getDMLStatements();
        Test.stopTest();

        Assert.areEqual(1, dmlExecuted, 'expected one Platform Event to be published');
    }
}