/**
 * @author Miguel Justo
 * @description COMM_REP_User test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo     27/02/2024      -              Original version
 * Daniel Lascas    28/02/2024      58             Added getUserByEmailAndLoginTypeTest and getUsersByIdTest
 * Daniel Lascas    12/03/2024      50             Added test getUserAccountAndContactDataByIdTest
 * Daniel Lascas    26/03/2024      74             Added test getAzureUsersByEmailTest
 * Miguel Freire    23/03/2024      76             Added test getUsersByIdEmailValidation and created inactive User
 * Miguel Freire    19/07/2024      76             Added test getActiveNonPartnerUserByEmailTest
 **/
@isTest
private class COMM_REP_UserTest {
    private final static COMM_REP_User USER_REP = new COMM_REP_User();

    @TestSetup
    static void makeData() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];

        Long suffix = DateTime.now().getTime();
        String nickname = 'testuser' + suffix;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'FederationIdentifier' => 'test@test.com.invalid',
                'COMM_LoginType__c' => COMM_DO_User.AZURE_SSO_IDENTIFIER,
                'CommunityNickname' => nickname,
                'Alias' => 'testUser',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testinactiveuser@ana.pt.test',
                'Email' => 'testinactiveuser@test.com.invalid',
                'LastName' => 'Inactive User',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => nickname + 'INACTIVE',
                'Alias' => 'testInac',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id,
                'IsActive' => false
            }
        );
    }

    @isTest
    static void getUserTest() {
        //Expected: Retrieved a User.
        List<User> expectedList = [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<User> actualList = USER_REP.getUser(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'The User found does not match expected');
    }

    @isTest
    static void getUsersByIdTest() {
        List<User> expectedList = [SELECT Id FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        List<User> actualList = USER_REP.getUsersById(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'user record does not match expected');
    }

    @isTest
    static void getUserWithLanguageFieldByIdTest() {
        List<User> expectedList = [SELECT Id FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        List<User> actualListWithoutSecurity = USER_REP.getUserWithLaguageFieldById(new Set<Id>{ expectedList[0].Id }, false);
        List<User> actualListWithSecurity = USER_REP.getUserWithLaguageFieldById(new Set<Id>{ expectedList[0].Id }, true);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualListWithoutSecurity[0].Id, 'user record does not match expected in without security query');
        Assert.areEqual(expectedList[0].Id, actualListWithSecurity[0].Id, 'user record does not match expected in with security query');
    }

    @isTest
    static void getUsersWithEmailChangeValidationByIdTest() {
        List<User> expectedList = [SELECT Id FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        List<User> actualList = USER_REP.getUsersWithEmailChangeValidationById(new Set<Id>{ expectedList[0].Id }, true);
        List<User> actualListWithoutSecurity = USER_REP.getUsersWithEmailChangeValidationById(new Set<Id>{ expectedList[0].Id }, true);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'user record does not match expected');
        Assert.areEqual(expectedList[0].Id, actualListWithoutSecurity[0].Id, 'user record without security does not match expected');
    }

    @isTest
    static void getUserByEmailAndLoginTypeTest() {
        //Scenario: One User Exists
        //Expected: Retrieved the existing User by it's Email and Login Type
        List<User> expectedList = [SELECT Id, Email, COMM_LoginType__c FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        List<User> actualList = USER_REP.getUserByEmailAndLoginType(
            new Set<String>{ expectedList[0].Email },
            new Set<String>{ expectedList[0].COMM_LoginType__c },
            false
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'user record does not match expected');
    }

    @isTest
    static void getUserAccountAndContactDataByIdTest() {
        //Expected: Retrieved a User.
        List<User> expectedList = [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<User> actualList = USER_REP.getUserAccountAndContactDataById(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'The User found does not match expected');
    }

    @isTest
    static void getAzureUsersByEmailTest() {
        //Expected: Retrieved a Azure User.
        List<User> expectedList = [
            SELECT Id, Email
            FROM User
            WHERE IsActive = TRUE AND Name = 'Test User'
            LIMIT 1
        ];

        Test.startTest();
        List<User> actualList = USER_REP.getAzureUsersByEmail(new Set<String>{ expectedList[0].Email }, false);
        List<User> actualListWithSecurity = USER_REP.getAzureUsersByEmail(new Set<String>{ expectedList[0].Email }, true);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'The User found does not match expected');
        Assert.areEqual(expectedList[0].Id, actualListWithSecurity[0].Id, 'The User found does not match expected');
    }

    @isTest
    static void getUsersByIdEmailValidationTest() {
        List<User> expectedList = [SELECT Id FROM User WHERE Name = 'Test Inactive User' LIMIT 1];

        Test.startTest();
        List<User> actualList = USER_REP.getUsersByIdEmailValidation(new Set<Id>{ expectedList[0].Id }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'user record does not match expected');
    }
    @isTest
    static void getUserByInValidationExpiredEmailTest() {
        List<User> expectedList = [SELECT Id, Email, COMM_LoginType__c FROM User WHERE Name = 'Test Inactive User'];

        Test.startTest();
        Boolean errorOccured = false;
        try {
            List<User> actualList = USER_REP.getUserByInValidationExpiredEmail(true);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'User Obfuscated and Account deleted');
    }

    @isTest
    static void getUsersValidationByIdTest() {
        List<User> expectedList = [SELECT Id FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        List<User> actualList = USER_REP.getUserValidationById(new Set<Id>{ expectedList[0].Id }, true);
        List<User> actualNoSecurityList = USER_REP.getUserValidationById(new Set<Id>{ expectedList[0].Id }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'user record does not match expected');
        Assert.areEqual(expectedList[0].Id, actualNoSecurityList[0].Id, 'user record without security does not match expected');
    }

    @isTest
    static void getActivePortalUserByEmail() {
        List<User> expectedList = [SELECT Id, Email FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        User actualList = USER_REP.getActiveNonPartnerUserByEmail(expectedList[0].Email, false);
        User actualNoSecurityList = USER_REP.getActiveNonPartnerUserByEmail(expectedList[0].Email, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList.Id, 'user record does not match expected');
        Assert.areEqual(expectedList[0].Id, actualNoSecurityList.Id, 'user record without security does not match expected');
    }

    @isTest
    static void getActiveNonPartnerUserByEmailTest() {
        List<User> expectedList = [SELECT Id, Email FROM User WHERE Name = 'Test User' LIMIT 1];

        Test.startTest();
        User actualList = USER_REP.getActiveNonPartnerUserByEmail(expectedList[0].Email, false);
        User actualNoSecurityList = USER_REP.getActiveNonPartnerUserByEmail(expectedList[0].Email, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList.Id, 'user record does not match expected');
        Assert.areEqual(expectedList[0].Id, actualNoSecurityList.Id, 'user record without security does not match expected');
    }
}