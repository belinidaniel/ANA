/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Subscription_AirportUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      100            ECOMM-1602: Original version
 **/
@isTest
private class COMM_TW_Subscription_AirportUpdateTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Product2 PRODUCT_REP = (COMM_REP_Product2) MOCKS.mock(COMM_REP_Product2.class);

    @isTest
    static void updateFieldTest() {
        //Scenario:	Subscription Product was Updated.
        //Expected: Airport Field updated in Subscription

        //Generate mocked Subscription Product
        List<Product2> subProductList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Product2.sObjectType), 'COMM_Airport__c' => 'LIS' }
        );

        //Generate mocked Subscription
        COMM_Subscription__c oldSubscription = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(COMM_Subscription__c.sObjectType), 'COMM_Product__c' => null }
        )[0];

        //Mocked Update where Product is changed
        COMM_Subscription__c newSubscription = oldSubscription.clone(true);
        newSubscription.COMM_Product__c = subProductList[0].Id;

        Map<Id, COMM_Subscription__c> oldSubscriptionMap = new Map<Id, COMM_Subscription__c>{ oldSubscription.Id => oldSubscription };
        List<COMM_Subscription__c> newSubscriptionList = new List<COMM_Subscription__c>{ newSubscription };

        //Mock REP Calls
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(subProductList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Subscription_AirportUpdate worker = new COMM_TW_Subscription_AirportUpdate();
        worker = new COMM_TW_Subscription_AirportUpdate(PRODUCT_REP);
        worker.execute(newSubscriptionList, oldSubscriptionMap);
        Test.stopTest();

        Assert.areEqual(
            subProductList[0].COMM_Airport__c,
            newSubscription.COMM_AirportValue__c,
            'expected subscription to be updated with Product airport'
        );
    }
}