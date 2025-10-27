/**
 * @author Daniel Lascas
 * @description COMM_SL_ChangeEmail test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/03/2024      94             ECOMM-343: Original version
 * Daniel Lascas    26/06/2024      100            ECOMM-1495: Refactor tests
 **/
@isTest
private class COMM_SL_ChangeEmailTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_ISL_Email GET_TEMPLATE_SL = (COMM_SL_Email) MOCKS.mock(COMM_SL_Email.class);
    private final static COMM_SL_ChangeEmailHelper HELPER_SL = (COMM_SL_ChangeEmailHelper) MOCKS.mock(COMM_SL_ChangeEmailHelper.class);

    @TestSetup
    static void makeData() {
        //Generate Test Encryption Key.
        COMM_EmailTemplatesEncryptionSettings__c setting = new COMM_EmailTemplatesEncryptionSettings__c();
        setting.Name = 'Encrypt key test';
        setting.COMM_UserKey__c = '9wp6gqhzz8u07wpw';
        insert setting;
    }

    @isTest
    static void changeUserEmailTest() {
        //Scenario: User initiates the Change Email process
        //Expected: User Record is updated with validation data, Emails are generated and sent

        //Create Mocked Records
        User userRecord = new User();
        userRecord.Id = UserInfo.getUserId();
        userRecord.LanguageLocaleKey = 'pt_BR';

        EmailTemplate templateForNewEmail = new EmailTemplate();
        templateForNewEmail.Name = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.DeveloperName = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        EmailTemplate templateForOldEmail = new EmailTemplate();
        templateForOldEmail.Name = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.DeveloperName = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        OrgWideEmailAddress orgAddress = new OrgWideEmailAddress();
        orgAddress.Address = 'no-reply@ana.pt.invalid';

        String newEmail = 'newemail@test.com.invalid';

        Map<Schema.SObjectField, Object> toMatchMap = new Map<Schema.SObjectField, Object>{
            User.Id => userRecord.Id,
            User.COMM_EmailValidationChangedAddress__c => newEmail
        };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(new List<EmailTemplate>{ templateForNewEmail, templateForOldEmail });
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
            worker = new COMM_SL_ChangeEmail(USER_REP, GET_TEMPLATE_SL, HELPER_SL);
            worker.changeEmail(userRecord.Id, userRecord.LanguageLocaleKey, newEmail, 'https://ana.pt/salesforcetest', 'Customers_Portal1');
        } catch (AuraHandledException e) {
            errorOccured = true;
        }
        Test.stopTest();
        ((COMM_IREP_User) mocks.verify(USER_REP, 1))
            .updateSObjects((List<User>) fflib_Match.sObjectsWith(new List<Map<Schema.SObjectField, Object>>{ toMatchMap }));
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void changeUserEmailWithGoogleTest() {
        //Scenario: User initiatas the Change Email process but is a Google User.
        //Expected: An error is throwed

        User googleUser = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sObjectType),
                'Username' => 'google.user@google.comFromGoogle',
                'Email' => 'google.user@google.com',
                'LastName' => 'Customer',
                'FirstName' => 'Google',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER
            }
        )[0];

        //Mock Query
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ googleUser });
        ((COMM_SL_ChangeEmailHelper) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('User Exists Error') }, HELPER_SL))
            .checkForExistingUser(fflib_Match.anyString());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
            worker = new COMM_SL_ChangeEmail(USER_REP, GET_TEMPLATE_SL, HELPER_SL);
            worker.changeEmail(
                googleUser.Id,
                googleUser.LanguageLocaleKey,
                'test@test.invalid',
                'https://ana.pt/salesforcetest',
                'Customers_Portal1'
            );
        } catch (AuraException e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void changeUserEmailAlreadyUsedTest() {
        //Scenario: User initiatas the Change Email process but email is being used by another customer.
        //Expected: An error is throwed

        User customerUser = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sObjectType),
                'Username' => 'test.user@outlook.comFromNormal',
                'Email' => 'test.user@outlook.com.invalid',
                'LastName' => 'Customer',
                'FirstName' => 'Test',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER
            }
        )[0];

        User existingUser = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sObjectType),
                'Username' => 'existing.user@google.comFromNormal',
                'Email' => 'existing.user@google.com.invalid',
                'LastName' => 'Customer',
                'FirstName' => 'Google',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER
            }
        )[0];

        //Mock Query
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ customerUser });
        ((COMM_SL_ChangeEmailHelper) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('User Exists Error') }, HELPER_SL))
            .checkForExistingUser(fflib_Match.anyString());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
            worker = new COMM_SL_ChangeEmail(USER_REP, GET_TEMPLATE_SL, HELPER_SL);
            worker.changeEmail(
                customerUser.Id,
                customerUser.LanguageLocaleKey,
                existingUser.Email,
                'https://ana.pt/salesforcetest',
                'Customers_Portal1'
            );
        } catch (AuraException e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void changeUserEmailFailureTest() {
        //Scenario: User initiates the Change Email process. An unexpected error occurs setting up validation.
        //Expected: An error is throwed.

        //Create Mocked Records
        User userRecord = new User();
        userRecord.Id = UserInfo.getUserId();
        userRecord.LanguageLocaleKey = 'pt_BR';

        EmailTemplate templateForNewEmail = new EmailTemplate();
        templateForNewEmail.Name = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.DeveloperName = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        EmailTemplate templateForOldEmail = new EmailTemplate();
        templateForOldEmail.Name = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.DeveloperName = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        OrgWideEmailAddress orgAddress = new OrgWideEmailAddress();
        orgAddress.Address = 'no-reply@ana.pt.invalid';

        String newEmail = 'newemail@test.com.invalid';

        Map<Schema.SObjectField, Object> toMatchMap = new Map<Schema.SObjectField, Object>{
            User.Id => userRecord.Id,
            User.COMM_EmailValidationChangedAddress__c => newEmail
        };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(GET_TEMPLATE_SL.getEmailTemplates((List<String>) fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(new List<EmailTemplate>{ templateForNewEmail, templateForOldEmail });
        ((COMM_IREP_User) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, USER_REP))
            .updateSObjects((List<User>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
            worker = new COMM_SL_ChangeEmail(USER_REP, GET_TEMPLATE_SL, HELPER_SL);
            worker.changeEmail(userRecord.Id, userRecord.LanguageLocaleKey, newEmail, 'https://ana.pt/salesforcetest', 'Customers_Portal1');
        } catch (AuraException e) {
            errorOccured = true;
        }
        Test.stopTest();
        ((COMM_IREP_User) mocks.verify(USER_REP, 1))
            .updateSObjects((List<User>) fflib_Match.sObjectsWith(new List<Map<Schema.SObjectField, Object>>{ toMatchMap }));
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void validateEmailChangeSuccessTest() {
        //Scenario: User initiates the Change Email process. Followed link from email.
        //Expected: Validation returned success.

        //Expected Token
        COMM_SL_ChangeEmail.TokenWrapper token = new COMM_SL_ChangeEmail.TokenWrapper();
        token.userId = fflib_IDGenerator.generate(User.SObjectType);
        token.requestDate = System.now().addDays(1);
        String encriptedToken = COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(HELPER_SL.emailChangeValidation(token.userId, token.requestDate)).thenReturn(true);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
        worker = new COMM_SL_ChangeEmail(USER_REP, GET_TEMPLATE_SL, HELPER_SL);
        Boolean validationResult = worker.validateEmailChange(encriptedToken);
        Test.stopTest();

        //Verify Results
        Assert.isTrue(validationResult, 'expected validation to pass');
    }

    @isTest
    static void validateEmailChangeExceptionTest() {
        //Scenario: User opens link with an invalid token.
        //Expected: An exception is throwed.

        //Token
        String invalidToken = 'wrong token';

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_ChangeEmail worker = new COMM_SL_ChangeEmail();
            worker.validateEmailChange(invalidToken);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }
}