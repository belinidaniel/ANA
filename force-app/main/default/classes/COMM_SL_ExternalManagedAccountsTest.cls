/**
 * @author Miguel Justo
 * @description COMM_SL_ExternalManagedAccounts test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo   27/02/2024          92            Original version
 **/
@isTest
private class COMM_SL_ExternalManagedAccountsTest {
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
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'CommunityNickname' => USERNAME,
                'Alias' => 'testUser',
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        );
        List<Profile> profileMinAcess = [SELECT Id FROM Profile WHERE Name = 'Identity User'];
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt',
                'Email' => 'test@test.com',
                'LastName' => 'Usermin',
                'FirstName' => 'Testmin',
                'CommunityNickname' => 'testusermin',
                'Alias' => 'testmin',
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileMinAcess[0].Id
            }
        );
    }

    @isTest
    private static void handleExternalManagedAccountsTest() {
        String communityId;
        List<Network> networkList = [SELECT Id FROM Network];
        if (networkList.size() > 0) {
            communityId = networkList[0].Id;
        }

        // Portal user
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];

        // Run system as User
        System.runAs(userRecord) {
            Test.startTest();
            try {
                List<ConnectApi.ExternalManagedAccountOutput> managedAccounts = COMM_SL_ExternalManagedAccounts.handleExternalManagedAccounts(
                    communityId
                );
                Assert.areEqual(null, managedAccounts, 'expected Account is not null');
            } catch (Exception e) {
                Assert.areEqual('System.UnsupportedOperationException', e.getTypeName(), 'Expected UnsupportedOperationException Exception');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testHandleSwitchAccount() {
        // Test data setup
        String accountid = fflib_idgenerator.generate(Account.SObjectType);
        List<User> usersList = [SELECT Id FROM User WHERE Username = 'testuser@ana.pt.test' LIMIT 1];
        // Call the method
        Test.startTest();
        COMM_SL_ExternalManagedAccounts.handleSwitchAccount(accountid, usersList[0].Id);
        Test.stopTest();
        // Assertions
        // Checking if the user's effective account ID was updated
        User user = [SELECT Id, COMM_EffectiveAccountId__c FROM User WHERE Id = :usersList[0].Id LIMIT 1];
        Assert.areEqual(accountid, user.COMM_EffectiveAccountId__c, 'Not Updated');
    }
}