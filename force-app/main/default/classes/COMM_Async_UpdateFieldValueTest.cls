/**
 * @author           Daniel Lascas
 * @description      COMM_Async_UpdateFieldValue test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/04/2024      100            ECOMM-305: Original version
 **/
@isTest
private class COMM_Async_UpdateFieldValueTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void fieldUpdateBatchExecuteTest() {
        //Scenario: Batch to update Reseller Assortment Current Daily Limit to zero is initiated
        //Expected: Rep to update records is called and no error occurs

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'AsyncResetResellerDailyLimit',
                Class_Name__c = 'COMM_Async_UpdateFieldValue',
                Job_Size__c = 200,
                SObject_API_Name__c = 'COMM_ResellerAssortment__c'
            )
        };

        //List of COMM_ResellerAssortment__c for Mocking Test
        List<SObject> resellerList = new List<SObject>{
            new COMM_ResellerAssortment__c(Id = fflib_IDGenerator.generate(COMM_ResellerAssortment__c.SObjectType), COMM_CurrentDailyQuantity__c = 10)
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
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_UpdateFieldValue.PARAMETER_OBJECT_NAME,
                Value__c = 'COMM_ResellerAssortment__c'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_UpdateFieldValue.PARAMETER_FIELD_NAME,
                Value__c = 'COMM_CurrentDailyQuantity__c'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_UpdateFieldValue.PARAMETER_UPDATED_VALUE,
                Value__c = '0'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_UpdateFieldValue.PARAMETER_WHERE_CLAUSE,
                Value__c = 'COMM_CurrentDailyQuantity__c > 0'
            )
        };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(SOBJECT_REP.updateSObjects((List<SObject>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        COMM_Async_UpdateFieldValue newBatchRun = new COMM_Async_UpdateFieldValue();
        newBatchRun = new COMM_Async_UpdateFieldValue(SOBJECT_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);
        newBatchRun.execute(null, resellerList);

        //Verify Results
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).updateSObjects(resellerList);
        Assert.areEqual(0, resellerList[0].get('COMM_CurrentDailyQuantity__c'), 'expected daily limit to reset');
    }
}