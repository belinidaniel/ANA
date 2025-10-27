/**
 * @author           Jose Passos
 * @description      COMM_WS_OCIReservations test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 * Jose Passos      26/02/2024      71             Updated after changing the service to getPrice
 * Jose Passos      26/02/2024      71             Updated makeData
 * Jose Passos      24/05/2024      71             ECOMM-1191 - change reservation request to have a new actionRequestID per product to create the reservations
-1191
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_WS_OCIReservationsTest {
    private static String reservationId = 'ResID_' + DateTime.now().formatGMT('yyyyMMddHHmmss');
    private static String dateTimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss';

    @TestSetup
    static void makeData() {
        Product2 parkingProduct;
        Product2 loungeProduct;

        // Update standard Pricebook with the required custom fields
        Id standardPriceBookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPriceBookId,
            IsActive = true,
            Type__c = 'Public',
            COMM_ValidFrom__c = DateTime.newInstance(DateTime.now().Year(), 1, 1, 0, 0, 0),
            COMM_ValidTo__c = DateTime.newInstance(DateTime.now().year(), 12, 31, 23, 59, 59)
        );
        update standardPricebook;

        // Create product 1
        List<Product2> products = (List<Product2>) COMM_TestDataFactory.insertRecords(
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
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => products[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );
        parkingProduct = (Product2) products[0];
        parkingProduct.isActive = true;
        upsert parkingProduct;

        // Insert PricebookEntry for Standard Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => standardPriceBookId,
                'Product2Id' => parkingProduct.Id,
                'UnitPrice' => 0,
                'IsActive' => true,
                'COMM_First15MinuteUnit__c' => 1,
                'COMM_Second15MinuteUnit__c' => 1,
                'COMM_Third15MinuteUnit__c' => 1,
                'COMM_Remaining15MinuteUnit__c' => 1,
                'COMM_FirstPeriodStartDay__c' => 1,
                'COMM_FirstPeriodEndDay__c' => 366,
                'COMM_FirstPeriodDailyMaximum__c' => 1
            }
        );

        // Create product 2
        products = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0_premium_1',
                'productCode' => 'LIS_P0_premium_1',
                'description' => 'LIS_P0_premium_1',
                'family' => 'Parking',
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
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => products[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );
        parkingProduct = (Product2) products[0];
        parkingProduct.isActive = true;
        upsert parkingProduct;

        // Insert PricebookEntry for Standard Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => standardPriceBookId,
                'Product2Id' => parkingProduct.Id,
                'UnitPrice' => 0,
                'IsActive' => true,
                'COMM_First15MinuteUnit__c' => 1,
                'COMM_Second15MinuteUnit__c' => 1,
                'COMM_Third15MinuteUnit__c' => 1,
                'COMM_Remaining15MinuteUnit__c' => 1,
                'COMM_FirstPeriodStartDay__c' => 1,
                'COMM_FirstPeriodEndDay__c' => 366,
                'COMM_FirstPeriodDailyMaximum__c' => 1
            }
        );

        // Create product 3 with child product 4
        products = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_lounge_1',
                'productCode' => 'OPO_lounge_1',
                'description' => 'OPO_lounge_1',
                'family' => 'Lounge',
                'COMM_SubCategory__c' => 'Lounge',
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => null,
                'COMM_Park__c' => null,
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => products[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );
        loungeProduct = (Product2) products[0];
        loungeProduct.isActive = true;
        upsert loungeProduct;

        products = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_lounge_kids_1',
                'productCode' => 'OPO_lounge_kids_1',
                'description' => 'OPO_lounge_kids_1',
                'COMM_SubCategory__c' => 'Lounge Child',
                'COMM_ParentProduct__c' => loungeProduct.id,
                'COMM_WhereProductAvailable__c' => 'eCommerce',
                'family' => 'Lounge',
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => null,
                'COMM_Park__c' => null,
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );
        loungeProduct = (Product2) products[0];
        loungeProduct.isActive = true;
        upsert loungeProduct;
        // Insert PricebookEntry for Standard Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{ 'Pricebook2Id' => standardPriceBookId, 'Product2Id' => loungeProduct.Id, 'UnitPrice' => 10, 'IsActive' => true }
        );
    }

    @IsTest
    static void reserveSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "LIS_P0_premium_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(3).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.reserve();
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(201, RestContext.response.statusCode, 'Expected a 201 HTTP status code.');
    }

    @IsTest
    static void reserveWrongDatesTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(-1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.reserve();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected a 400 HTTP status code due to invalid input.');
    }

    @IsTest
    static void reserveUnexistingProductTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "productId": "UnexistingProduct",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.reserve();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected a 400 HTTP status code due to invalid input.');
    }

    @IsTest
    static void releaseSuccessResponseTest() {
        String apexRestRequestBodyMock =
            //generate string with below json format as apex rest request body
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "LIS_P0_premium_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'DELETE'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.release();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(201, RestContext.response.statusCode, 'Expected a 201 HTTP status code.');
    }

    @IsTest
    static void releaseUnexistingProductTest() {
        String apexRestRequestBodyMock =
            //generate string with below json format as apex rest request body
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "product": [' +
            '        {' +
            '            "productId": "UnexistingProduct",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "LIS_P0_premium_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'DELETE'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.release();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected a 400 HTTP status code due to invalid input.');
    }

    @IsTest
    static void extendSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "extend": true,' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "productId": "LIS_P0_premium_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(3).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'PATCH'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.revertPermanentReservation();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(200, RestContext.response.statusCode, 'Expected a 200 HTTP status code due to invalid input.');
    }

    @IsTest
    static void extendUnexistingProductTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "extend": true,' +
            '    "product": [' +
            '        {' +
            '            "productId": "UnexistingProduct",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/oci/reserve/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'PATCH'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIReservations.revertPermanentReservation();
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected a 400 HTTP status code due to invalid input.');
    }
}