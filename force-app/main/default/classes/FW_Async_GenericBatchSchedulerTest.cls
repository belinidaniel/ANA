/**
 * @author         Nuno Costa
 * @description    FW_Async_GenericBatchScheduler test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * nuno Costa    	01/09/2023      100            US 00000000 - Original version
 **/
@isTest
private class FW_Async_GenericBatchSchedulerTest {
	static fflib_ApexMocks mocks = new fflib_ApexMocks();

	@isTest
	private static void Async_GenericBatchSchedulerExecuteOkTest() {
		FW_IREP_JobExecution jobExecutionRep = (FW_REP_JobExecution) mocks.mock(FW_REP_JobExecution.class);
		FW_IREP_BatchDefinition batchDefRep = (FW_REP_BatchDefinition) mocks.mock(FW_REP_BatchDefinition.class);
		FW_IDO_JobExecution jobExecutionDO = (FW_DO_JobExecution) mocks.mock(FW_DO_JobExecution.class);

		//Create Batch_Definition
		List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
		new Batch_Definition__c(
			Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
			Batch_Name__c = 'CleanJobExecutions',
			Class_Name__c = 'FW_Async_JobExecutionClean',
			Job_Size__c = 200,
			SObject_API_Name__c = 'Job_Execution__c'
		)
		};

		//Create JobExecution
		List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
			new Job_Execution__c(
				Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
				Batch_Definition__c = batchDefinitionList[0].id,
				Run_With_Defaults__c = true,
				Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
			)
		};

		mocks.startStubbing();
		mocks.when(batchDefRep.getBatchDefinitionByNameSet((Set<String>) fflib_match.anyObject())).thenReturn(batchDefinitionList);
		mocks.stopStubbing();

		FW_Async_GenericBatchScheduler scheduleJobExec = new FW_Async_GenericBatchScheduler();
		scheduleJobExec = new FW_Async_GenericBatchScheduler(batchDefRep, jobExecutionRep, jobExecutionDO);
		scheduleJobExec.batchDefinitionName = batchDefinitionList[0].Batch_Name__c;
		scheduleJobExec.execute(null);

		((FW_IREP_BatchDefinition) mocks.verify(batchDefRep, 1)).getBatchDefinitionByNameSet((Set<String>) fflib_match.anyObject());
	}

	@isTest
	private static void Async_GenericBatchSchedulerExecuteNOkTest() {
		FW_IREP_JobExecution jobExecutionRep = (FW_REP_JobExecution) mocks.mock(FW_REP_JobExecution.class);
		FW_IREP_BatchDefinition batchDefRep = (FW_REP_BatchDefinition) mocks.mock(FW_REP_BatchDefinition.class);
		FW_IDO_JobExecution jobExecutionDO = (FW_DO_JobExecution) mocks.mock(FW_DO_JobExecution.class);

		//Create Batch_Definition
		List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>();

		mocks.startStubbing();
		mocks.when(batchDefRep.getBatchDefinitionByNameSet((Set<String>) fflib_match.anyObject())).thenReturn(batchDefinitionList);
		mocks.stopStubbing();

		test.startTest();
		FW_Async_GenericBatchScheduler scheduleJobExec = new FW_Async_GenericBatchScheduler(batchDefRep, jobExecutionRep, jobExecutionDO);
		scheduleJobExec.execute(null);
		Test.stopTest();

		((FW_IREP_BatchDefinition) mocks.verify(batchDefRep, 1)).getBatchDefinitionByNameSet((Set<String>) fflib_match.anyObject());
	}
}