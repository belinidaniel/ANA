/**
 * @author Daniel Lascas
 * @description COMM_SL_ChangeEmailHelper test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/06/2024      100            ECOMM-1495 - Original version
 * Miguel Freire    22/07/2024      100            Added changeUserEmailWithGoogleTest and changeUserEmailAlreadyUsedTest
 **/
@isTest
private class COMM_SL_ChangeEmailHelperTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_IREP_Contact CONTACT_REP = (COMM_REP_Contact) MOCKS.mock(COMM_REP_Contact.class);
    private final static COMM_IREP_OrgWideEmailAddress ORGWIDE_ADDRESS_REP = (COMM_REP_OrgWideEmailAddress) MOCKS.mock(
        COMM_REP_OrgWideEmailAddress.class
    );

    @TestSetup
    static void makeData() {
        //Create Customer User
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);

        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Customer',
                'PersonEmail' => 'test.customer@ana.pt.invalid',
                'RecordTypeId' => recTypeInfo.recordtypeid
            }
        )[0];
        Id contactId = [SELECT PersonContactId FROM Account WHERE Id = :personAccount.Id].PersonContactId;

        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_IDENTITY_USER];

        Long suffix = DateTime.now().getTime();
        String nickname = 'testcustomer' + suffix;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => nickname + '@ana.pt.invalid',
                'Email' => personAccount.PersonEmail,
                'LastName' => personAccount.LastName,
                'FirstName' => personAccount.FirstName,
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => nickname,
                'Alias' => 'testCust',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id,
                'ContactId' => contactId,
                'COMM_EmailValidationExpirationDate__c' => System.now().addHours(1),
                'COMM_EmailValidationChangedAddress__c' => 'test.customer.alt@ana.pt.invalid'
            }
        );
    }

    @isTest
    static void sendEmailChangeValidationTest() {
        //Scenario: User initiated email change. Two emails are to be sent
        //Expected: An email invocation was called

        //Insert Test Email Templates (can't add to makeData due to MIXED_DML_OPERATION)
        EmailTemplate templateForNewEmail = new EmailTemplate();
        templateForNewEmail.Name = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.DeveloperName = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.FolderId = UserInfo.getUserId();
        templateForNewEmail.TemplateType = 'custom';

        EmailTemplate templateForOldEmail = new EmailTemplate();
        templateForOldEmail.Name = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.DeveloperName = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.FolderId = UserInfo.getUserId();
        templateForOldEmail.TemplateType = 'custom';

        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>{ templateForNewEmail, templateForOldEmail };

        insert emailTemplateList;

        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];

        Test.startTest();
        System.runAs(customerUser) {
            COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper();
            worker.sendEmailChangeValidation(customerUser.Id, 'teste@test.invalid', emailTemplateList);
        }
        Integer emailInvocation = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, emailInvocation, 'expected an email invocation to have been called');
    }

    @isTest
    static void sendEmailChangeValidationFailureTest() {
        //Scenario: User initiated email change but provided templates don't exist.
        //Expected: Exception is throwed and error log record is created.

        //Mock Email Templates (don't exist for use)
        EmailTemplate templateForNewEmail = new EmailTemplate();
        templateForNewEmail.Id = fflib_IdGenerator.generate(EmailTemplate.sObjectType);
        templateForNewEmail.Name = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.DeveloperName = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        EmailTemplate templateForOldEmail = new EmailTemplate();
        templateForOldEmail.Id = fflib_IdGenerator.generate(EmailTemplate.sObjectType);
        templateForOldEmail.Name = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.DeveloperName = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';

        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>{ templateForNewEmail, templateForOldEmail };

        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];

        Boolean errorOccured = false;
        Test.startTest();
        try {
            System.runAs(customerUser) {
                COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper();
                worker.sendEmailChangeValidation(customerUser.Id, 'teste@test.invalid', emailTemplateList);
            }
        } catch (Exception e) {
            errorOccured = true;
        }
        Integer emailInvocation = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to have been created');
        Assert.areEqual(0, emailInvocation, 'expected NO email invocation to have been called');
    }

    @isTest
    static void sendEmailChangeValidationSwitchedTemplatesTest() {
        //Scenario: User initiated email change. Two emails are to be sent.
        //Order of templates are reversed to verify that order doesn't cause error.
        //Expected: An email invocation was called

        //Insert Test Email Templates (can't add to makeData due to MIXED_DML_OPERATION)
        EmailTemplate templateForNewEmail = new EmailTemplate();
        templateForNewEmail.Name = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.DeveloperName = COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForNewEmail.FolderId = UserInfo.getUserId();
        templateForNewEmail.TemplateType = 'custom';

        EmailTemplate templateForOldEmail = new EmailTemplate();
        templateForOldEmail.Name = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.DeveloperName = COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME + '_pt_BR';
        templateForOldEmail.FolderId = UserInfo.getUserId();
        templateForOldEmail.TemplateType = 'custom';

        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>{ templateForOldEmail, templateForNewEmail };

        insert emailTemplateList;

        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];

        Test.startTest();
        System.runAs(customerUser) {
            COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper();
            worker.sendEmailChangeValidation(customerUser.Id, 'teste@test.invalid', emailTemplateList);
        }
        Integer emailInvocation = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, emailInvocation, 'expected an email invocation to have been called');
    }

    @isTest
    static void emailChangeValidationSuccessTest() {
        //Scenario: User opens Email Change Link, validation for a valid token is run.
        //Expected: Validation Success.

        User customerUser = [
            SELECT Id, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationChangedAddress__c
            FROM User
            WHERE Name = 'Test Customer'
            LIMIT 1
        ];

        Boolean validationResult;

        Test.startTest();
        System.runAs(customerUser) {
            COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper();
            validationResult = worker.emailChangeValidation(customerUser.Id, customerUser.COMM_EmailValidationExpirationDate__c);
        }
        Test.stopTest();

        User updatedUser = [
            SELECT Id, Email
            FROM User
            WHERE Name = 'Test Customer'
            LIMIT 1
        ];

        Assert.isTrue(validationResult, 'expected validation to succeed');
        Assert.areEqual(customerUser.COMM_EmailValidationChangedAddress__c, updatedUser.Email, 'expected user email to change');
    }

    @isTest
    static void emailChangeValidationFailureTest() {
        //Scenario: User opens Email Change Link, validation for a valid token is run but has expired.
        //Expected: Validation Failure.
        User customerUser = [
            SELECT Id, ContactId, COMM_EmailValidationChangedAddress__c, COMM_EmailValidationExpirationDate__c
            FROM User
            WHERE Name = 'Test Customer'
            LIMIT 1
        ];

        //Create Mocked User with expired validation
        User mockedUser = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => customerUser.Id,
                'ContactId' => customerUser.ContactId,
                'COMM_EmailValidationChangedAddress__c' => customerUser.COMM_EmailValidationChangedAddress__c,
                'COMM_EmailValidationExpirationDate__c' => System.now().addHours(-1)
            }
        )[0];

        //Mock Queries and DML Result
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersWithEmailChangeValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ mockedUser });
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean validationResult;

        Test.startTest();
        System.runAs(customerUser) {
            COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper(USER_REP, CONTACT_REP, ORGWIDE_ADDRESS_REP);
            validationResult = worker.emailChangeValidation(customerUser.Id, customerUser.COMM_EmailValidationExpirationDate__c);
        }
        Test.stopTest();

        //Verify no DML operation were called
        ((COMM_IREP_User) mocks.verify(USER_REP, 0)).updateSObjects((List<User>) fflib_Match.anyList());
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 0)).updateSObjects((List<Contact>) fflib_Match.anyList());
        //Verify validation failed
        Assert.isFalse(validationResult, 'expected validation to fail');
    }

    @isTest
    static void emailChangeValidationErrorTest() {
        //Scenario: User opens Email Change Link, validation for a valid token is run. Unexpected error occurs.
        //Expected: Exception is throwed and a Error Log Record is created.
        User customerUser = [
            SELECT Id, ContactId, COMM_EmailValidationChangedAddress__c, COMM_EmailValidationExpirationDate__c
            FROM User
            WHERE Name = 'Test Customer'
            LIMIT 1
        ];

        //Mock Queries and DML Result
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersWithEmailChangeValidationById((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ customerUser });
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        ((COMM_IREP_Contact) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, CONTACT_REP))
            .updateSObjects((List<Contact>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        System.runAs(customerUser) {
            try {
                COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper(USER_REP, CONTACT_REP, ORGWIDE_ADDRESS_REP);
                worker.emailChangeValidation(customerUser.Id, customerUser.COMM_EmailValidationExpirationDate__c);
            } catch (Exception e) {
                errorOccured = true;
            }
        }
        Test.stopTest();

        //Verify validation failed
        Assert.isTrue(errorOccured, 'expected error to occur');
        //Verify Error Log was created
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to have been created');
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
        MOCKS.when(USER_REP.getActiveNonPartnerUserByEmail(fflib_Match.anyString(), fflib_Match.anyBoolean())).thenReturn(existingUser);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_SL_ChangeEmailHelper worker = new COMM_SL_ChangeEmailHelper();
            worker = new COMM_SL_ChangeEmailHelper(USER_REP, CONTACT_REP, ORGWIDE_ADDRESS_REP);
            worker.checkForExistingUser(existingUser.Email);
        } catch (AuraException e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }
}