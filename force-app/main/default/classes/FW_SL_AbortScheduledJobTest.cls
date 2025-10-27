/**
 * @author           Nuno Costa
 * @description      FW_SL_AbortScheduledJob test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Nuno Costa      	01/09/2023      100            US 00000000 - Original version
 **/
@isTest
private class FW_SL_AbortScheduledJobTest {
	@isTest
	static void abortScheduledJobTest() {
		//scenario: This test is mostly for coverage. We do not want to schedule batches from tests 
		//and Job IDs are only returned after the test runs. So it's difficult to abort a job during testing
		Boolean error = false;

		Test.startTest();
		try{
			FW_SL_AbortScheduledJob.execute(new List<String>{'TestId'});
		} catch(exception ex) {
			error = true;
		}
		Test.stopTest();

		Assert.isTrue(error, 'No error was caught');
	}
}