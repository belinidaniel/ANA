/**
 * @author           Daniel Lascas
 * @description      COMM_SL_AuthProviderHandler test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/02/2024      100            Original version
 **/
@isTest
private class COMM_SL_AuthProviderHandlerTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_REP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_REP_Contact CONTACT_REP = (COMM_REP_Contact) MOCKS.mock(COMM_REP_Contact.class);
    private final static COMM_DO_User USER_DO = (COMM_DO_User) MOCKS.mock(COMM_DO_User.class);
    @isTest
    static void noDataTest() {
        // Scenario: A user tries to register but authProvider doesnt provide required fields
        // Expected: Null User is returned
        // Create Data
        Auth.UserData authProviderData = new Auth.UserData(null, null, null, null, null, null, null, null, null, null, null);
        Test.startTest();
        COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
        worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
        User returnedUser = worker.createUser(null, authProviderData);
        Test.stopTest();
        Assert.isNull(returnedUser, 'Expected null user returned');
    }

    @isTest
    static void userCreationTest() {
        // Scenario: A user tries to register with Google
        // Expected: User record is returned

        //Mock Person Account. Using Framework method to create record due to read-only fields (PersonContactId)
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account mockedAccount = (Account) fflib_ApexMocksUtils.setReadOnlyFields(
            new Account(),
            Account.class,
            new Map<SObjectField, Object>{
                Account.Id => fflib_IDGenerator.generate(Account.SObjectType),
                Account.PersonEmail => 'test@test.com.invalid',
                Account.LastName => 'User',
                Account.FirstName => 'Portal',
                Account.RecordTypeId => recTypeInfo.recordtypeid,
                Account.PersonContactId => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Mock expected User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => mockedAccount.PersonEmail,
                'LastName' => mockedAccount.LastName,
                'FirstName' => mockedAccount.FirstName,
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType),
                'ContactId' => mockedAccount.PersonContactId
            }
        )[0];

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            mockedAccount.FirstName,
            mockedAccount.LastName,
            null,
            mockedAccount.PersonEmail,
            null,
            null,
            null,
            COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.insertSObjects((List<Account>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(ACCOUNT_REP.getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ mockedAccount });
        MOCKS.when(USER_DO.instantiateUser(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(userRecord);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
        worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
        User returnedUser = worker.createUser(null, authProviderData);
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1)).insertSObjects((List<Account>) fflib_Match.anyList());
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1)).getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject());
        ((COMM_DO_User) mocks.verify(USER_DO, 1))
            .instantiateUser(authProviderData.firstName, authProviderData.lastName, authProviderData.email, authProviderData.provider);
        Assert.areEqual(returnedUser, userRecord, 'generated user does not match expected');
    }

    @isTest
    static void userCreationNoLastNameTest() {
        // Scenario: A user tries to register with Google. User only provided first name.
        // Expected: User record is returned

        //Mock Person Account. Using Framework method to create record due to read-only fields (PersonContactId)
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account mockedAccount = (Account) fflib_ApexMocksUtils.setReadOnlyFields(
            new Account(),
            Account.class,
            new Map<SObjectField, Object>{
                Account.Id => fflib_IDGenerator.generate(Account.SObjectType),
                Account.PersonEmail => 'test@test.com.invalid',
                Account.LastName => 'Portal',
                Account.FirstName => 'Portal',
                Account.RecordTypeId => recTypeInfo.recordtypeid,
                Account.PersonContactId => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Mock expected User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => mockedAccount.PersonEmail,
                'LastName' => mockedAccount.LastName,
                'FirstName' => mockedAccount.LastName,
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
                'CommunityNickname' => 'nullportal',
                'Alias' => 'nullport',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType),
                'ContactId' => mockedAccount.PersonContactId
            }
        )[0];

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'Portal',
            null,
            null,
            mockedAccount.PersonEmail,
            null,
            null,
            null,
            COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.insertSObjects((List<Account>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(ACCOUNT_REP.getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ mockedAccount });
        MOCKS.when(
                USER_DO.instantiateUser((String) fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString())
            )
            .thenReturn(userRecord);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
        worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
        User returnedUser = worker.createUser(null, authProviderData);
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1)).insertSObjects((List<Account>) fflib_Match.anyList());
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1)).getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject());
        ((COMM_DO_User) mocks.verify(USER_DO, 1))
            .instantiateUser(authProviderData.firstName, authProviderData.lastName, authProviderData.email, authProviderData.provider);
        Assert.areEqual(returnedUser, userRecord, 'generated user does not match expected');
    }

    @isTest
    static void azureLoginTest() {
        // Scenario: A user tries to login using Azure AD method
        // Expected: User record is returned

        //Mock expected Azure AD using User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@outlook.com.invalid',
                'Email' => 'testuser@outlook.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Portal',
                'COMM_LoginType__c' => COMM_DO_User.AZURE_SSO_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType)
            }
        )[0];

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            userRecord.FirstName,
            userRecord.LastName,
            null,
            userRecord.Email,
            null,
            null,
            null,
            COMM_DO_User.AZURE_AUTHPROVIDER_LABEL,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getAzureUsersByEmail((Set<String>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<User>{ userRecord });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
        worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
        User returnedUser = worker.createUser(null, authProviderData);
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getAzureUsersByEmail(new Set<String>{ userRecord.Email }, false);
        Assert.areEqual(returnedUser, userRecord, 'returned user does not match expected');
    }

    @isTest
    static void azureLoginFailureTest() {
        // Scenario: A user tries to login using Azure AD method. User Record doesn't exist in Salesforce.
        // Expected: Null Value returned

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'Portal',
            'User',
            null,
            'testuser@outlook.com.invalid',
            null,
            null,
            null,
            COMM_DO_User.AZURE_AUTHPROVIDER_LABEL,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getAzureUsersByEmail((Set<String>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
        worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
        User returnedUser = worker.createUser(null, authProviderData);
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getAzureUsersByEmail(new Set<String>{ authProviderData.email }, false);
        Assert.isNull(returnedUser, 'returned user does not match expected (null)');
    }

    @isTest
    static void userUpdateTest() {
        // Scenario: A previously logged in user, logs again after some time and changing data in their social account
        // Expected: User record is updated with new data

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Portal',
                'ContactId' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'NewPortal',
            'NewUser',
            null,
            userList[0].Email,
            null,
            null,
            null,
            COMM_DO_User.FACEBOOK_SSO_IDENTIFIER,
            null,
            null
        );

        //Expected Results
        Contact expectedContactUpdate = new Contact(
            Id = userList[0].ContactId,
            FirstName = authProviderData.firstName,
            LastName = authProviderData.lastName
        );
        User expectedUserUpdate = new User(Id = userList[0].Id, FirstName = authProviderData.firstName, LastName = authProviderData.lastName);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            worker.updateUser(userList[0].Id, null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getUsersById(new Set<Id>{ userList[0].Id });
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 1)).updateSObjects(new List<Contact>{ expectedContactUpdate });
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).updateSObjects(new List<User>{ expectedUserUpdate });
        Assert.isFalse(errorOccured, 'expected no erros to occur');
    }

    @isTest
    static void userCreationFailureTest() {
        // Scenario: A user tries to register with Google. An unexpected error occurs during Person Account creation.
        // Expected: An error is thrown

        //Mock Person Account. Using Framework method to create record due to read-only fields (PersonContactId)
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account mockedAccount = (Account) fflib_ApexMocksUtils.setReadOnlyFields(
            new Account(),
            Account.class,
            new Map<SObjectField, Object>{
                Account.Id => fflib_IDGenerator.generate(Account.SObjectType),
                Account.PersonEmail => 'test@test.com.invalid',
                Account.LastName => 'User',
                Account.FirstName => 'Portal',
                Account.RecordTypeId => recTypeInfo.recordtypeid,
                Account.PersonContactId => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Mock expected User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => mockedAccount.PersonEmail,
                'LastName' => mockedAccount.LastName,
                'FirstName' => mockedAccount.FirstName,
                'COMM_LoginType__c' => COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType),
                'ContactId' => mockedAccount.PersonContactId
            }
        )[0];

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            mockedAccount.FirstName,
            mockedAccount.LastName,
            null,
            mockedAccount.PersonEmail,
            null,
            null,
            null,
            COMM_DO_User.GOOGLE_SSO_IDENTIFIER,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        ((COMM_IREP_Account) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, ACCOUNT_REP))
            .insertSObjects((List<Account>) fflib_Match.anyList());
        MOCKS.when(ACCOUNT_REP.getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ mockedAccount });
        MOCKS.when(USER_DO.instantiateUser(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(userRecord);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            User returnedUser = worker.createUser(null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1)).insertSObjects((List<Account>) fflib_Match.anyList());
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 0)).getPersonAccountsByIds((Set<Id>) fflib_Match.anyObject());
        ((COMM_DO_User) mocks.verify(USER_DO, 0))
            .instantiateUser(authProviderData.firstName, authProviderData.lastName, authProviderData.email, authProviderData.provider);
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void userNoUpdateTest() {
        // Scenario: A previously logged in user, logs again after some time. Auth Provider doesn't supply required data.
        // Expected: No update is performed

        //Mock Auth Provider Data
        Auth.UserData authProviderData = new Auth.UserData(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            COMM_DO_User.FACEBOOK_SSO_IDENTIFIER,
            null,
            null
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>());
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            worker.updateUser(fflib_IDGenerator.generate(User.SObjectType), null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 0)).getUsersById((Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 0)).updateSObjects((List<Contact>) fflib_Match.anyList());
        ((COMM_IREP_User) mocks.verify(USER_REP, 0)).updateSObjects((List<User>) fflib_Match.anyList());
        Assert.isFalse(errorOccured, 'expected no erros to occur');
    }

    @isTest
    static void userUpdateNoLastNameTest() {
        // Scenario: A previously logged in user, logs again after some time. Auth Provider doesn't supply last name.
        // Expected: Update is performed with First Name being the same as Last Name

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Portal',
                'ContactId' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'NewPortal',
            null,
            null,
            userList[0].Email,
            null,
            null,
            null,
            COMM_DO_User.FACEBOOK_SSO_IDENTIFIER,
            null,
            null
        );

        //Expected Results
        Contact expectedContactUpdate = new Contact(
            Id = userList[0].ContactId,
            FirstName = authProviderData.firstName,
            LastName = authProviderData.firstName
        );
        User expectedUserUpdate = new User(Id = userList[0].Id, FirstName = authProviderData.firstName, LastName = authProviderData.firstName);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            worker.updateUser(userList[0].Id, null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        System.debug(expectedContactUpdate);

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getUsersById(new Set<Id>{ userList[0].Id });
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 1)).updateSObjects(new List<Contact>{ expectedContactUpdate });
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).updateSObjects(new List<User>{ expectedUserUpdate });
        Assert.isFalse(errorOccured, 'expected no erros to occur');
    }

    @isTest
    static void userUpdateFailTest() {
        // Scenario: A previously logged in user, logs again after some time and changing data in their social account.
        // An unexpected error occurs during User update.
        // Expected: Exception is throwed.

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Portal',
                'ContactId' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'NewPortal',
            'NewUser',
            null,
            userList[0].Email,
            null,
            null,
            null,
            COMM_DO_User.FACEBOOK_SSO_IDENTIFIER,
            null,
            null
        );

        //Expected Results
        Contact expectedContactUpdate = new Contact(
            Id = userList[0].ContactId,
            FirstName = authProviderData.firstName,
            LastName = authProviderData.lastName
        );
        User expectedUserUpdate = new User(Id = userList[0].Id, FirstName = authProviderData.firstName, LastName = authProviderData.lastName);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        ((COMM_IREP_User) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, USER_REP))
            .updateSObjects((List<User>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            worker.updateUser(userList[0].Id, null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getUsersById(new Set<Id>{ userList[0].Id });
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 1)).updateSObjects(new List<Contact>{ expectedContactUpdate });
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).updateSObjects(new List<User>{ expectedUserUpdate });
        Assert.isTrue(errorOccured, 'expected an erros to occur');
    }

    @isTest
    static void contactUpdateFailTest() {
        // Scenario: A previously logged in user, logs again after some time and changing data in their social account.
        // An unexpected error occurs during Contact update.
        // Expected: Exception is throwed.

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(User.SObjectType),
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Portal',
                'ContactId' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        Auth.UserData authProviderData = new Auth.UserData(
            null,
            'NewPortal',
            'NewUser',
            null,
            userList[0].Email,
            null,
            null,
            null,
            COMM_DO_User.FACEBOOK_SSO_IDENTIFIER,
            null,
            null
        );

        //Expected Results
        Contact expectedContactUpdate = new Contact(
            Id = userList[0].ContactId,
            FirstName = authProviderData.firstName,
            LastName = authProviderData.lastName
        );
        User expectedUserUpdate = new User(Id = userList[0].Id, FirstName = authProviderData.firstName, LastName = authProviderData.lastName);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        ((COMM_IREP_Contact) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, CONTACT_REP))
            .updateSObjects((List<Contact>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_AuthProviderHandler worker = new COMM_SL_AuthProviderHandler();
            worker = new COMM_SL_AuthProviderHandler(ACCOUNT_REP, CONTACT_REP, USER_REP, USER_DO);
            worker.updateUser(userList[0].Id, null, authProviderData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_User) mocks.verify(USER_REP, 1)).getUsersById(new Set<Id>{ userList[0].Id });
        ((COMM_IREP_Contact) mocks.verify(CONTACT_REP, 1)).updateSObjects(new List<Contact>{ expectedContactUpdate });
        ((COMM_IREP_User) mocks.verify(USER_REP, 0)).updateSObjects((List<User>) fflib_Match.anyList());
        Assert.isTrue(errorOccured, 'expected an erros to occur');
    }
}