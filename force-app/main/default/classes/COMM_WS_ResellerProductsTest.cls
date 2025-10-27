/**
 * @author Daniel Lascas
 * @description COMM_WS_ResellerProducts test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    06/06/2024      100            ECOMM-386: First Implementation
 **/
@isTest
private class COMM_WS_ResellerProductsTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_SL_WS_ResellerProducts GET_PRODUCTS_SL = (COMM_SL_WS_ResellerProducts) MOCKS.mock(COMM_SL_WS_ResellerProducts.class);

    @isTest
    static void noResellerTest() {
        //Scenario: Request is received but there is no reseller available
        //Expected: Error Response is returned

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"resellerId":"testId"}');
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        COMM_WS_ResellerProducts.doPost();
        Test.stopTest();

        Assert.areEqual(400, res.statusCode, 'expected a 400 error code');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to have been generated');
    }

    @isTest
    static void getProductsTest() {
        //Scenario: Request is received for a registered reseller
        //Expected: Response is returned

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"resellerId":"existingId"}');
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        //Mock expected response
        COMM_SL_WS_ResellerSearchResponse mockedResponse = new COMM_SL_WS_ResellerSearchResponse();

        //Mock SL Call
        MOCKS.startStubbing();
        MOCKS.when(GET_PRODUCTS_SL.getResellerStock(fflib_Match.anyString())).thenReturn(mockedResponse);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_WS_ResellerProducts worker = new COMM_WS_ResellerProducts();
        worker = new COMM_WS_ResellerProducts(GET_PRODUCTS_SL);
        worker.processRequest();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'expected a 200 success code');
    }
}