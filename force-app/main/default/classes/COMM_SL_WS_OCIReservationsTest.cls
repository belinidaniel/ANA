/**
 * @author           Jose Passos
 * @description      COMM_SL_WS_OCIReservations test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      93             Original version
 * Jose Passos      02/05/2024      92             Updated to support get price requests
 * Jose Passos      02/05/2024      89             Updated to add child product requests
 * Jose Passos      15/05/2024      89             Updated makeData
 * Jose Passos      29/05/2024      91             ECOMM-1191
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class COMM_SL_WS_OCIReservationsTest {
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
    static void reserveWithoutPriceSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "actionRequestId": "' +
            COMM_OCI_Utils.newGuid() +
            '",' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "actionRequestId": "' +
            COMM_OCI_Utils.newGuid() +
            '",' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        },' +
            '        {' +
            '            "actionRequestId": "' +
            COMM_OCI_Utils.newGuid() +
            '",' +
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

        COMM_WS_ReservationInput input = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();

        Test.startTest();
        List<COMM_WS_ReservationOutput> output = reservationService.reserve(input, false, COMM_OCI_Utils.DATETIME_GMT_STRING);
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(3, output.size(), 'Expected 3 products in response.');
    }

    @IsTest
    static void reserveWithChildProductAndPriceSuccessResponseTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_lounge_kids_1",' +
            '            "startDate": "' +
            DateTime.now().addDays(1).formatGMT(dateTimeFormat) +
            '",' +
            '            "endDate": "' +
            DateTime.now().addDays(5).formatGMT(dateTimeFormat) +
            '"' +
            '        }' +
            '    ]' +
            '}';

        COMM_WS_ReservationInput input = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();

        Test.startTest();
        List<COMM_WS_ReservationOutput> output = reservationService.reserve(input, true, COMM_OCI_Utils.DATETIME_GMT_STRING);
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(1, output.size(), 'Expected 1 products in response.');
    }

    @IsTest
    static void reserveWithPriceSuccessResponseTest() {
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

        COMM_WS_ReservationInput input = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();

        Test.startTest();
        List<COMM_WS_ReservationOutput> output = reservationService.reserve(input, true, COMM_OCI_Utils.DATETIME_GMT_STRING);
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(3, output.size(), 'Expected 3 products in response.');
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

        COMM_WS_ReservationInput input = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();

        Test.startTest();
        reservationService.release(input, COMM_OCI_Utils.DATETIME_LOCAL_STRING);
        Test.stopTest();

        // Asserts - It is not possible to query the result and it is a void method
        Assert.areEqual(1, 1, 'Expected same result.');
    }

    @IsTest
    static void revertPermanentReservationSuccessResponseTest() {
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

        COMM_WS_ReservationInput input = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        COMM_SL_WS_OCIReservations reservationService = new COMM_SL_WS_OCIReservations();

        Test.startTest();
        List<COMM_WS_ReservationOutput> output = reservationService.revertPermanentReservation(input, false, COMM_OCI_Utils.DATETIME_LOCAL_STRING);
        Test.stopTest();

        // Asserts - Expecting a success response
        Assert.areEqual(3, output.size(), 'Expected 3 products in response.');
    }

    @IsTest
    static void rollbackReservedRecordsTest() {
        String apexRestRequestBodyMock =
            '{' +
            '    "reservationId": "' +
            reservationId +
            '",' +
            '    "expirationSeconds": 90,' +
            '    "product": [' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "2024-01-01T00:00:00",' +
            '            "endDate": "2024-01-04T23:00:00"' +
            '        },' +
            '        {' +
            '            "productId": "OPO_P3_economy_1",' +
            '            "startDate": "2024-01-01T00:00:00",' +
            '            "endDate": "2024-01-05T23:00:00"' +
            '        },' +
            '        {' +
            '            "productId": "LIS_P0_premium_1",' +
            '            "startDate": "2024-01-01T00:00:00",' +
            '            "endDate": "2024-01-03T23:00:00"' +
            '        }' +
            '    ]' +
            '}';

        COMM_WS_ReservationInput inputRequest = COMM_WS_ReservationInput.parse(apexRestRequestBodyMock);
        List<String> actionRequestIdList = new List<String>{ 'reqActionId1', 'reqActionId2' };
        Boolean isTemporaryReservation = true;
        Test.startTest();
        Boolean success = COMM_SL_WS_OCIReservations.rollbackReservedRecords(isTemporaryReservation, reservationId, actionRequestIdList, null);
        Test.stopTest();

        // Asserts - Expecting a failure response
        Assert.areEqual(true, success, 'Expected a success output');
    }

    @IsTest
    static void processInvokeReserveErrorsTest() {
        /*String createReservationOutputErrorMock = 
        '{'+
        '    "details": ['+
        '        {'+
        '            "errorCode": "InsufficientQuantity",'+
        '            "locationGroupIdentifier": null,'+
        '            "locationIdentifier": "Hour_00",'+
        '            "quantity": null,'+
        '            "stockKeepingUnit": "OPO_P3_economy_1"'+
        '        }'+
        '    ],'+
        '    "errors": [],'+
        '    "expirationTime": "2024-03-08T16:43:17.591Z",'+
        '    "reservationTime": "2024-03-08T16:41:47.663Z",'+
        '    "success": true'+
        '}';*/
        ConnectApi.OCICreateReservationOutputRepresentation outputCreateReservation = new ConnectApi.OCICreateReservationOutputRepresentation();
        outputCreateReservation.success = true;
        outputCreateReservation.details = new List<ConnectApi.OCICreateReservationSingleOutputRepresentation>();
        ConnectApi.OCICreateReservationSingleOutputRepresentation detail = new ConnectApi.OCICreateReservationSingleOutputRepresentation();
        detail.errorCode = 'InsufficientQuantity';
        detail.locationGroupIdentifier = null;
        detail.locationIdentifier = 'Hour_00';
        detail.quantity = null;
        detail.stockKeepingUnit = 'OPO_P3_Economy_1';
        outputCreateReservation.details.add(detail);
        List<String> failedItemLocQtyKeyList = new List<String>{ detail.stockKeepingUnit + '_' + detail.locationIdentifier };

        // Reservation Errors
        Boolean success = true;
        List<String> reservationErrorMessageList = new List<String>();
        Test.startTest();
        success = COMM_SL_WS_OCIReservations.processInvokeReserveErrors(
            outputCreateReservation,
            reservationErrorMessageList,
            failedItemLocQtyKeyList
        );
        Test.stopTest();
        Assert.isFalse(success, 'success should be false.');
        Assert.isNotNull(reservationErrorMessageList, 'reservationErrorMessageList is null');
    }

    @IsTest
    static void processInvokeReleaseErrorsTest() {
        /*String releaseReservationOutputErrorMock = 
        '{'+
        '    "errors": ['+
        '        {'+
        '            "details": {'+
        '                "actionRequestId": Req_"'+reservationId+'",'+
        '                "externalRefId": Ref_"'+reservationId+'",'+
        '                "locationGroupIdentifier": null,'+
        '                "locationIdentifier": "Hour_00",'+
        '                "quantity": 0.0,'+
        '                "stockKeepingUnit": "OPO_P3_economy_1"'+
        '            },'+
        '            "errorCode": "InsufficientQuantity",'+
        '            "message": "Insufficient Quantity"'+
        '        }'+
        '    ],'+
        '    "success": true'+
        '}';*/
        ConnectApi.OCIReleaseReservationOutputRepresentation outputReleaseReservation = new ConnectApi.OCIReleaseReservationOutputRepresentation();
        outputReleaseReservation.success = true;
        outputReleaseReservation.errors = new List<ConnectApi.OCIReleaseReservationErrorOutputRepresentation>();
        ConnectApi.OCIReleaseReservationErrorOutputRepresentation error = new ConnectApi.OCIReleaseReservationErrorOutputRepresentation();
        error.errorCode = 'InsufficientQuantity';
        error.message = 'Insufficient Quantity';
        error.details = new ConnectApi.OCIReleaseReservationSingleOutputRepresentation();
        error.details.actionRequestId = 'Req_' + reservationId;
        error.details.externalRefId = 'Ref_' + reservationId;
        error.details.locationGroupIdentifier = null;
        error.details.locationIdentifier = 'Hour_00';
        error.details.quantity = 0.0;
        error.details.stockKeepingUnit = 'OPO_P3_economy_1';
        outputReleaseReservation.errors.add(error);

        // Release Errors
        Boolean success = true;
        List<String> realeaseErrorMessageList = new List<String>();
        Test.startTest();
        success = COMM_SL_WS_OCIReservations.processInvokeReleaseErrors(outputReleaseReservation, realeaseErrorMessageList);
        Test.stopTest();
        Assert.isFalse(success, 'success should be false.');
        Assert.isNotNull(realeaseErrorMessageList, 'resleaseErrorMessageList is null');
    }
}