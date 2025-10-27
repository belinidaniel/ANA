/**
 * @author Daniel Lascas
 * @description COMM_DO_SubscriptionManagementMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    19/06/2024      100            Original version
 **/
@isTest
private class COMM_DO_SubscriptionManagementMapTest {
    @isTest
    static void mappingTest() {
        //Create mocked Product and Subscription
        Product2 testProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'ProductCode' => 'ALS-10' }
        )[0];

        COMM_Subscription__c testSubscription = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType),
                'COMM_Active__c' => true,
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_Price__c' => 100,
                'COMM_SubscriptionNumber__c' => '522200'
            }
        )[0];
        testSubscription.COMM_Product__r = testProduct;

        Map<String, Object> testMap = new Map<String, Object>();

        Test.startTest();
        new COMM_DO_SubscriptionManagementMapping().mapJsonFromSObject(testSubscription, testMap);
        Test.stopTest();

        Assert.isFalse(testMap.isEmpty(), 'expected map to have been updated with mapped values');
    }
}