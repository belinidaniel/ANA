/**
 * @author Daniel Lascas
 * @description COMM_DO_SAPMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_DO_SAPMappingTest {
    @isTest
    static void mappingTest() {
        //Scenario: Mapping is called to prepare JSON sent to SAP with invoice data
        //Expected: Map with mapped data according to metadata

        //Generate Mocked Invoice and Product
        COMM_SubscriptionInvoice__c testInvoice = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
                'COMM_SubscriptionAmount__c' => 123.00
            }
        )[0];

        testInvoice = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            testInvoice,
            new Map<String, Object>{ 'COMM_SubscriptionAmountWithoutTax__c' => 100, 'COMM_TaxAmount__c' => 23 }
        );

        testInvoice.COMM_SubscriptonProduct__r = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'ProductCode' => 'test_code' }
        )[0];

        Test.startTest();
        Map<String, Object> resultMap = new COMM_DO_SAPMapping().mapJsonFromSObject(testInvoice, new Map<String, Object>(), false);
        Test.stopTest();

        //Verify Result
        Assert.isFalse(resultMap.isEmpty(), 'expected a resulting map with values');
        Assert.areEqual(
            resultMap.get('totalNetAmount'),
            testInvoice.COMM_SubscriptionAmountWithoutTax__c,
            'expected net value to be the same as invoice amount'
        );
        Assert.areEqual(
            resultMap.get('productId'),
            testInvoice.COMM_SubscriptonProduct__r.ProductCode,
            'expected SAP Product Id to be the same as code of invoice\'s product'
        );
    }
}