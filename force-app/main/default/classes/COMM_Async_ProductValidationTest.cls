/**
 * @author Ruben Rodrigues
 * @description COMM_Async_ProductValidation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues  11/06/2024      100            Original version
 **/
@isTest
private class COMM_Async_ProductValidationTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static COMM_SL_ProductValidation VALIDATION_SL = (COMM_SL_ProductValidation) MOCKS.mock(COMM_SL_ProductValidation.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    static void testCheckMatching() {
        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Product Validation',
                Class_Name__c = 'COMM_Async_ProductValidation',
                Job_Size__c = 100,
                SObject_API_Name__c = 'Product2'
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
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER)
        };

        // Mock Records:
        List<Product2> productRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0_premium_1',
                'Family' => 'Parking',
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

        List<COMM_ProductSetting__c> productSettingRecordList = (List<COMM_ProductSetting__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ProductSetting__c',
            new Map<String, Object>{
                'Name' => 'Test Setting ProductCode',
                'COMM_FieldName__c' => 'ProductCode',
                'COMM_CoreEssential__c' => true,
                'COMM_CommerceEssential__c' => true,
                'COMM_FieldAPIName__c' => 'ProductCode',
                'COMM_CommerceMappingAttribute__c' => 'Test',
                'COMM_EligibleProductType__c' => 'Parking'
            }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(VALIDATION_SL.verifyReadiness((List<Product2>) fflib_Match.anyList())).thenReturn(productSettingRecordList);
        MOCKS.when(SOBJECT_REP.upsertSObjects((List<COMM_ProductSetting__c>) fflib_Match.anyList(), (SObjectField) fflib_Match.anyObject()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_ProductValidation newBatchRun = new COMM_Async_ProductValidation();
            newBatchRun = new COMM_Async_ProductValidation(SOBJECT_REP, VALIDATION_SL, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, productRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).upsertSObjects((List<SObject>) fflib_Match.anyList(), (SObjectField) fflib_Match.anyObject());
    }
}