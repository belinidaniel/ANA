/**
 * @author           Daniel Lascas
 * @description      COMM_LCC_AccountInformation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/03/2024      95            ECOMM-142 - Original version
 * Miguel Justo     19/08/2024      97            Changed deactivateAccountTest
 **/
@isTest
private class COMM_LCC_AccountInformationTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_IREP_Contact CONTACT_REP = (COMM_REP_Contact) MOCKS.mock(COMM_REP_Contact.class);
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_IREP_Case CASE_REP = (COMM_REP_Case) MOCKS.mock(COMM_REP_Case.class);
    private final static COMM_IDO_AccountManagementMapping MAPPING_DO = (COMM_DO_AccountManagementMapping) MOCKS.mock(
        COMM_DO_AccountManagementMapping.class
    );

    private final static Id TEST_ACCOUNT_ID = fflib_IdGenerator.generate(Account.sObjectType);
    private final static Id TEST_PERSON_ACCOUNT_ID = fflib_IdGenerator.generate(Account.sObjectType);

    @isTest
    static void interfaceTest() {
        //Scenario: This is just for coverage.
        //The interface methods are static and cannot be tested using the mock framework.
        //The actual testing is done below using the mock framework.
        Boolean errorOccured = false;
        try {
            COMM_LCC_AccountInformation.retrieveAccountDetails();
        } catch (Exception e) {
            errorOccured = true;
        }
        Assert.isTrue(errorOccured, 'no error has occured when retrieving unexisting data');

        errorOccured = false;
        try {
            COMM_LCC_AccountInformation.updateAccountDetails(null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Assert.isTrue(errorOccured, 'no error has occured when updating with unexisting data');
    }

    @isTest
    static void getCountryPicklistValuesTest() {
        //Retrieve Map with Country Values

        Test.startTest();
        Map<String, String> resultMap = COMM_LCC_AccountInformation.getCountryPicklistValues();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected a map with values');
        Assert.isTrue(resultMap.containsKey('PT'), 'expected map to contain Portugal');
    }

    @isTest
    static void validateVatTest() {
        //Call VAT Validation Test

        Test.startTest();
        Boolean validationResult = COMM_LCC_AccountInformation.validateVAT('2191', 'PT');
        Test.stopTest();

        Assert.isFalse(validationResult, 'expected validation to fail');
    }

    @isTest
    static void handleRetrieveAccountDetailsTest() {
        //Scenario: Customer with Person Account opens Account Management
        //Expected: User's Account Details are returned in a Map

        //Mock Person Account
        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => TEST_PERSON_ACCOUNT_ID,
                'FirstName' => 'Test',
                'LastName' => 'User',
                'PersonEmail' => 'test@user.com.invalid'
            }
        )[0];
        personAccount = (Account) COMM_TestDataFactory.setField(personAccount, new Map<String, Object>{ 'IsPersonAccount' => true });

        //Mock User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(User.sObjectType), 'FirstName' => 'Test', 'LastName' => 'User' }
        )[0];
        userRecord = (User) COMM_TestDataFactory.setField(
            userRecord,
            new Map<String, Object>{ 'AccountId' => personAccount.Id, 'Account' => personAccount }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<Case>());
        ((COMM_IDO_AccountManagementMapping) MOCKS.doAnswer(new PersonAccountMappingMock(), MAPPING_DO))
            .mapJsonFromSObject((Account) fflib_Match.anyObject(), (Map<String, Object>) fflib_Match.anyObject(), fflib_Match.anyBoolean());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_AccountInformation worker = new COMM_LCC_AccountInformation();
        worker = new COMM_LCC_AccountInformation(USER_REP, CASE_REP, ACCOUNT_REP, CONTACT_REP, MAPPING_DO);
        Map<String, Object> resultMap = worker.handleRetrieveAccountDetails();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected resulting map to not be empty');
        Assert.areEqual(TEST_PERSON_ACCOUNT_ID, resultMap.get('accountId'), 'account id does not match expected');
        Assert.areEqual('+351', resultMap.get('personalPhoneCode'), 'phone code does not match expected');
    }

    @isTest
    static void handleRetrieveAccountSwitchDetailsTest() {
        //Scenario: A Partner with a B2B Account opens Account Management after switching Accounts
        //Expected: Switched Account Details are returned in a Map

        //Mock User's Account
        Account usersAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => TEST_PERSON_ACCOUNT_ID, 'Name' => 'Test Inc' }
        )[0];

        //Mock B2B Account
        Account switchedAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => TEST_ACCOUNT_ID, 'Name' => 'Test LDA' }
        )[0];

        //Mock User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sObjectType),
                'FirstName' => 'Test',
                'LastName' => 'User',
                'COMM_EffectiveAccountId__c' => switchedAccount.Id
            }
        )[0];
        userRecord = (User) COMM_TestDataFactory.setField(
            userRecord,
            new Map<String, Object>{ 'AccountId' => usersAccount.Id, 'Account' => usersAccount }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ switchedAccount });
        ((COMM_IDO_AccountManagementMapping) MOCKS.doAnswer(new B2BAccountMappingMock(), MAPPING_DO))
            .mapJsonFromSObject((SObject) fflib_Match.anySObject(), (Map<String, Object>) fflib_Match.anyObject(), fflib_Match.anyBoolean());
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<Case>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_AccountInformation worker = new COMM_LCC_AccountInformation();
        worker = new COMM_LCC_AccountInformation(USER_REP, CASE_REP, ACCOUNT_REP, CONTACT_REP, MAPPING_DO);
        Map<String, Object> resultMap = worker.handleRetrieveAccountDetails();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected resulting map to not be empty');
        Assert.areEqual(TEST_ACCOUNT_ID, resultMap.get('accountId'), 'account id does not match expected');
        Assert.areEqual('+351', resultMap.get('personalPhoneCode'), 'phone code does not match expected');
    }

    @isTest
    static void handleRetrieveAffiliateAccountDetailsTest() {
        //Scenario: A Customer with an Affiliate Account opens Account Management
        //Expected: Affiliate Account Details are returned in a Map

        //Mock Affiliate Account
        Account affiliateAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => TEST_ACCOUNT_ID, 'Name' => 'Test LDA', 'COMM_IsAffiliate__c' => true }
        )[0];

        //Mock User's Account
        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => TEST_PERSON_ACCOUNT_ID,
                'FirstName' => 'Test',
                'LastName' => 'User',
                'PersonEmail' => 'test@user.com.invalid',
                'COMM_ParentAccount__c' => affiliateAccount.Id
            }
        )[0];
        personAccount = (Account) COMM_TestDataFactory.setField(
            personAccount,
            new Map<String, Object>{
                'IsPersonAccount' => true,
                'COMM_ParentAccountIsAffiliate__c' => true,
                'COMM_ParentAccountData__c' => '{"accountId":"' +
                TEST_ACCOUNT_ID +
                '"}'
            }
        );

        //Mock User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sObjectType),
                'FirstName' => personAccount.FirstName,
                'LastName' => personAccount.LastName,
                'Email' => personAccount.PersonEmail
            }
        )[0];
        userRecord = (User) COMM_TestDataFactory.setField(
            userRecord,
            new Map<String, Object>{ 'AccountId' => personAccount.Id, 'Account' => personAccount }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        ((COMM_IDO_AccountManagementMapping) MOCKS.doAnswer(new B2BAccountMappingMock(), MAPPING_DO))
            .mapJsonFromSObject((SObject) fflib_Match.anySObject(), (Map<String, Object>) fflib_Match.anyObject(), fflib_Match.anyBoolean());
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<Case>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_AccountInformation worker = new COMM_LCC_AccountInformation();
        worker = new COMM_LCC_AccountInformation(USER_REP, CASE_REP, ACCOUNT_REP, CONTACT_REP, MAPPING_DO);
        Map<String, Object> resultMap = worker.handleRetrieveAccountDetails();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected resulting map to not be empty');
        Assert.areEqual(TEST_ACCOUNT_ID, resultMap.get('accountId'), 'account id does not match expected');
    }

    @isTest
    static void handleUpdateAccountDetailsTest() {
        //Scenario: Customer with Person Account opens Account Management and made changes to their detais and submitted it.
        //Expected: User's Person Account Details are updated

        //Mock Details
        Map<String, Object> mockedInput = new Map<String, Object>{
            'isB2C' => true,
            'accountId' => TEST_PERSON_ACCOUNT_ID,
            'contactId' => null,
            'personalFirstName' => 'New Test',
            'personalLastName' => 'User',
            'personalPhoneCode' => '+351',
            'personalPhoneNumber' => '936 123 000',
            'preferencialContact' => true,
            'marketingConsent' => false
        };

        //Mock Queries
        MOCKS.startStubbing();
        ((COMM_IDO_AccountManagementMapping) MOCKS.doAnswer(new JsonMappingMock(), MAPPING_DO))
            .mapSObjectFromJson((Map<String, Object>) fflib_Match.anyObject(), (SObject) fflib_Match.anySObject(), fflib_Match.anyBoolean());
        MOCKS.when(ACCOUNT_REP.updateSObjects((List<Account>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_AccountInformation worker = new COMM_LCC_AccountInformation();
            worker = new COMM_LCC_AccountInformation(USER_REP, CASE_REP, ACCOUNT_REP, CONTACT_REP, MAPPING_DO);
            worker.handleUpdateAccountDetails(mockedInput);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void handleUpdateAccountDetailsB2BTest() {
        //Scenario: Customer with B2B Account opens Account Management and made changes to their detais and submitted it.
        //Expected: User's B2B Account Details are updated

        //Mock Details
        Map<String, Object> mockedInput = new Map<String, Object>{
            'isB2C' => false,
            'accountId' => TEST_ACCOUNT_ID,
            'contactId' => fflib_IDGenerator.generate(Contact.sObjectType),
            'personalFirstName' => 'New Test',
            'personalLastName' => 'User',
            'personalPhoneCode' => '+351',
            'personalPhoneNumber' => '936 123 000',
            'preferencialContact' => false,
            'marketingConsent' => true
        };

        //Mock Queries
        MOCKS.startStubbing();
        ((COMM_IDO_AccountManagementMapping) MOCKS.doAnswer(new JsonMappingB2BMock(), MAPPING_DO))
            .mapSObjectFromJson((Map<String, Object>) fflib_Match.anyObject(), (SObject) fflib_Match.anySObject(), fflib_Match.anyBoolean());
        MOCKS.when(ACCOUNT_REP.updateSObjects((List<Account>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(CONTACT_REP.updateSObjects((List<Contact>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(USER_REP.updateSObjects((List<User>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_AccountInformation worker = new COMM_LCC_AccountInformation();
            worker = new COMM_LCC_AccountInformation(USER_REP, CASE_REP, ACCOUNT_REP, CONTACT_REP, MAPPING_DO);
            worker.handleUpdateAccountDetails(mockedInput);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void changePasswordTest() {
        //This test is for code coverage. Test for Change Password is present on the test class for COMM_SL_ResetPassword.
        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_LCC_AccountInformation.changePassword();
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur executing logic');
    }

    @isTest
    static void changeEmailTest() {
        //This test is for code coverage. Test for Change Email is present on the test class for COMM_SL_ChangeEmail.
        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_LCC_AccountInformation.changeEmail('test@');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur executing logic');
    }

    @isTest
    static void deactivateAccountTest() {
        //This test is for code coverage. Logic is performed by Flow.
        //Ensure the running user's owner has a role
        User adminUser = [
            SELECT Id, UserRoleId, IsActive
            FROM User
            WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE AND UserRoleId != NULL
            LIMIT 1
        ];

        //Create Customer User
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        // Created Account Record owned by a user with a role
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test' + DateTime.now().getTime(),
                'LastName' => 'Account' + DateTime.now().getTime(),
                'PersonEmail' => 'test@user.com.invalid',
                'RecordTypeId' => recTypeInfo.recordtypeid,
                'OwnerId' => adminUser.Id
            }
        )[0];
        Id contactId = [SELECT PersonContactId FROM Account WHERE Id = :testAccount.Id].PersonContactId;

        //Get Profile
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'Customers'];
        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;

        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => USERNAME + '@ana.pt.test',
                'Email' => USERNAME + '@test.com.invalid',
                'LastName' => 'User ' + SUFFIX,
                'FirstName' => 'Test',
                'CommunityNickname' => USERNAME,
                'Alias' => USERNAME.right(8),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id,
                'ContactId' => contactId
            }
        )[0];

        //Run as a Customer user.
        System.runAs(userRecord) {
            Boolean errorOccured = false;
            Test.startTest();
            try {
                COMM_LCC_AccountInformation.deactivateAccount();
            } catch (Exception e) {
                errorOccured = true;
            }
            Test.stopTest();

            Assert.isFalse(errorOccured, 'Expected no error to occur because internal users should be able to self-deactivate.');
        }
    }

    //Mock Account Mapping Process using fflib_Answer
    private class PersonAccountMappingMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            Map<String, Object> mappingMap = (Map<String, Object>) invocation.getArgument(1);
            mappingMap.put('accountId', TEST_PERSON_ACCOUNT_ID);
            mappingMap.put('personalPhoneNumber', '+351 936000222');
            return null;
        }
    }

    //Mock B2B Account Mapping Process using fflib_Answer
    private class B2BAccountMappingMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SObject sobjRecord = (SObject) invocation.getArgument(0);
            Map<String, Object> mappingMap = (Map<String, Object>) invocation.getArgument(1);

            mappingMap.put('accountId', TEST_ACCOUNT_ID);
            mappingMap.put('contactId', fflib_IDGenerator.generate(Contact.SObjectType));
            mappingMap.put('personalPhoneNumber', '+351 936000222');
            return null;
        }
    }

    //Mock JSON Mapping Process using fflib_Answer
    private class JsonMappingMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SObject sobjRecord = (SObject) invocation.getArgument(1);
            Map<String, Object> mappingMap = (Map<String, Object>) invocation.getArgument(0);

            sobjRecord.put('Id', mappingMap.get('accountId'));
            sobjRecord.put('FirstName', mappingMap.get('personalFirstName'));
            sobjRecord.put('LastName', mappingMap.get('personalLastName'));
            sobjRecord.put('PersonMobilePhone', mappingMap.get('personalPhoneNumber'));
            return null;
        }
    }

    //Mock JSON Mapping Process for B2B using fflib_Answer
    private class JsonMappingB2BMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SObject sobjRecord = (SObject) invocation.getArgument(1);
            Map<String, Object> mappingMap = (Map<String, Object>) invocation.getArgument(0);

            sobjRecord.put('Id', mappingMap.get('accountId'));
            sobjRecord.put('FirstName', mappingMap.get('personalFirstName'));
            sobjRecord.put('LastName', mappingMap.get('personalLastName'));
            return null;
        }
    }
}