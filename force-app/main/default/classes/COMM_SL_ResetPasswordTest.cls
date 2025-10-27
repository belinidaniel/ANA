/**
 * @author Daniel Lascas
 * @description COMM_SL_ResetPassword test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/03/2024      100            Original version
 **/
@isTest
private class COMM_SL_ResetPasswordTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_IREP_OrgWideEmailAddress OWEA_REP = (COMM_REP_OrgWideEmailAddress) MOCKS.mock(COMM_REP_OrgWideEmailAddress.class);
    private final static COMM_ISL_Email GET_TEMPLATE_SL = (COMM_SL_Email) MOCKS.mock(COMM_SL_Email.class);

    @TestSetup
    static void makeData() {
        //Create Test User (for tests that call system methods like Set Password)
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];

        Long usernameSuffix = DateTime.now().getTime();
        String testUsername = 'testuser' + usernameSuffix;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => testUsername,
                'Alias' => 'testUser',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id
            }
        );

        //Generate Test Encryption Key
        COMM_EmailTemplatesEncryptionSettings__c setting = new COMM_EmailTemplatesEncryptionSettings__c();
        setting.Name = 'Encrypt key test';
        setting.COMM_UserKey__c = '9wp6gqhzz8u07wpw';
        insert setting;
    }

    @isTest
    static void handleValidateResetTokenSuccessTest() {
        //Scenario: User enters Forgot Password Page with a Token to enable Password Setup.
        //Expected: Token is valid so User Id is returned

        COMM_SL_ResetPassword.TokenWrapper token = new COMM_SL_ResetPassword.TokenWrapper();
        token.userId = fflib_IDGenerator.generate(User.SOBjectType);
        token.requestDate = Datetime.now().addDays(1);
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME);

        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => token.userId,
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_IsPasswordReseted__c' => true,
                'COMM_ResetPasswordEmailExpirationDate__c' => token.requestDate
            }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(userList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
        worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
        User result = worker.handleValidateResetToken(encryptedToken);
        Test.stopTest();

        Assert.areEqual(token.userId, result.Id, 'result does not match expected');
    }

    @isTest
    static void handleValidateResetTokenFailureTest() {
        //Scenario: User enters Forgot Password Page with a Token to enable Password Setup. User's Link has expired.
        //Expected: A null value is returned

        COMM_SL_ResetPassword.TokenWrapper token = new COMM_SL_ResetPassword.TokenWrapper();
        token.userId = fflib_IDGenerator.generate(User.SOBjectType);
        token.requestDate = Datetime.now().addDays(-1);
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME);

        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => token.userId,
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_IsPasswordReseted__c' => true,
                'COMM_ResetPasswordEmailExpirationDate__c' => token.requestDate
            }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(userList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
        worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
        User result = worker.handleValidateResetToken(encryptedToken);
        Test.stopTest();

        Assert.isNull(result, 'expected returned user to be null');
    }

    @isTest
    static void handleChangePasswordSuccessTest() {
        //Scenario: User enters a new Password
        //Expected: Password is changed and an Email is Sent

        //Retrieve User Record and a Email Test to simulate the real email
        User userRecord = [SELECT Id, LanguageLocaleKey FROM User WHERE Name = 'Test User' LIMIT 1];
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Assert.isFalse(templateList.isEmpty(), 'no templates for testing exist');

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserWithLaguageFieldById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ userRecord });
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(templateList);
        MOCKS.when(OWEA_REP.getDefaultNoReplyAddress()).thenReturn(new List<OrgWideEmailAddress>());
        MOCKS.stopStubbing();

        Test.startTest();
        Integer emailInvocationStart = Limits.getEmailInvocations();
        COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
        worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
        worker.handleChangePassword(userRecord.Id, 'testeR76!a');
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(emailSent, 'no email was sent');
    }

    @isTest
    static void handleChangePasswordFailureTest() {
        //Scenario: User enters a new Password but is the same as his current one
        //Expected: Error is thrown due to repeated Password

        //Retrieve User Record and a Email Test to simulate the real email
        User userRecord = [SELECT Id, LanguageLocaleKey FROM User WHERE Name = 'Test User' LIMIT 1];
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Assert.isFalse(templateList.isEmpty(), 'no templates for testing exist');

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserWithLaguageFieldById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ userRecord });
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(templateList);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            //Set Password before executing class method
            System.setPassword(userRecord.Id, 'testeR76!a');
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.handleChangePassword(userRecord.Id, 'testeR76!a');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected error to occur');
    }

    @isTest
    static void handleChangePasswordFailureNoUserTest() {
        //Scenario: User enters a new Password but fails to verify Language
        //Expected: Error is thrown

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserWithLaguageFieldById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.handleChangePassword(fflib_IDGenerator.generate(User.sObjectType), 'testeR76!a');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected error to occur');
    }

    @isTest
    static void handleValidateForgotPasswordSuccessTest() {
        //Scenario: User enters the Forgot Password Site and inputs his email.
        //Expected: Password is Reset and Email is Sent

        //Retrieve User Record and a Email Test to simulate the real email
        List<User> userList = [
            SELECT
                Id,
                Email,
                LanguageLocaleKey,
                COMM_LoginType__c,
                COMM_ResetPasswordEmailExpirationDate__c,
                COMM_PasswordRetrievalCount__c,
                COMM_LastPasswordRetrievalTime__c
            FROM User
            WHERE Name = 'Test User'
            LIMIT 1
        ];
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Assert.isFalse(templateList.isEmpty(), 'no templates for testing exist');

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    fflib_Match.anyBoolean()
                )
            )
            .thenReturn(userList);
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(userList);
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(templateList);
        MOCKS.when(OWEA_REP.getDefaultNoReplyAddress()).thenReturn(new List<OrgWideEmailAddress>());
        MOCKS.stopStubbing();

        Test.startTest();
        Integer emailInvocationStart = Limits.getEmailInvocations();
        COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
        worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
        worker.resetPassword(userList[0].Email, 'https://testcommunity.invalid', 'Customers_Portal1', 'ana.pt');
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(emailSent, 'no email was sent');
    }

    @isTest
    static void handleValidateForgotPasswordFailureSettingValidationTest() {
        //Scenario: User enters the Forgot Password Site and inputs his email. An error occurs during validation setup.
        //Expected: Exception is throwed.

        //Retrieve User Record and a Email Test to simulate the real email
        List<User> userList = [SELECT Id, Email, LanguageLocaleKey FROM User WHERE Name = 'Test User' LIMIT 1];
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Assert.isFalse(templateList.isEmpty(), 'no templates for testing exist');

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    fflib_Match.anyBoolean()
                )
            )
            .thenReturn(userList);
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(templateList);
        MOCKS.when(OWEA_REP.getDefaultNoReplyAddress()).thenReturn(new List<OrgWideEmailAddress>());

        //Throws an Exception when method is called (to test failure)
        MOCKS.startStubbing();
        ((COMM_IREP_User) MOCKS.doThrowWhen(new List<Exception>{ new AuraException() }, USER_REP)).updateSObjects((List<User>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        Integer emailInvocationStart = Limits.getEmailInvocations();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetPassword(userList[0].Email, 'https://testcommunity.invalid', 'Customers_Portal1', null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
        Assert.isFalse(emailSent, 'an email was sent when it shouldn\'t');
    }

    @isTest
    static void handleValidateForgotPasswordNoUserFailureTest() {
        //Scenario: User enters the Forgot Password Site and inputs the wrong email.
        //Expected: Error is thrown due to no User with Email existing

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    fflib_Match.anyBoolean()
                )
            )
            .thenReturn(new List<User>());
        MOCKS.stopStubbing();

        String errorMessage = '';

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetPassword('nouser@test.invalid', 'https://testcommunity.invalid', 'Customers_Portal1', null);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(
            System.Label.COMM_FORGOT_PASSWORD_RESET_FAILED,
            errorMessage,
            'expected custom error message that a problem reseting password occured'
        );
    }

    @isTest
    static void resetPasswordUserNoResetTest() {
        //Scenario: User resets password but his login doesn't allow it (ex: Google Login)
        //Expected: Exception is throwed and a Error Log Record is generated

        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER
            }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    fflib_Match.anyBoolean()
                )
            )
            .thenReturn(userList);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetPassword(userList[0].Email, 'https://testcommunity.invalid', 'Customers_Portal1', null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];
        Assert.areEqual(1, errorList.size(), 'expected an error log to have been generated');
        Assert.isTrue(errorOccured, 'expected an error to happen');
    }

    @isTest
    static void resetPasswordUserFailTest() {
        //Scenario: User resets password but an unexpected error occurs
        //Expected: Exception is throwed and a Error Log Record is generated

        COMM_PortalValidationSetting__mdt portalSetting = COMM_DO_PortalValidationSetting.getPortalSetting('Customers_Portal1', 'ResetPassword');

        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
                'COMM_ResetPasswordEmailExpirationDate__c' => System.now().addHours(Integer.valueOf(portalSetting.COMM_ExpirationTimeHours__c)),
                'COMM_PasswordRetrievalCount__c' => 0,
                'COMM_LastPasswordRetrievalTime__c' => System.now().addMinutes(Integer.valueOf(portalSetting.COMM_PasswordRetrievalWindow__c))
            }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(userList);
        ((COMM_REP_User) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, USER_REP))
            .updateSObjects((List<User>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetUserPassword(
                fflib_IDGenerator.generate(User.SObjectType),
                UserInfo.getLanguage(),
                'https://testcommunity.invalid',
                'Customers_Portal1',
                null,
                false
            );
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];
        Assert.areEqual(1, errorList.size(), 'expected an error log to have been generated');
        Assert.isTrue(errorOccured, 'expected an error to happen');
    }

    @isTest
    static void resetPasswordUserFailDueToLimitTest() {
        //Scenario: User resets password but has reached daily limit
        //Expected: Exception is throwed and a Error Log Record is generated

        COMM_PortalValidationSetting__mdt portalSetting = COMM_DO_PortalValidationSetting.getPortalSetting('Customers_Portal1', 'ResetPassword');

        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
                'COMM_ResetPasswordEmailExpirationDate__c' => System.now().addHours(Integer.valueOf(portalSetting.COMM_ExpirationTimeHours__c)),
                'COMM_PasswordRetrievalCount__c' => portalSetting.COMM_MaxPasswordRetrievals__c,
                'COMM_LastPasswordRetrievalTime__c' => System.now().addMinutes(Integer.valueOf(portalSetting.COMM_PasswordRetrievalWindow__c))
            }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(userList);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetUserPassword(
                fflib_IDGenerator.generate(User.SObjectType),
                UserInfo.getLanguage(),
                'https://testcommunity.invalid',
                'Customers_Portal1',
                null,
                false
            );
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to happen');
    }

    @isTest
    static void resetPasswordUserFailDueToNotExistTest() {
        //Scenario: User resets password but record isnt' returned in query
        //Expected: Exception is throwed and a Error Log Record is generated

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ResetPassword worker = new COMM_SL_ResetPassword();
            worker = new COMM_SL_ResetPassword(USER_REP, OWEA_REP, GET_TEMPLATE_SL);
            worker.resetUserPassword(
                fflib_IDGenerator.generate(User.SObjectType),
                UserInfo.getLanguage(),
                'https://testcommunity.invalid',
                'Customers_Portal1',
                null,
                false
            );
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to happen');
    }
}