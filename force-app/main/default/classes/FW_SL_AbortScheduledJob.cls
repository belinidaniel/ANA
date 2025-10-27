/**
 * @author           Nuno Costa
 * @description      Class that allows to abort a schedule from a flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Nuno Costa      	01/09/2023      US 00000000 - Original version
 **/
public with sharing class FW_SL_AbortScheduledJob {

	@InvocableMethod(
		label='Abort Schedule Batch'
		description='Abort Schedule Batch'
		category='Custom Actions'
	)
	public static void execute(List<String> crontriggerIdList){
		for(String crontriggerId: crontriggerIdList){
			System.abortJob(crontriggerId);
		}
    }
}