/**
 * @author Miguel Justo
 * @description COMM_LCC_ExternalManagedAccount test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo    04/03/2024      75            Original version
 **/
@isTest
private class COMM_LCC_ExternalManagedAccountTest {
    @TestSetup
    static void makeData() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => USERNAME + '@ana.pt.test',
                'Email' => USERNAME + '@test.com.invalid',
                'LastName' => 'User ' + SUFFIX,
                'FirstName' => 'Test',
                'CommunityNickname' => USERNAME,
                'Alias' => USERNAME.right(8),
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        );
    }

    @isTest
    static void testWrapperConstructor() {
        // Create a new instance of the ExternalManagedAccountOutput
        ConnectApi.ExternalManagedAccountOutput managedAccount = new ConnectApi.ExternalManagedAccountOutput();
        managedAccount.accountId = fflib_idgenerator.generate(Account.SObjectType);
        managedAccount.accountName = 'TestAccountName';

        // Create a new instance of the wrapper class using the constructor
        COMM_LCC_ExternalManagedAccount.ExternalManagedAccountWrapper wrapper = new COMM_LCC_ExternalManagedAccount.ExternalManagedAccountWrapper(
            managedAccount
        );

        // Verify that the wrapper object is not null
        Assert.isNotNull(wrapper, 'Is Null');

        // Verify that the accountId and accountName properties are set correctly
        Assert.areEqual(managedAccount.accountId, wrapper.accountId, 'The AccountId are not the same');
        Assert.areEqual(managedAccount.accountName, wrapper.accountName, 'The Account Name are not the Same');
    }

    @isTest
    private static void getExternalManagedAccountsTest() {
        String communityId;
        List<Network> networkList = [SELECT Id FROM Network];
        if (networkList.size() > 0) {
            communityId = networkList[0].Id;
        }

        // Portal user
        User userRecord = [SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];

        // Run system as User
        System.runAs(userRecord) {
            Test.startTest();
            try {
                List<COMM_LCC_ExternalManagedAccount.ExternalManagedAccountWrapper> managedAccounts = COMM_LCC_ExternalManagedAccount.getExternalManagedAccounts(
                    communityId
                );
                Assert.areEqual(null, managedAccounts, 'expected Account is not null');
            } catch (Exception e) {
                Assert.areEqual('System.AuraHandledException', e.getTypeName(), 'Expected UnsupportedOperationException Exception');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSwitchAccount() {
        // Test data setup
        String accountid = fflib_idgenerator.generate(Account.SObjectType);
        List<User> usersList = [SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];
        // Call the method
        Test.startTest();
        COMM_LCC_ExternalManagedAccount.switchAccount(accountid, usersList[0].Id);
        Test.stopTest();
        // Assertions
        // Checking if the user's effective account ID was updated
        User user = [SELECT Id, COMM_EffectiveAccountId__c FROM User WHERE Id = :usersList[0].Id LIMIT 1];
        Assert.areEqual(accountid, user.COMM_EffectiveAccountId__c, 'Not Updated');
    }

    @isTest
    static void testgetEffectiveAccountIdSucess() {
        // Test data setup
        List<User> usersList = [SELECT Id, COMM_EffectiveAccountId__c FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];

        // Call the method
        Test.startTest();
        String userEffectiveAccountID = COMM_LCC_ExternalManagedAccount.getEffectiveAccountId(UsersList[0].Id);
        Test.stopTest();
        // Assertions
        // Checking if the user's effective is the same.
        Assert.areEqual(usersList[0].COMM_EffectiveAccountId__c, userEffectiveAccountID, 'The Effective Account IDs are not the Same');
    }

    @isTest
    static void testgetEffectiveAccountIdFailure() {
        // Test data setup
        String userId = fflib_idgenerator.generate(User.SObjectType);
        Boolean error = false;
        // Call the method
        Test.startTest();
        try {
            COMM_LCC_ExternalManagedAccount.getEffectiveAccountId(userId);
        } catch (Exception e) {
            error = true;
        }
        Test.stopTest();
        // Assertions
        // Ids are not the same and error occurred.
        Assert.isTrue(error, 'expected an error to occur');
    }
}