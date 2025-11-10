/**
 * @author Miguel Justo
 * @description COMM_SL_User test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo   05/03/2024          100            Original version
 **/
@isTest
private class COMM_SL_UserTest {
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
                'LastName' => USERNAME,
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
    static void testgetEffectiveAccountIdSucess() {
        // Test data setup
        List<User> usersList = [SELECT Id, COMM_EffectiveAccountId__c FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];

        // Call the method
        Test.startTest();
        String userEffectiveAccountID = COMM_SL_User.getEffectiveAccountId(UsersList[0].Id);
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
            COMM_SL_User.getEffectiveAccountId(userId);
        } catch (Exception e) {
            error = true;
        }
        Test.stopTest();
        // Assertions
        // Ids are not the same and error occurred.
        Assert.isTrue(error, 'expected an error to occur');
    }
}