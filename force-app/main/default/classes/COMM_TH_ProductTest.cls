/**
 * @author Carlos Fusco
 * @description COMM_TH_Product test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/02/2024           100                 Original version
 **/
@isTest
public with sharing class COMM_TH_ProductTest {
    private final static String PRODUCT_AVAILABLE_IN_COMMERCE = 'eCommerce';

    @isTest
    static void insertTest() {
        List<Product2> products = (List<Product2>) COMM_TestDataFactory.insertRecords(
            10,
            false,
            'Product2',
            new Map<String, Object>{
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'COMM_Airport__c' => 'LIS',
                'isActive' => false,
                'COMM_WhereProductAvailable__c' => PRODUCT_AVAILABLE_IN_COMMERCE,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_Tax__c' => 'Continent',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        Integer count = 0;

        for (Product2 product : products) {
            product.Name = 'P' + count + '-Lisboa';
            product.ProductCode = 'P' + count + '-Lisboa';
            product.Description = 'P' + count + '-Lisboa';
            count++;
        }

        Test.startTest();
        insert products;
        Test.stopTest();

        Integer insertedProducts = [SELECT COUNT() FROM Product2 WHERE Id IN :(new Map<Id, Product2>(products)).keySet()];

        Assert.areEqual(10, insertedProducts, 'capacity record was not inserted');
    }

    @isTest
    static void updateTest() {
        List<Product2> products = (List<Product2>) COMM_TestDataFactory.insertRecords(
            10,
            false,
            'Product2',
            new Map<String, Object>{
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'COMM_Airport__c' => 'LIS',
                'isActive' => false,
                'COMM_WhereProductAvailable__c' => PRODUCT_AVAILABLE_IN_COMMERCE,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_Tax__c' => 'Continent',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        Integer count = 0;

        for (Product2 product : products) {
            product.Name = 'P' + count + '-Lisboa';
            product.ProductCode = 'P' + count + '-Lisboa';
            product.Description = 'P' + count + '-Lisboa';
            count++;
        }

        insert products;

        Test.startTest();
        List<Product2> productsToUpdate = [SELECT Id, COMM_ValidTo__c FROM Product2 WHERE Id IN :(new Map<Id, Product2>(products)).keySet()];
        for (Product2 product : productsToUpdate) {
            product.COMM_ValidTo__c = product.COMM_ValidTo__c.addDays(1);
        }
        update productsToUpdate;
        Test.stopTest();

        Integer updatedProducts = [SELECT COUNT() FROM Product2 WHERE COMM_ValidTo__c = NEXT_N_DAYS:3];
        List<Product2> updatedProducts2 = [SELECT COMM_ValidTo__c FROM Product2];

        Assert.areEqual(10, updatedProducts, 'capacity record was not inserted');
    }
}