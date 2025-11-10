/**
 * @author           Daniel Reto
 * @description      COMM_OCI_Utils test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      14/05/2024      100            Original version - ECOMM-281
 **/
@isTest
private class COMM_OCI_UtilsTest {
    @TestSetup
    static void makeData() {
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'ParkProduct',
                'ProductCode' => 'ParkProduct',
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_PARKING,
                'isActive' => false,
                'COMM_Alarmistic__c' => 25,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Product').RecordTypeId
            }
        );

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'SubscriptionProduct',
                'ProductCode' => 'SubscriptionProduct',
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'COMM_SubCategory__c' => 'Park',
                'COMM_Periodicity__c' => 'Monthly',
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

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'ProductWithoutFamily',
                'ProductCode' => 'ProductWithoutFamily',
                'Family' => null,
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
                'COMM_SubCategory__c' => null,
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Product').RecordTypeId
            }
        );
    }

    /**
     * @description Test method of COMM_OCI_Utils.generateProductList
     */
    @isTest
    static void generateProductListTest() {
        Test.startTest();
        List<Product2> productList = [SELECT id, ProductCode FROM Product2 LIMIT 1];
        List<String> fullDayProductsList = new List<String>();
        List<String> firstDayProductsList = new List<String>();
        List<String> lastDayProductsList = new List<String>();
        DateTime startDateTime = DateTime.newInstanceGMT(2024, 1, 1, 0, 0, 0);
        DateTime endDateTime = DateTime.newInstanceGMT(2024, 4, 1, 0, 0, 0);

        for (Product2 product : productList) {
            COMM_OCI_Utils.generateProductList(
                product.ProductCode,
                startDateTime,
                endDateTime,
                firstDayProductsList,
                fullDayProductsList,
                lastDayProductsList
            );
        }
        Test.stopTest();

        Assert.isFalse(firstDayProductsList.size() == 0, 'First Day is empty');
        Assert.isFalse(fullDayProductsList.size() == 0, 'Full Days is empty');
        Assert.isFalse(lastDayProductsList.size() == 0, 'Last Day is empty');
    }

    /**
     * @description Test method of COMM_OCI_Utils.getInventoryAPISetting
     */
    @isTest
    static void getInventoryAPISettingTest() {
        Test.startTest();
        String config = COMM_OCI_Utils.getInventoryAPISetting();
        Test.stopTest();
        Assert.isFalse(config == null, 'INVENTORY_API configuration not found');
    }

    /**
     * @description Test method of COMM_OCI_Utils.groupProductsByCategory
     */
    @isTest
    static void groupProductsByCategoryTest() {
        Map<String, List<String>> productsMap = new Map<String, List<String>>();

        Test.startTest();
        List<Product2> productList = new List<Product2>();
        productList = [
            SELECT Id, ProductCode, Family
            FROM Product2
            WHERE ProductCode = 'ParkProduct'
        ];
        productsMap = COMM_OCI_Utils.groupProductsByCategory(null, productList);
        Assert.isFalse(productsMap.size() == 0, 'Parking productsMap is empty');

        productsMap.clear();
        productList = [
            SELECT Id, ProductCode, Family
            FROM Product2
            WHERE ProductCode = 'SubscriptionProduct'
        ];
        productsMap = COMM_OCI_Utils.groupProductsByCategory(null, productList);
        Assert.isFalse(productsMap.size() == 0, 'Subscription productsMap is empty');

        productsMap.clear();
        productList = [
            SELECT Id, ProductCode, Family
            FROM Product2
            WHERE ProductCode = 'ProductWithoutFamily'
        ];
        try {
            productsMap = COMM_OCI_Utils.groupProductsByCategory(null, productList);
        } catch (Exception e) {
            Assert.isFalse(productsMap.size() != 0, 'productsMap without family is not expected');
        }
        Test.stopTest();
    }

    /**
     * @description Test method of COMM_OCI_Utils.generateLocationList Single Day
     */
    @isTest
    static void generateLocationListSingleDayTest() {
        String family = COMM_OCI_Constants.PRODUCT_FAMILY_PARKING;
        Datetime startDateTime = DateTime.newInstanceGMT(2024, 1, 1, 0, 0, 0);
        Datetime endDateTime = DateTime.newInstanceGMT(2024, 1, 1, 23, 59, 0);
        List<String> firstDayLocationsList = new List<String>();
        List<String> fullDayLocationsList = new List<String>();
        List<String> lastDayLocationsList = new List<String>();

        Test.startTest();
        COMM_OCI_Utils.generateLocationList(family, startDateTime, endDateTime, firstDayLocationsList, fullDayLocationsList, lastDayLocationsList);
        Test.stopTest();

        Assert.isFalse(firstDayLocationsList.size() == 0, 'First Day is empty');
        Assert.isFalse(fullDayLocationsList.size() != 0, 'Full Days is not empty');
        Assert.isFalse(lastDayLocationsList.size() != 0, 'Last Day is not empty');
    }

    /**
     * @description Test method of COMM_OCI_Utils.generateLocationList Multiple Days
     */
    @isTest
    static void generateLocationListMultipleDaysTest() {
        String family = COMM_OCI_Constants.PRODUCT_FAMILY_PARKING;
        Datetime startDateTime = DateTime.newInstanceGMT(2024, 1, 1, 0, 0, 0);
        Datetime endDateTime = DateTime.newInstanceGMT(2024, 1, 6, 23, 59, 0);
        List<String> firstDayLocationsList = new List<String>();
        List<String> fullDayLocationsList = new List<String>();
        List<String> lastDayLocationsList = new List<String>();

        Test.startTest();
        COMM_OCI_Utils.generateLocationList(family, startDateTime, endDateTime, firstDayLocationsList, fullDayLocationsList, lastDayLocationsList);
        Test.stopTest();

        Assert.isFalse(firstDayLocationsList.size() == 0, 'First Day is empty');
        Assert.isFalse(fullDayLocationsList.size() == 0, 'Full Days is empty');
        Assert.isFalse(lastDayLocationsList.size() == 0, 'Last Day is empty');
    }

    /**
     * @description Test method of COMM_OCI_Utils.generateLocationList Multiple Days Subscription
     */
    @isTest
    static void generateLocationSubscriptionTest() {
        String family = COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION;
        Datetime startDateTime = DateTime.newInstanceGMT(2024, 1, 1, 0, 0, 0);
        Datetime endDateTime = DateTime.newInstanceGMT(2024, 1, 6, 23, 59, 0);
        List<String> firstDayLocationsList = new List<String>();
        List<String> fullDayLocationsList = new List<String>();
        List<String> lastDayLocationsList = new List<String>();

        Test.startTest();
        COMM_OCI_Utils.generateLocationList(family, startDateTime, endDateTime, firstDayLocationsList, fullDayLocationsList, lastDayLocationsList);
        Test.stopTest();

        Assert.isFalse(firstDayLocationsList.size() == 0, 'First Day is empty');
        Assert.isFalse(fullDayLocationsList.size() == 0, 'Full Days is empty');
        Assert.isFalse(lastDayLocationsList.size() == 0, 'Last Day is empty');
    }

    /**
     * @description Test method of COMM_OCI_Utils.newGuid
     */
    @isTest
    static void newGuidTest() {
        String guid = COMM_OCI_Utils.newGuid();
        Assert.isFalse(guid == null, 'guid generation failed');
    }

    /**
     * @description Test method of COMM_OCI_Utils.generateProductLocationList to Products with Family different of Subscription
     */
    @isTest
    static void generateProductLocationListTest() {
        
        List<Product2> productList = new List<Product2>();
        productList = [
            SELECT id, ProductCode, Family
            FROM Product2
            WHERE ProductCode = 'ParkProduct'
        ];
        
        String apexRestRequestBodyMock =
            '{' +
            '   "products": [' +
            '       {' +
            '           "startDate": "2024-01-01T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "ParkProduct"' +
            '       }' +
            '   ]' +
            '}';

        COMM_WS_AvailabilityInput inputRequest = COMM_WS_AvailabilityInput.parse(apexRestRequestBodyMock);
        Map<String, List<String>> productDayByLocationMap = new Map<String, List<String>>();

        Test.startTest();
        Map<String, List<String>> productsMap = COMM_OCI_Utils.groupProductsByCategory(null, productList);
        COMM_OCI_Utils.generateProductLocationList('Others', inputRequest, productDayByLocationMap, productsMap);
        Test.stopTest();

        Assert.isFalse(productDayByLocationMap.size() == 0, 'ProductDayByLocationMap is empty');
    }
    
    /**
     * @description Test method of COMM_OCI_Utils.generateProductLocationList to Subscription Products
     */
    @isTest
    static void generateProductLocationSubscriptionListTest() {
        
        List<Product2> productList = new List<Product2>();
        productList = [
            SELECT id, ProductCode, Family
            FROM Product2
            WHERE ProductCode = 'SubscriptionProduct'
        ];
        
        String apexRestRequestBodyMock =
            '{' +
            '   "products": [' +
            '       {' +
            '           "startDate": "2024-01-01T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "SubscriptionProduct"' +
            '       }' +
            '   ]' +
            '}';

        COMM_WS_AvailabilityInput inputRequest = COMM_WS_AvailabilityInput.parse(apexRestRequestBodyMock);
        Map<String, List<String>> productDayByLocationMap = new Map<String, List<String>>();

        Test.startTest();
        Map<String, List<String>> productsMap = COMM_OCI_Utils.groupProductsByCategory(null, productList);
        COMM_OCI_Utils.generateProductLocationList(COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION, inputRequest, productDayByLocationMap, productsMap);
        Test.stopTest();

        Assert.isFalse(productDayByLocationMap.size() == 0, 'ProductDayByLocationMap is empty');
    }
}