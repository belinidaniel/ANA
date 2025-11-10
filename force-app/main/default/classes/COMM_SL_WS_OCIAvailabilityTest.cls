/**
 * @author           Jose Passos
 * @description      COMM_SL_WS_OCIAvailability test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      97            Original version
 * Daniel Reto      02/05/2024      94            ECOMM-957
 * Daniel Reto      02/05/2024      94            ECOMM-281
 * Jose Passos      02/05/2024      95            Update test class
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_SL_WS_OCIAvailabilityTest {
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

    /**
     * @description Test method of COMM_SL_WS_OCIAvailability.checkAvailability only availability
     */
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

        COMM_WS_AvailabilityInput input = COMM_WS_AvailabilityInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIAvailability availabilityService = new COMM_SL_WS_OCIAvailability();

        Test.startTest();
        COMM_WS_AvailabilityOutput output = availabilityService.checkAvailability(input, true);
        Test.stopTest();

        // Asserts - Expecting a success response
        System.assertEquals(output.products.isEmpty(), false, 'Expected products in output.');
    }

    /**
     * @description Test method of COMM_SL_WS_OCIAvailability.checkAvailability receiving all Data
     */
    @IsTest
    static void getFullAvailableSuccessResponseTest() {
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

        COMM_WS_AvailabilityInput input = COMM_WS_AvailabilityInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIAvailability availabilityService = new COMM_SL_WS_OCIAvailability();

        Test.startTest();
        COMM_WS_AvailabilityOutput output = availabilityService.checkAvailability(input, false);
        Test.stopTest();

        // Asserts - Expecting a success response
        System.assertEquals(output.inventory.isEmpty(), false, 'Expected products in output.');
    }
}