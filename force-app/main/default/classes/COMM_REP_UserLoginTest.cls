/**
 * @author Miguel Freire
 * @description COMM_REP_UserLogin test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire   	15/04/2024      -              Original version
 **/
@isTest
private class COMM_REP_UserLoginTest {
    private final static COMM_REP_UserLogin USER_LOGIN_REP = new COMM_REP_UserLogin();

    @TestSetup
    static void makeData() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];

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
                'FederationIdentifier' => USERNAME + '@test.com.invalid',
                'COMM_LoginType__c' => COMM_DO_User.AZURE_SSO_IDENTIFIER,
                'CommunityNickname' => USERNAME,
                'Alias' => USERNAME.right(8),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id
            }
        );
    }

    @isTest
    static void getUserLoginsByUserIdTest() {
        //Expected: Retrieved a User.
        List<User> userList = [
            SELECT Id
            FROM User
            ORDER BY CreatedDate DESC NULLS LAST
            LIMIT 1
        ];

        Test.startTest();
        List<UserLogin> actualList = USER_LOGIN_REP.getUserLoginsByUserId(new Set<Id>{ userList[0].Id });
        Test.stopTest();

        Assert.areEqual(userList[0].Id, actualList[0].UserId, 'The UserLogin found does not match expected');
    }
}