/**
 * @author           Daniel Lascas
 * @description      COMM_TW_CustomerUpdateRequest_CallUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/09/2024      100            Original version
 **/
@isTest
private class COMM_TW_CustomerUpdateReq_CallUpdateTest {
    @isTest
    static void withAccountAndContactUpdateTest() {
        //Scenario: An Account and Contact were updated and are set for Commerce Sync
        //Expected: Sync Logic is executed (queuable is called for each)

        //Generate mocked Platform Event
        COMM_CustomerUpdateRequest__e accountEvent = new COMM_CustomerUpdateRequest__e();
        accountEvent.COMM_AccountId__c = fflib_IDGenerator.generate(Account.sObjectType);
        COMM_CustomerUpdateRequest__e contactEvent = new COMM_CustomerUpdateRequest__e();
        contactEvent.COMM_ContactId__c = fflib_IDGenerator.generate(Contact.sObjectType);

        Test.startTest();
        COMM_TW_CustomerUpdateRequest_CallUpdate worker = new COMM_TW_CustomerUpdateRequest_CallUpdate();
        worker.execute(new List<COMM_CustomerUpdateRequest__e>{ accountEvent, contactEvent });
        Integer queueableCounter = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(2, queueableCounter, 'expected two queueble classes to have been called');
    }

    @isTest
    static void noUpdateTest() {
        //Scenario: Platform Event is called but without the Id of the updated records.
        //Expected: Sync Logic isn't executed (queuable not called).

        //Generate mocked Platform Event
        COMM_CustomerUpdateRequest__e eventRecord = new COMM_CustomerUpdateRequest__e();

        Test.startTest();
        COMM_TW_CustomerUpdateRequest_CallUpdate worker = new COMM_TW_CustomerUpdateRequest_CallUpdate();
        worker.execute(new List<COMM_CustomerUpdateRequest__e>{ eventRecord });
        Integer queueableCounter = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(0, queueableCounter, 'expected no queueble class to have been called');
    }
}