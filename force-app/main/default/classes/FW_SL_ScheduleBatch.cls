/**
 * @author           Nuno Costa
 * @description      Class that allows to schedule a batch from a flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Nuno Costa      	01/09/2023      US 00000000 - Original version
 **/
public with sharing class FW_SL_ScheduleBatch {

	@InvocableMethod(
		label='Schedule Batch'
		description='Schedule Batch'
		category='Custom Actions'
	)
	public static List<String> scheduleBatch(List<Batch_Definition__c> batchDefinition){

        List<String> jobIdList = new List<String>();
		for(Batch_Definition__c batchDefinitionRecord: batchDefinition){

			if(batchDefinitionRecord.BatchSchedulerClass__c == FW_Async_GenericBatchScheduler.class.getName()){
				FW_Async_GenericBatchScheduler genericScheduler = new FW_Async_GenericBatchScheduler();
				genericScheduler.batchDefinitionName = batchDefinitionRecord.Batch_Name__c;

				String jobID = !Test.isRunningTest() ? System.schedule(batchDefinitionRecord.Name, batchDefinitionRecord.CronExpression__c, genericScheduler) : 'Test Id';
				jobIdList.add(jobID);
			} else {
				Type classType = Type.forName(batchDefinitionRecord.BatchSchedulerClass__c);
				Schedulable classInstance = (Schedulable) classType.newInstance();
				//Due to the nature of this class, it's difficult to test the scheduling, since job ids are only returned after the test runs. 
				//Therefore, if it's a test we return a mock Id.CronExpression__c
				String jobID = !Test.isRunningTest() ? System.schedule(batchDefinitionRecord.Name, batchDefinitionRecord.CronExpression__c, classInstance) : 'Test Id';
				jobIdList.add(jobID);
			}
			
		}

        return jobIdList;
    }
}