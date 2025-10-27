/**
 * @author Daniel Lascas
 * @description COMM_REP_Product2 test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/03/2024      100            Original version
 * Jose Passos      21/03/2024      100            Test COMM_REP_Product2.getProductsByProductCodes
 **/
@isTest
private class COMM_REP_Product2Test {
    @TestSetup
    static void makeData() {
        Time myTime = Time.newInstance(1, 2, 3, 0);
        List<Object> products = new List<Object>();
        Product2 product = new Product2();

        // Insert Card Product
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Card',
                'ProductCode' => 'C',
                'Description' => 'Test Card',
                'IsActive' => true,
                'Family' => 'Card',
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime
            }
        );

        // Insert Park Product 1
        products = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_1',
                'productCode' => 'OPO_P3_economy_1',
                'description' => 'OPO_P3_economy_1',
                'family' => 'Parking',
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );
        product = (Product2) products[0];
        products = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => product.id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'PENDING'
            }
        );
        product.isActive = true;
        upsert product;

        // Insert Park Product 2 (not active)
        products = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0_premium_1',
                'productCode' => 'LIS_P0_premium_1',
                'description' => 'LIS_P0_premium_1',
                'family' => null,
                'isActive' => false,
                'COMM_Airport__c' => 'LIS',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P0',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );

        // Insert Child Product
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Child',
                'ProductCode' => 'C2132',
                'Description' => 'Test Card',
                'IsActive' => true,
                'Family' => 'Card',
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'OPO',
                'COMM_Tax__c' => 'Continent',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_ParentProduct__c' => product.id,
                'COMM_WhereProductAvailable__c' => COMM_DO_Product2.PRODUCT_AVAILABLE_IN_COMMERCE
            }
        );
    }

    @isTest
    static void getActiveProductsByIdsTest() {
        // Retrieve the Product2 record to get its ProductCode for the test
        List<Product2> expectedList = [SELECT Id FROM Product2 WHERE IsActive = TRUE LIMIT 1];

        Test.startTest();
        List<Product2> actualEntries = new COMM_REP_Product2().getActiveProductsByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        // Verify Product
        Assert.areEqual(expectedList[0].Id, actualEntries[0].Id, 'Retrieved Product does not match expected');
    }

    @isTest
    static void getProductsByProductCodesTest() {
        //Scenario: One Product active and one inactive
        //Expected: Only the active product should be returned
        COMM_IREP_Product2 productRep = new COMM_REP_Product2();
        Test.startTest();
        List<String> productCodeList = new List<String>{ 'OPO_P3_economy_1', 'LIS_P0_premium_1' };
        Map<String, Product2> actualList = productRep.getProductsByProductCodes(productCodeList);
        Test.stopTest();
        Assert.areEqual(actualList.size(), 1, 'Only one Active product is expected');
    }

    @isTest
    static void getProductAndCapacitiesByProductCodesTest() {
        // Retrieve the Product2 record to get its ProductCode for the test
        List<Product2> expectedList = [SELECT Id, ProductCode FROM Product2 WHERE IsActive = TRUE LIMIT 1];
        Test.startTest();
        List<Product2> resultList = new COMM_REP_Product2().getProductAndCapacitiesByProductCodes(new Set<String>{ expectedList[0].ProductCode });
        Test.stopTest();

        // Verify Product
        Assert.areEqual(expectedList[0].Id, resultList[0].Id, 'Retrieved Product does not match expected');
    }

    @isTest
    static void getProductWithDynamicFieldsTest() {
        // Retrieve the Product2 record to get its ProductCode for the test
        List<Product2> expectedList = [SELECT Id, Family, COMM_ParentProduct__c, ProductCode FROM Product2 WHERE IsActive = TRUE LIMIT 1];
        Test.startTest();
        List<Product2> resultList = new COMM_REP_Product2().getProductWithDynamicFields(new Set<String>{ 'ProductCode' });
        Test.stopTest();

        // Verify Product
        Assert.areEqual(expectedList[0].Id, resultList[0].Id, 'Retrieved Product does not match expected');
    }

    @isTest
    static void getValidProductAndCapacitiesByIdsTest() {
        // Retrieve Product2 record for the test
        List<Product2> expectedList = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE AND COMM_ValidFrom__c <= TODAY AND COMM_ValidTo__c >= TODAY
            LIMIT 1
        ];
        Test.startTest();
        List<Product2> resultList = new COMM_REP_Product2().getValidProductAndCapacitiesByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        // Verify Product
        Assert.areEqual(expectedList[0].Id, resultList[0].Id, 'Retrieved Product does not match expected');
    }

    @isTest
    static void getProductsByIdsTest() {
        // Retrieve Product2 record for the test
        List<Product2> expectedList = [
            SELECT Id
            FROM Product2
            LIMIT 1
        ];
        Test.startTest();
        List<Product2> resultList = new COMM_REP_Product2().getProductsByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        // Verify Product
        Assert.areEqual(expectedList[0].Id, resultList[0].Id, 'Retrieved Product does not match expected');
    }
}