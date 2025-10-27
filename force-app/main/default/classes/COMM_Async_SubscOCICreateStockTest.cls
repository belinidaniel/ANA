/**
 * @author Daniel Reto
 * @description COMM_Async_SubscOCICreateStock test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)     Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/05/2024      100             Original version
 * Daniel Reto      06/06/2024      100             Hotfix
 **/
@isTest
private class COMM_Async_SubscOCICreateStockTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Capacity CAPACITY_REP = (COMM_REP_Capacity) MOCKS.mock(COMM_REP_Capacity.class);
    private final static COMM_IREP_Subscription SUBSCRIPTION_REP = (COMM_REP_Subscription) MOCKS.mock(COMM_REP_Subscription.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void executeSuccessTest() {
        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Subscription Create Stock On New Environment',
                Class_Name__c = 'COMM_Async_SubscOCICreateStock',
                Job_Size__c = 100,
                SObject_API_Name__c = 'COMM_Subscription__c'
            )
        };

        //Products for Mocking Test
        Id parentProductId = fflib_IDGenerator.generate(Product2.SObjectType);
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

        //Subscription for Mocking Test
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.SObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => false,
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => fflib_IDGenerator.generate(Contact.SObjectType),
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => Date.today().addDays(-1),
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => childProductId,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
                    .get(COMM_DO_Subscription.RECORDTYPE_PARTNER)
                    .RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(), 12, Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'COMM_SetupInitialStock__c' => 'TO PROCESS'
            }
        );
        subscriptionRecordList[0].COMM_Product__r = productRecordList[0];

        //Capacity for Mocking Test
        List<COMM_Capacity__c> capacityRecordList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => parentProductId,
                'COMM_ValidFrom__c' => Datetime.now(),
                'COMM_ValidTo__c' => subscriptionRecordList[0].COMM_EndDate__c.addYears(1),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'COMPLETED'
            }
        );
        capacityRecordList[0].COMM_Product__r = parentProductRecordList[0];

        //Parent Product for Mocking Test
        Set<String> parentProductIdSet = new Set<String>{ subscriptionRecordList[0].COMM_Product__r.COMM_ParentProduct__c };

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
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER)
        };

        // Expected Values
        List<COMM_Subscription__c> expectedSubscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.SObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => false,
                'COMM_AutomaticRenewal__c' => false,
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => fflib_IDGenerator.generate(Contact.SObjectType),
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => Date.today().addDays(-1),
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => childProductId,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
                    .get(COMM_DO_Subscription.RECORDTYPE_PARTNER)
                    .RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(), 12, Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_ARCHIEVED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321',
                'COMM_SetupInitialStock__c' => 'PROCESSED',
                'COMM_OCIEndDate__c' => subscriptionRecordList[0].COMM_EndDate__c.addYears(1)
            }
        );
        expectedSubscriptionRecordList[0].COMM_Product__r = productRecordList[0];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(CAPACITY_REP.getCapacityByProductIds(parentProductIdSet)).thenReturn(capacityRecordList);
        MOCKS.when(SUBSCRIPTION_REP.updateSObjects(expectedSubscriptionRecordList)).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_SubscOCICreateStock newBatchRun = new COMM_Async_SubscOCICreateStock();
            newBatchRun = new COMM_Async_SubscOCICreateStock(CAPACITY_REP, SUBSCRIPTION_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, subscriptionRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1)).getCapacityByProductIds(parentProductIdSet);
    }
}