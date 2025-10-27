/**
 * @author           Nuno Costa
 * @description      FW_SL_ScheduleBatch test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Nuno Costa      	01/09/2023      100            US 00000000 - Original version
 **/
@isTest
private class FW_SL_ScheduleBatchTest {
	@isTest
	static void scheduleBatchTest() {
		//scenario: This test is mostly for coverage. We do not want to schedule batches from tests 
		//and Job IDs are only returned after the test runs
		Batch_Definition__c batchDefinition = new Batch_Definition__c();
		batchDefinition.Batch_Name__c = 'CleanJobExecutions';
		batchDefinition.Class_Name__c = 'FW_Async_JobExecutionClean'; //Class that implements "Schedulable" framework
		batchDefinition.CronExpression__c = '0 0 12 ? * * *';
		batchDefinition.BatchSchedulerClass__c = 'FW_Async_JobExecutionCleanSchedule';

		Boolean error = false;
		String errorMessage = '';
		List<String> resultList = new List<String>();
		Test.startTest();
		try{
			resultList = FW_SL_ScheduleBatch.scheduleBatch(new List<Batch_Definition__c> {batchDefinition});
		} catch(exception ex) {
			error = true;
			errorMessage = ex.getMessage();
		}
		Test.stopTest();

		Assert.isFalse(error, 'An error was found: ' + errorMessage);
		Assert.isTrue(!resultList.isEmpty(), 'No id was returned');
	}

	@isTest
	static void scheduleGenericBatchTest() {
		//scenario: This test is mostly for coverage. We do not want to schedule batches from tests 
		//and Job IDs are only returned after the test runs
		Batch_Definition__c batchDefinition = new Batch_Definition__c();
		batchDefinition.Batch_Name__c = 'CleanJobExecutions';
		batchDefinition.Class_Name__c = 'FW_Async_JobExecutionClean'; //Class that implements "Schedulable" framework
		batchDefinition.CronExpression__c = '0 0 12 ? * * *';
		batchDefinition.BatchSchedulerClass__c = 'FW_Async_GenericBatchScheduler';

		Boolean error = false;
		String errorMessage = '';
		List<String> resultList = new List<String>();
		Test.startTest();
		try{
			resultList = FW_SL_ScheduleBatch.scheduleBatch(new List<Batch_Definition__c> {batchDefinition});
		} catch(exception ex) {
			error = true;
			errorMessage = ex.getMessage();
		}
		Test.stopTest();

		Assert.isFalse(error, 'An error was found: ' + errorMessage);
		Assert.isTrue(!resultList.isEmpty(), 'No id was returned');
	}
}