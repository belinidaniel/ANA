/**
 * @author           Jose Passos
 * @description      COMM_WS_OCIAvailability test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 * Jose Passos      15/05/2024      100            Updated method makeData
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_WS_OCIAvailabilityTest {
    @TestSetup
    static void makeData() {
        List<Product2> productList = (List<Product2>) COMM_TestDataFactory.insertRecords(
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
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );

        Product2 product = productList[0];
        product.isActive = true;
        upsert product;

        productList = (List<Product2>) COMM_TestDataFactory.insertRecords(
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
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );

        product = productList[0];
        product.isActive = true;
        upsert product;
    }

    @IsTest
    static void getAvailableSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '   "products": [' +
            '       {' +
            '           "startDate": "2024-01-01T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "OPO_P3_economy_1"' +
            '       },' +
            '       {' +
            '           "startDate": "2024-01-01T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "LIS_P0_premium_1"' +
            '       }' +
            '   ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/oci/isAvailable/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIAvailability.isAvailable();
        Test.stopTest();

        // Asserts - Expecting a success response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected a 200 HTTP status code.');
    }

    @IsTest
    static void getAvailableUnexistingProductTest() {
        String apexRestRequestBodyMock =
            '{' +
            '   "products": [' +
            '       {' +
            '           "startDate": "2024-01-01T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "Unexisting_Product"' +
            '       }' +
            '   ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/oci/isAvailable/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIAvailability.isAvailable();
        Test.stopTest();

        // Asserts - Expecting a failure response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected a non-200 HTTP status code due to invalid input.');
    }

    @IsTest
    static void getAvailableWrongDatesTest() {
        String apexRestRequestBodyMock =
            '{' +
            '   "products": [' +
            '       {' +
            '           "startDate": "2024-01-05T00:00:00",' +
            '           "endDate": "2024-01-03T23:00:00",' +
            '           "productId": "OPO_P3_economy_1"' +
            '       }' +
            '   ]' +
            '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/oci/isAvailable/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIAvailability.isAvailable();
        Test.stopTest();

        // Asserts - Expecting a failure response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected a 400 HTTP status code due to invalid input.');
    }

    @IsTest
    static void getExceptionErrorTest() {
        String apexRestRequestBodyMock = '{' + '    "badInput": "badInput"' + '}';

        // Build Request ApexRest
        String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
        String endpoint = sfdcBaseURL + '/services/apexrest/oci/isAvailable/v1';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = endpoint; //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(apexRestRequestBodyMock);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        COMM_WS_OCIAvailability.isAvailable();
        Test.stopTest();

        // Asserts - Expecting a failure response
        System.assertEquals(500, RestContext.response.statusCode, 'Expected a 500 HTTP status code due to invalid input.');
    }
}