/**
 * @author         Miguel Freire
 * @description    COMM_Async_UserCreation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    24/01/2024      100         Original version
 **/
@isTest
private class COMM_Async_UserCreationTest {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution jobExecutionRep = (FW_REP_JobExecution) mocks.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters parameterRep = (FW_REP_Parameters) mocks.mock(FW_REP_Parameters.class);
    private final static FW_IAsync asynHandler = (FW_AsyncHandler) mocks.mock(FW_AsyncHandler.class);
    private final static COMM_REP_Contact CONTACT_REP = (COMM_REP_Contact) MOCKS.mock(COMM_REP_Contact.class);
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_DO_User USER_DO = (COMM_DO_User) MOCKS.mock(COMM_DO_User.class);

    @isTest
    private static void COMM_Async_UserCreationTest() {
        // Initialize framework
        //Create Batch_Definition
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'COMM_Async_UserCreation',
                Class_Name__c = 'COMM_Async_UserCreation',
                Job_Size__c = 200,
                SObject_API_Name__c = 'Contact'
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
        mocks.when(jobExecutionRep.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(jobExecutionRep.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(parameterRep.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        mocks.when(
                USER_DO.instantiateUser(
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject()
                )
            )
            .thenReturn(new User());
        mocks.stopStubbing();

        COMM_Async_UserCreation newBatchRun = new COMM_Async_UserCreation();
        newBatchRun = new COMM_Async_UserCreation(CONTACT_REP, USER_REP, USER_DO, jobExecutionRep, parameterRep);

        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);

        ((FW_IREP_JobExecution) mocks.verify(jobExecutionRep, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_IREP_Parameters) mocks.verify(parameterRep, 1)).getParametersByParentId((Set<Id>) fflib_match.anyObject());
    }
    @isTest
    private static void COMM_Async_UserCreationExecuteTest() {
        //Scenario: The Batch tries to Create a User for each Contact that has de field COMM_MigrationCreateExternalUser = true
        //Expected: Creates Users for correct Contacts

        //Mock Person Contact.
        Contact mockedContact = (Contact) fflib_ApexMocksUtils.setReadOnlyFields(
            new Contact(),
            Contact.class,
            new Map<SObjectField, Object>{
                Contact.Id => fflib_IDGenerator.generate(Contact.SObjectType),
                Contact.Email => 'test@test.com',
                Contact.LastName => 'User',
                Contact.FirstName => 'Portal',
                Contact.COMM_MigrationCreateExternalUser__c => 'TO PROCESS'
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
                'Email' => mockedContact.Email,
                'LastName' => mockedContact.LastName,
                'FirstName' => mockedContact.FirstName,
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType),
                'ContactId' => mockedContact.Id
            }
        )[0];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_DO.instantiateUser(
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject(),
                    (String) fflib_match.anyObject()
                )
            )
            .thenReturn(userRecord);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_UserCreation newBatchRun = new COMM_Async_UserCreation();
            newBatchRun = new COMM_Async_UserCreation(CONTACT_REP, USER_REP, USER_DO, jobExecutionRep, parameterRep);
            newBatchRun.execute(null, new List<Contact>{ mockedContact });
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isFalse(errorOccured, 'Users created successfully');
    }
}