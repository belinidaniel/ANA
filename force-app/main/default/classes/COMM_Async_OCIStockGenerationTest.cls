/**
 * @author Ruben Rodrigues
 * @description COMM_Async_OCIStockGeneration test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer          Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues    12/03/2024      89             Original version
 * Jose Passos        15/05/2024      89             Update makeData method
 **/
@isTest
private class COMM_Async_OCIStockGenerationTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);
    private final static COMM_IREP_Capacity CAPACITY_REP = (COMM_REP_Capacity) MOCKS.mock(COMM_REP_Capacity.class);

    @TestSetup
    static void makeData() {
        List<Product2> productList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_1',
                'productCode' => 'OPO_P3_economy_1',
                'description' => 'OPO_P3_economy_1',
                'stockKeepingUnit' => 'OPO_P3_economy_1',
                'family' => 'Parking',
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Capacity__c' => 50,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addDays(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(3),
                'COMM_ProcessStatus__c' => 'NOT PROCESSED'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Capacity__c' => 5,
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addDays(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_ProcessStatus__c' => 'PENDING',
                'COMM_ProcessId__c' => '123'
            }
        );
        Product2 product = productList[0];
        product.isActive = true;
        upsert product;
    }

    @isTest
    private static void generateStockBatchExecuteTest() {
        //Scenario: Batch to generate stock records is initiated
        //Expected: Rep to update product records is called and no error occurs

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'AsyncOCIStockGeneration',
                Class_Name__c = 'COMM_Async_OCIStockGeneration',
                Job_Size__c = 1,
                SObject_API_Name__c = 'Product2'
            )
        };

        //Create Mocked JobExecution Record
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Create Mocked Parameters Record
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = COMM_Async_OCIStockGeneration.PARAMETER_PRODLIST)
        };

        List<Product2> productList = [SELECT ProductCode FROM Product2];
        List<COMM_Capacity__c> capacityList = [
            SELECT
                Id,
                COMM_Product__r.ProductCode,
                COMM_CalculatedCapacity__c,
                COMM_ValidFrom__c,
                COMM_ValidTo__c,
                COMM_ProcessId__c,
                COMM_ProcessStatus__c,
                COMM_StatusMessage__c
            FROM COMM_Capacity__c
        ];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SOBJECT_REP.updateSObjects(capacityList)).thenReturn(new List<Database.UpsertResult>());
        //MOCKS.when(PRODUCTLOCATIONSTOCK_REP.upsertSObjects(expectedProductLocationStockRecordList, COMM_ProductLocationStock__c.COMM_ProductLocation__c)).thenReturn(new List<Database.UpsertResult>());
        MOCKS.when(CAPACITY_REP.getCapacityRecordsToProcessByProductCodes((List<String>) fflib_Match.anyList(), (List<String>) fflib_Match.anyList()))
            .thenReturn(capacityList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Boolean errorOccured = false;
        try {
            COMM_Async_OCIStockGeneration newBatchRun = new COMM_Async_OCIStockGeneration();
            newBatchRun = new COMM_Async_OCIStockGeneration(SOBJECT_REP, CAPACITY_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);

            Test.startTest();
            newBatchRun.execute(null, productList);
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        //Verify Results
        /*((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 2)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
         ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 2)).updateSObjects(capacityList);*/
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}