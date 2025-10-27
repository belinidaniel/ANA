/**
 * @author Daniel Lascas
 * @description COMM_WS_SubscriptionManagement test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    19/06/2024      100            Original version
 **/
@isTest
private class COMM_WS_SubscriptionManagementTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_SL_WS_SubscriptionManagement SUB_MANAGEMENT_SL = (COMM_SL_WS_SubscriptionManagement) MOCKS.mock(
        COMM_SL_WS_SubscriptionManagement.class
    );

    @isTest
    static void doPostFailureTest() {
        //Scenario: Callout is made to Post. Call is missing account Id.
        //Expected: Error is returned and a Error Log Record is created.

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{}');
        req.requestURI = '/subscriptions/customer/';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        COMM_WS_SubscriptionManagement.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'expected a 400 error code');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to have been generated');
    }

    @isTest
    static void doPostSuccessTest() {
        //Scenario: Callout is made to Post.
        //Expected: Successfull Response is returned.
        Id testAccountId = fflib_IDGenerator.generate(Account.sObjectType);

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{}');
        req.requestURI = '/subscriptions/customer/' + testAccountId;
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Map<String, Object> mockedResponseMap = new Map<String, Object>{
            'count' => 0,
            'pageSize' => 100,
            'currentPage' => 1,
            'data' => new List<Object>()
        };

        //Mock Service Layer Response
        MOCKS.startStubbing();
        MOCKS.when(SUB_MANAGEMENT_SL.searchSubscriptionList(fflib_Match.anyString(), (Map<String, Object>) fflib_Match.anyObject()))
            .thenReturn(mockedResponseMap);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_WS_SubscriptionManagement worker = new COMM_WS_SubscriptionManagement();
        worker = new COMM_WS_SubscriptionManagement(SUB_MANAGEMENT_SL);
        worker.handleDoPost();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'expected a successfull response');
    }
}