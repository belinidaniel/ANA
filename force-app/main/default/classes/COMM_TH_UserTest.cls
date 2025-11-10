/**
 * @author Daniel Lascas
 * @description COMM_TH_User test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024       100            ECOMM-700: Original version
 **/
@isTest
private class COMM_TH_UserTest {
    @isTest
    static void insertTest() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];
        
        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;
        
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'CommunityNickname' => USERNAME,
                'Alias' => 'testUser',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        )[0];

        Test.startTest();
        insert userRecord;
        Test.stopTest();

        Assert.isNotNull(userRecord.Id, 'user record was not inserted');
    }

    @isTest
    static void updateTest() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];
        
        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;
        
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
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
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        )[0];

        Test.startTest();
        userRecord.FirstName = 'updateName';
        update userRecord;
        Test.stopTest();

        User actualUser = [SELECT FirstName FROM User WHERE Id = :userRecord.Id];

        Assert.areEqual(userRecord.FirstName, actualUser.FirstName, 'user record was not updated');
    }
}