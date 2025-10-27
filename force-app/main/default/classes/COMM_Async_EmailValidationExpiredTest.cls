/**
 * @author         Miguel Freire
 * @description    COMM_Async_EmailValidationExpired test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    24/01/2024      88         Original version
 **/
@isTest
private class COMM_Async_EmailValidationExpiredTest {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) mocks.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETER_REP = (FW_REP_Parameters) mocks.mock(FW_REP_Parameters.class);
    private final static FW_IAsync ASYNC_HANDLER = (FW_AsyncHandler) mocks.mock(FW_AsyncHandler.class);
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_REP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);

    @isTest
    private static void COMM_Async_EmailValidationExpiredTest() {
        // Initialize framework
        //Create Batch_Definition
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'COMM_Async_EmailValidationExpired',
                Class_Name__c = 'COMM_Async_EmailValidationExpired',
                Job_Size__c = 200,
                SObject_API_Name__c = 'User'
            )
        };

        //Create Parameters
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER)
        };

        //Create JobExecution
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        List<Job_Execution__c> jobExecutionList2 = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_SCHEDULED
            )
        };

        mocks.startStubbing();
        mocks.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(PARAMETER_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        mocks.when(USER_REP.getUserByInValidationExpiredEmail((Boolean) fflib_match.anyObject())).thenReturn(new List<User>());
        mocks.when(ACCOUNT_REP.getAccountByIds((Set<Id>) fflib_match.anyObject())).thenReturn(new List<Account>());
        mocks.stopStubbing();

        COMM_Async_EmailValidationExpired newBatchRun = new COMM_Async_EmailValidationExpired();
        newBatchRun = new COMM_Async_EmailValidationExpired(USER_REP, ACCOUNT_REP, JOB_EXECUTION_REP, PARAMETER_REP);

        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);

        ((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_IREP_Parameters) mocks.verify(PARAMETER_REP, 1)).getParametersByParentId((Set<Id>) fflib_match.anyObject());
    }
    @isTest
    private static void COMM_Async_EmailValidationExpiredExecuteTest() {
        //Scenario: The Batch tries to Obfuscate the users that have the validationEmailStatus = In Validation and the validatioEmailDate smaller than today to Expired and delete related Accounts
        //Expected: Obfuscate correct users and deletes related accounts

        //Mock Person Account. Using Framework method to create record due to read-only fields (PersonContactId)
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account mockedAccount = (Account) fflib_ApexMocksUtils.setReadOnlyFields(
            new Account(),
            Account.class,
            new Map<SObjectField, Object>{
                Account.Id => fflib_IDGenerator.generate(Account.SObjectType),
                Account.PersonEmail => 'test@test.com',
                Account.LastName => 'User',
                Account.FirstName => 'Portal',
                Account.RecordTypeId => recTypeInfo.recordtypeid,
                Account.PersonContactId => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Mock Query Result (Account with no Orders)
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ mockedAccount },
            Order.AccountId,
            new List<List<Order>>{ new List<Order>() }
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
                'ContactId' => mockedAccount.PersonContactId,
                'COMM_EmailValidationExpirationDate__c' => DateTime.now().addDays(-2),
                'COMM_EmailValidationStatus__c' => 'In Validation'
            }
        )[0];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserByInValidationExpiredEmail((Boolean) fflib_match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountsAndOrdersByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(accountList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_EmailValidationExpired newBatchRun = new COMM_Async_EmailValidationExpired();
            newBatchRun = new COMM_Async_EmailValidationExpired(USER_REP, ACCOUNT_REP, JOB_EXECUTION_REP, PARAMETER_REP);
            newBatchRun.execute(null, new List<User>());
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isFalse(errorOccured, 'User Obfuscated and Account deleted');
    }
    @isTest
    private static void COMM_Async_EmailValidationExpiredExecuteTestFailed() {
        //Scenario: The Batch tries to Obfuscate the users that have the validationEmailStatus = In Validation and the validatioEmailDate smaller than today to Expired and delete related Accounts
        //Expected: Obfuscate correct users and deletes related accounts

        //Mock Person Account. Using Framework method to create record due to read-only fields (PersonContactId)
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account mockedAccount = (Account) fflib_ApexMocksUtils.setReadOnlyFields(
            new Account(),
            Account.class,
            new Map<SObjectField, Object>{
                Account.Id => fflib_IDGenerator.generate(Account.SObjectType),
                Account.PersonEmail => 'test@test.com',
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
                'ContactId' => mockedAccount.PersonContactId,
                'COMM_EmailValidationExpirationDate__c' => DateTime.now().addDays(-2),
                'COMM_EmailValidationStatus__c' => 'In Validation'
            }
        )[0];
        //Mock expected User Record
        Account accountRecord = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{ 'LastName' => 'Account', 'FirstName' => 'Test' }
        )[0];
        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserByInValidationExpiredEmail((Boolean) fflib_match.anyObject())).thenReturn(new List<User>{ userRecord });
        MOCKS.when(ACCOUNT_REP.getAccountsAndOrdersByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Account>{ accountRecord });
        ((COMM_REP_Account) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error') }, ACCOUNT_REP))
            .deleteSObjects((List<Account>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_EmailValidationExpired newBatchRun = new COMM_Async_EmailValidationExpired();
            newBatchRun = new COMM_Async_EmailValidationExpired(USER_REP, ACCOUNT_REP, JOB_EXECUTION_REP, PARAMETER_REP);
            newBatchRun.execute(null, new List<User>());
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isTrue(errorOccured, 'Account deletion Failed');
    }
}