/**
 * @author           Daniel Lascas
 * @description      COMM_DO_AccountManagementMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/03/2024      100            ECOMM-142 - Original version
 **/
@isTest
private class COMM_DO_AccountManagementMappingTest {
    private final static COMM_DO_AccountManagementMapping MAPPING_DO = new COMM_DO_AccountManagementMapping();

    @isTest
    static void mapJsonFromSObjectTest() {
        Account accountData = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.SObjectType), 'Name' => 'Test Account' }
        )[0];

        Map<String, Object> testMap = new Map<String, Object>();

        Test.startTest();
        MAPPING_DO.mapJsonFromSObject(accountData, testMap, false);
        Test.stopTest();

        Assert.isFalse(testMap.isEmpty(), 'expected mapping to occur');
        Assert.areEqual(accountData.Id, testMap.get('accountId'), 'mapped Id does not match expected');
        Assert.areEqual(accountData.Name, testMap.get('companyName'), 'mapped Name does not match expected');
    }

    @isTest
    static void mapSObjectFromJsonTest() {
        Account accountData = new Account();

        Map<String, Object> testMap = new Map<String, Object>{
            'accountId' => fflib_IDGenerator.generate(Account.SObjectType),
            'companyName' => 'Test Account'
        };

        Test.startTest();
        MAPPING_DO.mapSObjectFromJson(testMap, accountData, false);
        Test.stopTest();

        Assert.areEqual(testMap.get('accountId'), accountData.Id, 'mapped Id does not match expected');
        Assert.areEqual(testMap.get('companyName'), accountData.Name, 'mapped Name does not match expected');
    }
}