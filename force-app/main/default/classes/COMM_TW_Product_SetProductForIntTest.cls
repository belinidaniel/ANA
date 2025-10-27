/**
 * @author Carlos Fusco
 * @description COMM_TW_Product_SetProductForIntegration test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/02/2024           100                 Original version
 **/
@isTest
public with sharing class COMM_TW_Product_SetProductForIntTest {
    private final static String PRODUCT_AVAILABLE_IN_COMMERCE = 'eCommerce';

    @isTest
    static void setProductForIntegrationOnCreateTest() {
        Product2 newProduct = new Product2();
        newProduct.Id = fflib_IDGenerator.generate(Product2.sobjectType);
        newProduct.isActive = true;
        newProduct.COMM_WhereProductAvailable__c = PRODUCT_AVAILABLE_IN_COMMERCE;
        newProduct.Name = 'Low Cost Parking';
        newProduct.ProductCode = 'PARK-LC-00001';

        Test.startTest();
        COMM_TW_Product_SetProductForIntegration worker = new COMM_TW_Product_SetProductForIntegration();
        worker.execute(new List<Product2>{ newProduct }, null);
        Test.stopTest();

        Assert.areNotEqual(null, newProduct.COMM_IntegrationRequestBody__c);
        Assert.areEqual(
            newProduct.ProductCode,
            (String) ((Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c)).get('id')
        );
        Assert.areEqual(
            newProduct.Name,
            (String) ((Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c)).get('name')
        );
    }

    @isTest
    static void setProductForIntegrationOnUpdateTest() {
        Map<String, Object> integrationRequestBody = new Map<String, Object>{ 'id' => 'PARK-LC-00001', 'name' => 'Low Cost Parking' };

        Product2 oldProduct = new Product2();
        oldProduct.Id = fflib_IDGenerator.generate(Product2.sobjectType);
        oldProduct.isActive = true;
        oldProduct.COMM_WhereProductAvailable__c = PRODUCT_AVAILABLE_IN_COMMERCE;
        oldProduct.Name = 'Low Cost Parking';
        oldProduct.ProductCode = 'PARK-LC-00001';
        oldProduct.COMM_IntegrationRequestBody__c = JSON.serialize(integrationRequestBody);

        Product2 newProduct = oldProduct.clone(true);
        newProduct.COMM_Park__c = 'P4';

        Test.startTest();
        COMM_TW_Product_SetProductForIntegration worker = new COMM_TW_Product_SetProductForIntegration();
        worker.execute(new List<Product2>{ newProduct }, new Map<Id, Product2>{ oldProduct.Id => oldProduct });
        Test.stopTest();

        Assert.areNotEqual(null, newProduct.COMM_IntegrationRequestBody__c);
        Assert.areEqual(
            newProduct.ProductCode,
            (String) ((Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c)).get('id')
        );
        Assert.areEqual(
            newProduct.Name,
            (String) ((Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c)).get('name')
        );
        Assert.areEqual(
            newProduct.COMM_Park__c,
            (String) ((Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c)).get('brand')
        );
    }
}