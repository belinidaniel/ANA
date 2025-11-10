/**
 * @author Carlos Fusco
 * @description COMM_SL_GetProductAvailabilityTest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco     28/02/2024          100                 Original version
 * Daniel Reto      02/05/2024          100                 ECOMM-957
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@isTest
private class COMM_SL_GetProductAvailabilityTest {
    @TestSetup
    static void makeData() {
        List<Product2> parentProducts = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0',
                'productCode' => 'LIS_P0',
                'description' => 'LIS_P0',
                'family' => 'Subscription',
                'isActive' => false,
                'COMM_Airport__c' => 'LIS',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P0',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        // Insert Parent Product Capacity
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => parentProducts[0].Id,
                'COMM_IsDefaultCapacity__c' => true,
                'RecordTypeId' => Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        Product2 product = parentProducts[0];
        product.isActive = true;
        upsert product;

        List<Product2> childProducts = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0_premium_1',
                'ProductCode' => 'LIS_P0_premium_1',
                'Description' => 'Subscription Service',
                'IsActive' => true,
                'Family' => 'Subscription',
                'COMM_WhereProductAvailable__c' => 'Subscriptions Portal',
                'COMM_ParentProduct__c' => parentProducts[0].Id,
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'P0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_SubCategory__c' => 'Park',
                'COMM_PaymentType__c' => 'Credit',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );
    }

    @isTest
    static void test() {
        COMM_SL_GetProductPrice.InputWrapper wrapper = new COMM_SL_GetProductPrice.InputWrapper();
        wrapper.airports = 'LIS';
        wrapper.categories = 'Parking';
        wrapper.periodicities = 'Monthly';
        wrapper.subCategories = 'Park';
        wrapper.codes = new List<String>{ 'LIS_P0_premium_1' };
        wrapper.quantities = 5;

        Test.startTest();
        Map<String, Integer> availableProductCodes = COMM_SL_GetProductAvailability.getProductAvailability(
            new List<COMM_SL_GetProductPrice.InputWrapper>{ wrapper }
        );
        Test.stopTest();

        Assert.isFalse(availableProductCodes.isEmpty(), 'Expected a product in the output');
    }
}