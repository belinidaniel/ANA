/**
 * @author Daniel Reto
 * @description COMM_Async_CapacityEndDateExtension test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      16/04/2024      ECOMM-204: Original version
 **/
@isTest
private class COMM_Async_CapacityEndDateExtensionTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Subscription SUBSCRIPTION_REP = (COMM_REP_Subscription) MOCKS.mock(COMM_REP_Subscription.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void executeSuccessTest() {

        Date endDateValue = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Capacity End Date OCI Extension',
                Class_Name__c = 'COMM_Async_CapacityEndDateExtension',
                Job_Size__c = 100,
                SObject_API_Name__c = 'COMM_Capacity__c'
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
                Name = COMM_Async_CapacityEndDateExtension.PARAMETER_MINUTE_EXECUTE_SINCE,
                Value__c = '0'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CapacityEndDateExtension.PARAMETER_HOUR_EXECUTE_SINCE,
                Value__c = '0'
            )
        };

        //Products for Mocking Test
        Id parentProductId = fflib_IDGenerator.generate(Product2.SObjectType);
        List<Product2> parentProductRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => parentProductId,
                'ProductCode' => 'T-0',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );
        Id childProductId = fflib_IDGenerator.generate(Product2.SObjectType);
        List<Product2> productRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => childProductId,
                'COMM_ParentProduct__c' => parentProductId,
                'ProductCode' => 'T-0-12',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        //Capacity for Mocking Test
        List<COMM_Capacity__c> capacityRecordList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Capacity__c.SObjectType),
                'COMM_Product__c' => parentProductId,
                'RecordTypeId' => Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId,
                'COMM_ValidTo__c' => endDateValue.addYears(1),
                'COMM_Capacity__c' => 150
            }
        );
        capacityRecordList[0].COMM_Product__r = parentProductRecordList[0];

        //Subscription for Mocking Test
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.SObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => true,
                'COMM_CancellationDate__c' => Date.today(),
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => fflib_IDGenerator.generate(Contact.SObjectType),
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => endDateValue,
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => endDateValue,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_YEARLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => childProductId,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName().get(COMM_DO_Subscription.RECORDTYPE_PARTNER).RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(),12,Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321'
            }
        );
        subscriptionRecordList[0].COMM_Product__r = productRecordList[0];

        //Expected Subscription for Mocking Test
        List<COMM_Subscription__c> expectedSubscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => subscriptionRecordList[0].Id,
                'COMM_OCIEndDate__c' => endDateValue.addYears(1)
            }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SUBSCRIPTION_REP.getSubscriptionsByParentProductIds(new Set<String>{ parentProductId })).thenReturn(subscriptionRecordList);
        MOCKS.when(SUBSCRIPTION_REP.updateSObjects(expectedSubscriptionRecordList)).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_CapacityEndDateExtension newBatchRun = new COMM_Async_CapacityEndDateExtension();
            newBatchRun = new COMM_Async_CapacityEndDateExtension(
                SUBSCRIPTION_REP,
                JOB_EXECUTION_REP,
                PARAMETERS_REP
            );
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, subscriptionRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

    }
}