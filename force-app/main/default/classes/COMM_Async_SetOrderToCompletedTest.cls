/**
 * @author Ruben Rodrigues
 * @description COMM_Async_OCIStockGeneration test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      17/04/2024      93             Original version
 **/
@isTest
private class COMM_Async_SetOrderToCompletedTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @testSetup
    static void setup() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    private static void setOrderSummaryToCompletedTest() {
        //Scenario: Batch to generate stock records is initiated
        //Expected: Rep to update product records is called and no error occurs

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Set Order Summary to Completed',
                Class_Name__c = 'COMM_Async_SetOrderToCompleted',
                Job_Size__c = 200,
                SObject_API_Name__c = 'OrderSummary'
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
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SetOrderToCompleted.PARAMETER_RESERVATION_END_DATE
            )
        };

        List<OrderSummary> orderSummaryList = [
            SELECT id, Status
            FROM OrderSummary
            LIMIT 1
        ];

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
            COMM_Async_SetOrderToCompleted newBatchRun = new COMM_Async_SetOrderToCompleted();
            newBatchRun = new COMM_Async_SetOrderToCompleted(SOBJECT_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);

            Test.startTest();
            newBatchRun.execute(null, orderSummaryList);
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        //Verify Results
        ((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 2)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).updateSObjects(orderSummaryList);
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}