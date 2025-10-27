/**
 * @author Daniel Lascas
 * @description COMM_DO_CommerceAppMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024      100            ECOMM-178: Original version
 **/
@isTest
private class COMM_DO_CommerceAppMappingTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);

    @isTest
    static void accountDataB2CTest() {
        //Scenario: User has a Person Account with no Parent Account.
        //Expected: Mapped data with User's Person Account.

        //Mock Person Account
        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'FirstName' => 'Test',
                'LastName' => 'User',
                'PersonEmail' => 'test@user.com.invalid',
                'BillingCountryCode' => 'PT',
                'COMM_ParentAccount__c' => null
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

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_DO_CommerceAppMapping worker = new COMM_DO_CommerceAppMapping();
        worker = new COMM_DO_CommerceAppMapping(USER_REP, ACCOUNT_REP);
        Map<String, String> resultMap = worker.getAccountDataMapWithUserId(userRecord.Id, new Map<String, String>());
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_Account.ACCOUNT_TYPE_B2C,
            resultMap.get(COMM_DO_CommerceAppMapping.CUSTOMER_TYPE_ATTRIBUTE),
            'Customer Type does not match expected for Person Account'
        );
    }

    @isTest
    static void accountDataB2BTest() {
        //Scenario: User has a B2B Account.
        //Expected: Mapped data with User's Account

        //Mock Account
        Account businessAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.sObjectType), 'Name' => 'Test INC' }
        )[0];
        businessAccount = (Account) COMM_TestDataFactory.setField(businessAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        //Mock User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(User.sObjectType), 'FirstName' => 'Test', 'LastName' => 'User' }
        )[0];
        userRecord = (User) COMM_TestDataFactory.setField(
            userRecord,
            new Map<String, Object>{ 'AccountId' => businessAccount.Id, 'Account' => businessAccount }
        );

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_DO_CommerceAppMapping worker = new COMM_DO_CommerceAppMapping();
        worker = new COMM_DO_CommerceAppMapping(USER_REP, ACCOUNT_REP);
        Map<String, String> resultMap = worker.getAccountDataMapWithUserId(userRecord.Id, new Map<String, String>());
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_Account.ACCOUNT_TYPE_B2B,
            resultMap.get(COMM_DO_CommerceAppMapping.CUSTOMER_TYPE_ATTRIBUTE),
            'Customer Type does not match expected for Business Account'
        );
    }

    @isTest
    static void parentAccountIsAffiliateDataTest() {
        //Scenario: User has a Person Account with a Parent Account. Parent Account is an affiliate.
        //Expected: Mapped data with Parent Account

        //Mock Account
        Account businessAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'Name' => 'Test Inc',
                'COMM_IsAffiliate__c' => true,
                'COMM_PaymentMethod__c' => COMM_DO_Account.PAYMENT_METHOD_CREDIT
            }
        )[0];
        businessAccount = (Account) COMM_TestDataFactory.setField(businessAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        //Mock Person Account
        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'FirstName' => 'Test',
                'LastName' => 'User',
                'PersonEmail' => 'test@user.com.invalid',
                'COMM_ParentAccount__c' => businessAccount.Id
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

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ businessAccount });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_DO_CommerceAppMapping worker = new COMM_DO_CommerceAppMapping();
        worker = new COMM_DO_CommerceAppMapping(USER_REP, ACCOUNT_REP);
        Map<String, String> resultMap = worker.getAccountDataMapWithUserId(userRecord.Id, new Map<String, String>());
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_Account.ACCOUNT_TYPE_B2B,
            resultMap.get(COMM_DO_CommerceAppMapping.CUSTOMER_TYPE_ATTRIBUTE),
            'Customer Type does not match expected for Business Account'
        );
    }

    @isTest
    static void parentAccountIsNotAffiliateDataTest() {
        //Scenario: User has a Person Account with a Parent Account. Parent Account is not an affiliate.
        //Expected: Mapped data with User's Person Account

        //Mock Account
        Account businessAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.sObjectType), 'Name' => 'Test Inc', 'COMM_IsAffiliate__c' => false }
        )[0];
        businessAccount = (Account) COMM_TestDataFactory.setField(businessAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        //Mock Person Account
        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'FirstName' => 'Test',
                'LastName' => 'User',
                'PersonEmail' => 'test@user.com.invalid',
                'COMM_ParentAccount__c' => businessAccount.Id
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

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ businessAccount });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_DO_CommerceAppMapping worker = new COMM_DO_CommerceAppMapping();
        worker = new COMM_DO_CommerceAppMapping(USER_REP, ACCOUNT_REP);
        Map<String, String> resultMap = worker.getAccountDataMapWithUserId(userRecord.Id, new Map<String, String>());
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_Account.ACCOUNT_TYPE_B2C,
            resultMap.get(COMM_DO_CommerceAppMapping.CUSTOMER_TYPE_ATTRIBUTE),
            'Customer Type does not match expected for Business Account'
        );
    }
}