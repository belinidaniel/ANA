/**
 * @author Carlos Fusco
 * @description COMM_Async_CleanupCaseRecords test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer             Date            Coverage(%)         Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco        26/04/2024           100             Original version
 **/
@isTest
private class COMM_Async_CleanupCaseRecordsTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    private static void deleteCaseRecordsBatchExecuteTest() {
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'AsyncCleanupCompletedCaseContactUsRecords',
                Class_Name__c = 'COMM_Async_CleanupCaseRecords',
                Job_Size__c = 200,
                SObject_API_Name__c = 'Case'
            )
        };

        List<SObject> caseList = new List<SObject>{ new Case() };

        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_DATEFIELD,
                Value__c = 'CreatedDate'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_OPERATOR,
                Value__c = '<='
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_MONTHS_AGO,
                Value__c = '12'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_RECORD_TYPE,
                Value__c = 'COMM_ContactUs'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_STATUS,
                Value__c = 'Process Concluded'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CleanupCaseRecords.PARAMETER_ORIGIN,
                Value__c = 'Web'
            )
        };

        MOCKS.startStubbing();
        MOCKS.when(SOBJECT_REP.deleteSObjects((List<SObject>) fflib_Match.anyList())).thenReturn(new List<Database.DeleteResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;
        try {
            COMM_Async_CleanupCaseRecords newBatchRun = new COMM_Async_CleanupCaseRecords();
            newBatchRun = new COMM_Async_CleanupCaseRecords(SOBJECT_REP, JOB_EXECUTION_REP, PARAMETERS_REP);

            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, caseList);
        } catch (Exception e) {
            errorOccured = true;
        }

        ((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).deleteSObjects(caseList);
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}