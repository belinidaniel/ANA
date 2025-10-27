/**
 * @author Daniel Lascas
 * @description COMM_Async_SetExpiredToInactive test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    19/02/2024      100            Original version
 **/
@isTest
private class COMM_Async_SetExpiredToInactiveTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void updateRecordsBatchExecuteTest() {
        //Scenario: Batch to update expired Product records is initiated
        //Expected: Rep to update product records is called and no error occurs

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'AsyncSetExpiredCapacityToInactive',
                Class_Name__c = 'COMM_Async_SetExpiredToInactive',
                Job_Size__c = 200,
                SObject_API_Name__c = 'Product2'
            )
        };

        //List of Product2 for Mocking Test
        List<SObject> productList = new List<SObject>{ new Product2(Id = fflib_IDGenerator.generate(Product2.SObjectType)) };

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
                Name = COMM_Async_SetExpiredToInactive.PARAMETER_ACTIVEFIELD,
                Value__c = 'IsActive'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SetExpiredToInactive.PARAMETER_OBJECT_NAME,
                Value__c = 'Product2'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SetExpiredToInactive.PARAMETER_DATEFIELD,
                Value__c = 'COMM_ValidTo__c'
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
        Boolean errorOccured = false;
        try {
            COMM_Async_SetExpiredToInactive newBatchRun = new COMM_Async_SetExpiredToInactive();
            newBatchRun = new COMM_Async_SetExpiredToInactive(SOBJECT_REP, JOB_EXECUTION_REP, PARAMETERS_REP);

            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, productList);
        } catch (Exception e) {
            errorOccured = true;
        }

        //Verify Results
        ((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).updateSObjects(productList);
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}