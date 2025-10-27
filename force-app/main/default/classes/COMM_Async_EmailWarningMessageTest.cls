/**
 * @author Daniel Reto
 * @description COMM_Async_EmailWarningMessage test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      26/04/2024      90          ECOMM-247: Original version
 * Daniel Reto      14/10/2024      98          ECOMM-2354
 **/
@isTest
private class COMM_Async_EmailWarningMessageTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_EmailTemplate EMAILTEMPLATE_REP = (COMM_REP_EmailTemplate) MOCKS.mock(COMM_REP_EmailTemplate.class);
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_iREP_OrgWideEmailAddress ORGWIDEADDRESSNOREPLY_REP = (COMM_REP_OrgWideEmailAddress) MOCKS.mock(COMM_REP_OrgWideEmailAddress.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void executeSuccessManualRenewalTest() {

        Date endDateValue = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Renewal Email Warning Message',
                Class_Name__c = 'COMM_Async_EmailWarningMessage',
                Job_Size__c = 100,
                SObject_API_Name__c = 'Contact'
            )
        };

        //Create Mocked JobExecution Record
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].Id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Create Mocked Parameters Record
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_DAYS_BEFORE_END_OF_MONTH,
                Value__c = '30'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_EMAIL_TEMPLATE_EN,
                Value__c = 'COMM_EndUser_SubscriptionRenewalWarning_en_US'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_RECORD_TYPE,
                Value__c = 'COMM_Partner'
            )
        };

        //User for Mocking Test
        Id userId = fflib_IDGenerator.generate(User.SObjectType);
        List<User> userRecordList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => userId,
                'FirstName' => 'Test',
                'LastName' => 'DR',
                'Email' => 'test@test.com',
                'LanguageLocaleKey' => 'en_US'
            }
        );

        //Contact for Mocking Test
        List<Contact> contactRecordList = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Subscription which must be inserted to run "Messaging.renderStoredEmailTemplate"
        List<COMM_Subscription__c> dummySubscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => false,
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => endDateValue,
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => endDateValue,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_MONTHLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName().get(COMM_DO_Subscription.RECORDTYPE_PARTNER).RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(),12,Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'OwnerId' => UserInfo.getUserId()
            }
        );

        //Subscription for Mocking Test
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => dummySubscriptionRecordList[0].Id,
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => false,
                'COMM_CancellationDate__c' => Date.today(),
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => contactRecordList[0].Id,
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => endDateValue,
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => endDateValue,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_MONTHLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName().get(COMM_DO_Subscription.RECORDTYPE_PARTNER).RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(),12,Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'OwnerId' => UserInfo.getUserId()
            }
        );
        COMM_Subscription__c subscriptionRecord = (COMM_Subscription__c) COMM_TestDataFactory.setField(subscriptionRecordList[0], new Map<String, Object>{ 'CreatedBy' => userRecordList[0] });

        List<Contact> contactList = (List<Contact>) fflib_ApexMocksUtils.makeRelationship(
            List<Contact>.class,
            new List<Contact>{ contactRecordList[0] },
            COMM_Subscription__c.COMM_Contact__c,
            new List<List<COMM_Subscription__c>>{
                    new List<COMM_Subscription__c>{
                        subscriptionRecord
                    }
            }
        );

        //Expected Records for Mocking Test
        List<EmailTemplate> expectedEmailTemplateRecord = [
            SELECT
                Id,
                Name,
                DeveloperName,
                Subject,
                Body
            FROM
                EmailTemplate
            WHERE
                Name = 'COMM_EndUser_SubscriptionRenewalWarning_en_US'
        ];
        List<OrgWideEmailAddress> expectedOrgWideEmailAddressRecord = (List<OrgWideEmailAddress>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'OrgWideEmailAddress',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(OrgWideEmailAddress.SObjectType)
            }
        );
        List<User> userList = [
            SELECT
                Id,
                Email,
                LanguageLocaleKey
            FROM
                User
            WHERE
                Id =: UserInfo.getUserId()
        ];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(EMAILTEMPLATE_REP.getEmailTemplateByNames(new Set<String>{ 'COMM_EndUser_SubscriptionRenewalWarning_en_US' })).thenReturn(expectedEmailTemplateRecord);
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(ORGWIDEADDRESSNOREPLY_REP.getDefaultNoReplyAddress()).thenReturn(expectedOrgWideEmailAddressRecord);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_EmailWarningMessage newBatchRun = new COMM_Async_EmailWarningMessage();
            newBatchRun = new COMM_Async_EmailWarningMessage(
                EMAILTEMPLATE_REP,
                USER_REP,
                ORGWIDEADDRESSNOREPLY_REP,
                JOB_EXECUTION_REP,
                PARAMETERS_REP
            );
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, contactList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

    }
    
    @isTest
    private static void executeSuccessAutomaticRenewalTest() {

        Date endDateValue = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Renewal Email Warning Message',
                Class_Name__c = 'COMM_Async_EmailWarningMessage',
                Job_Size__c = 100,
                SObject_API_Name__c = 'Contact'
            )
        };

        //Create Mocked JobExecution Record
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].Id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Create Mocked Parameters Record
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_DAYS_BEFORE_END_OF_MONTH,
                Value__c = '30'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_EMAIL_TEMPLATE_EN,
                Value__c = 'COMM_EndUser_SubscriptionRenewalWarning_en_US'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_EmailWarningMessage.PARAMETER_RECORD_TYPE,
                Value__c = 'COMM_Partner'
            )
        };

        //User for Mocking Test
        Id userId = fflib_IDGenerator.generate(User.SObjectType);
        List<User> userRecordList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => userId,
                'FirstName' => 'Test',
                'LastName' => 'DR',
                'Email' => 'test@test.com',
                'LanguageLocaleKey' => 'en_US'
            }
        );

        //Contact for Mocking Test
        List<Contact> contactRecordList = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Contact.SObjectType)
            }
        );

        //Subscription which must be inserted to run "Messaging.renderStoredEmailTemplate"
        List<COMM_Subscription__c> dummySubscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => true,
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => endDateValue,
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => endDateValue,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_MONTHLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName().get(COMM_DO_Subscription.RECORDTYPE_PARTNER).RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(),12,Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'OwnerId' => UserInfo.getUserId()
            }
        );

        //Subscription for Mocking Test
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => dummySubscriptionRecordList[0].Id,
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => true,
                'COMM_CancellationDate__c' => Date.today(),
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => contactRecordList[0].Id,
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => endDateValue,
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => endDateValue,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_MONTHLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName().get(COMM_DO_Subscription.RECORDTYPE_PARTNER).RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(),12,Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'OwnerId' => UserInfo.getUserId()
            }
        );
        COMM_Subscription__c subscriptionRecord = (COMM_Subscription__c) COMM_TestDataFactory.setField(subscriptionRecordList[0], new Map<String, Object>{ 'CreatedBy' => userRecordList[0] });

        List<Contact> contactList = (List<Contact>) fflib_ApexMocksUtils.makeRelationship(
            List<Contact>.class,
            new List<Contact>{ contactRecordList[0] },
            COMM_Subscription__c.COMM_Contact__c,
            new List<List<COMM_Subscription__c>>{
                    new List<COMM_Subscription__c>{
                        subscriptionRecord
                    }
            }
        );

        //Expected Records for Mocking Test
        List<EmailTemplate> expectedEmailTemplateRecord = [
            SELECT
                Id,
                Name,
                DeveloperName,
                Subject,
                Body
            FROM
                EmailTemplate
            WHERE
                Name = 'COMM_EndUser_SubscriptionRenewalWarning_en_US'
        ];
        List<OrgWideEmailAddress> expectedOrgWideEmailAddressRecord = (List<OrgWideEmailAddress>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'OrgWideEmailAddress',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(OrgWideEmailAddress.SObjectType)
            }
        );
        List<User> userList = [
            SELECT
                Id,
                Email,
                LanguageLocaleKey
            FROM
                User
            WHERE
                Id =: UserInfo.getUserId()
        ];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(EMAILTEMPLATE_REP.getEmailTemplateByNames(new Set<String>{ 'COMM_EndUser_SubscriptionRenewalWarning_en_US' })).thenReturn(expectedEmailTemplateRecord);
        MOCKS.when(USER_REP.getUsersById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(ORGWIDEADDRESSNOREPLY_REP.getDefaultNoReplyAddress()).thenReturn(expectedOrgWideEmailAddressRecord);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_EmailWarningMessage newBatchRun = new COMM_Async_EmailWarningMessage();
            newBatchRun = new COMM_Async_EmailWarningMessage(
                EMAILTEMPLATE_REP,
                USER_REP,
                ORGWIDEADDRESSNOREPLY_REP,
                JOB_EXECUTION_REP,
                PARAMETERS_REP
            );
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, contactList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

    }
}