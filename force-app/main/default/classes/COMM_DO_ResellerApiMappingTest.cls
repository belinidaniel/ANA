/**
 * @author Daniel Lascas
 * @description COMM_DO_ResellerApiMapping test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    05/06/2024      82            ECOMM-194: Original version
 **/
@isTest
private class COMM_DO_ResellerApiMappingTest {
    @isTest
    static void mappingTest() {
        //Scenario: Mapping is called to prepare JSON sent to reseller
        //Expected: Map with mapped data according to metadata

        //Generate Mocked Product
        Product2 testProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'ProductCode' => 'test_code' }
        )[0];

        Test.startTest();
        Map<String, Object> resultMap = new COMM_DO_ResellerApiMapping().mapJsonFromSObject(testProduct, new Map<String, Object>());
        Test.stopTest();

        //Verify Result
        Assert.isFalse(resultMap.isEmpty(), 'expected a resulting map with values');
        Assert.areEqual(resultMap.get('productId'), testProduct.ProductCode, 'expected Product SKU to be the same as product\'s code');
    }
}