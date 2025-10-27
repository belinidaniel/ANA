/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Product_AirportUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      100            ECOMM-1602: Original version
 **/
@isTest
private class COMM_TW_Product_AirportUpdateTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Subscription SUBSCRIPTION_REP = (COMM_REP_Subscription) MOCKS.mock(COMM_REP_Subscription.class);

    @isTest
    static void updateAirportFieldTest() {
        //Scenario:	Product's Airport field was Updated.
        //Expected: Related Subscription's Aiport Field was set for update.

        //Generate mocked Product
        Product2 oldProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Product2.sObjectType),
                'Family' => COMM_DO_Product2.CATEGORY_SUBSCRIPTION,
                'COMM_Airport__c' => 'LIS'
            }
        )[0];

        //Mocked Update where Airport is changed
        Product2 newProduct = oldProduct.clone(true);
        newProduct.COMM_Airport__c = 'OPO';

        //Generate mocked Subscription
        List<COMM_Subscription__c> subscriptionList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(COMM_Subscription__c.sObjectType),
                'COMM_Product__c' => oldProduct.Id,
                'COMM_AirportValue__c' => oldProduct.COMM_Airport__c
            }
        );

        Map<Id, Product2> oldProductMap = new Map<Id, Product2>{ oldProduct.Id => oldProduct };
        List<Product2> newProductList = new List<Product2>{ newProduct };

        //Mock REP Calls
        MOCKS.startStubbing();
        MOCKS.when(SUBSCRIPTION_REP.getSubscriptionsByProductIds((Set<Id>) fflib_Match.anyObject())).thenReturn(subscriptionList);
        MOCKS.when(SUBSCRIPTION_REP.updateSObjects((List<COMM_Subscription__c>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Product_AirportUpdate worker = new COMM_TW_Product_AirportUpdate();
        worker = new COMM_TW_Product_AirportUpdate(SUBSCRIPTION_REP);
        worker.execute(newProductList, oldProductMap);
        Test.stopTest();

        ((COMM_IREP_Subscription) mocks.verify(SUBSCRIPTION_REP, 1)).updateSObjects(subscriptionList);
        Assert.areEqual(
            newProduct.COMM_Airport__c,
            subscriptionList[0].COMM_AirportValue__c,
            'expected subscription to be updated with Product airport'
        );
    }
}