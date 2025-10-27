/**
 * @author           Miguel Freire
 * @description      COMM_SL_RegistrationEmailExpiration Test Class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)        Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    22/03/2024        89              Original version
 **/
@isTest
private class COMM_SL_RegistrationEmailExpirationTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_REP_UserLogin USER_LOGIN_REP = (COMM_REP_UserLogin) MOCKS.mock(COMM_REP_UserLogin.class);

    @isTest
    static void interfaceTest() {
        //Scenario: This is just for coverage.
        //The interface methods are static and cannot be tested using the mock framework.
        //The actual testing is done below using the mock framework.
        Boolean errorOccured = false;
        try {
            COMM_SL_RegistrationEmailExpiration.validateEmailExpiration(null);
        } catch (Exception e) {
            errorOccured = true;
        }
    }

    @isTest
    static void testExceptionWhenUserDoesntExist() {
        //Scenario: A user tries to validate is email but no user was found
        //Expected: Exception is trown
        //Mock expected User Record
        COMM_IREP_Profile profileRep = new COMM_REP_PROFILE();
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser2@ana.pt.test',
                'Email' => 'test2@email.com',
                'LastName' => 'Test2',
                'FirstName' => 'User2',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => (profileRep.getProfilesByName(new Set<String>{ 'Standard User' }, false)[0]).Id
            }
        )[0];
        String encodedUserId = COMM_GEN_Utility.convertToBase64(userRecord.Id);
        String stringValue = 'https://test?dXNlcklk=' + encodedUserId;
        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersByIdEmailValidation((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>());
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_SL_RegistrationEmailExpiration worker = new COMM_SL_RegistrationEmailExpiration();
            worker = new COMM_SL_RegistrationEmailExpiration(USER_REP, USER_LOGIN_REP);
            worker.handlerValidateEmailExpiration(stringValue);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        Assert.isTrue(errorOccured, 'error trown because user was not found');
    }

    @isTest
    static void testSuccessfullValidation() {
        //Scenario: A user validates his email successfully
        //Expected: Successful validation

        //Mock expected User Record
        COMM_IREP_Profile profileRep = new COMM_REP_PROFILE();
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser2@ana.pt.test',
                'Email' => 'test2@email.com',
                'LastName' => 'Test2',
                'FirstName' => 'User2',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => (profileRep.getProfilesByName(new Set<String>{ 'Standard User' }, false)[0]).Id
            }
        )[0];
        UserLogin userLoginRecord = [SELECT id FROM UserLogin WHERE UserId = :userRecord.Id LIMIT 1];
        String encodedUserId = COMM_GEN_Utility.convertToBase64(userRecord.Id);
        String stringValue = 'https://test?dXNlcklk=' + encodedUserId;
        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersByIdEmailValidation((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ userRecord });
        MOCKS.when(USER_LOGIN_REP.getUserLoginsByUserId((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<UserLogin>{ userLoginRecord });
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_SL_RegistrationEmailExpiration worker = new COMM_SL_RegistrationEmailExpiration();
            worker = new COMM_SL_RegistrationEmailExpiration(USER_REP, USER_LOGIN_REP);
            worker.handlerValidateEmailExpiration(stringValue);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        Assert.isFalse(errorOccured, 'Successful Validation');
    }
}