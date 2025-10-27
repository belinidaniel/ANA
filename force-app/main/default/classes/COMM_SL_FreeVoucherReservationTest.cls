/**
 * @author           Daniel Lascas
 * @description      COMM_SL_FreeVoucherReservation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/10/2024      92            ECOMM-2248: Original version
 **/
@isTest
private class COMM_SL_FreeVoucherReservationTest {
    private static final List<String> QRCODE_RESPONSE_DATA = new List<String>{
        '"content": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdj+Gkf9x8ABmEClm+bvsMAAAAASUVORK5CYII="',
        '"fileType": "img/png"'
    };

    @TestSetup
    static void setup() {
        Time testTime = Time.newInstance(1, 2, 3, 0);
        //Insert Lounge Product for testing
        Product2 loungeProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Lounge Product',
                'ProductCode' => 'lounge2',
                'Description' => 'lounge',
                'IsActive' => false,
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => testTime,
                'COMM_ClosingOperatingHours__c' => testTime,
                'COMM_SubCategory__c' => 'Lounge'
            }
        )[0];

        // Insert Child Product
        Product2 pForCap = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Child',
                'ProductCode' => 'C2132',
                'Description' => 'Test Lounge',
                'IsActive' => true,
                'Family' => 'Lounge',
                'COMM_ValidFrom__c' => System.now().addMinutes(1),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_OpeningOperatingHours__c' => testTime,
                'COMM_ClosingOperatingHours__c' => testTime,
                'COMM_ParentProduct__c' => loungeProduct.id,
                'COMM_SubCategory__c' => 'Lounge',
                'COMM_WhereProductAvailable__c' => COMM_DO_Product2.PRODUCT_AVAILABLE_IN_COMMERCE
            }
        )[0];

        //Insert Free Voucher Record
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_FreeVoucher__c',
            new Map<String, Object>{
                'COMM_ReservationName__c' => 'Joao Teste',
                'COMM_StartDate__c' => Datetime.now(),
                'COMM_Email__c' => 'joao.teste@test.invalid',
                'COMM_Language__c' => 'pt_PT',
                'COMM_Product__c' => pForCap.Id
            }
        );
    }

    @isTest
    static void testCreateReservationVouchers() {
        //Scenario: QR Code for Free Voucher is requested
        //Expected: QR Code generated.
        List<COMM_FreeVoucher__c> fvList = [SELECT Id FROM COMM_FreeVoucher__c LIMIT 1];
        Assert.areEqual(fvList.isEmpty(), false, 'Free Voucher not found.');

        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock('{' + String.join(QRCODE_RESPONSE_DATA, ',') + '}'));

        Test.startTest();
        COMM_SL_FreeVoucherReservation.createFreeReservationVouchers(new List<Id>{ fvList[0].Id });
        Test.stopTest();

        List<COMM_FreeVoucher__c> actualFvList = [SELECT Id, COMM_QRCodeImage__c FROM COMM_FreeVoucher__c WHERE Id = :fvList[0].Id];

        Assert.isNotNull(actualFvList[0].COMM_QRCodeImage__c, 'QR Codes were not created');
    }

    @isTest
    static void testCreateVouchersExceptionAndResolve() {
        //Scenario: QR Code for Free Voucher is requested but fails to generate.
        //Expected: QR Code isn't generated.
        List<COMM_FreeVoucher__c> fvList = [SELECT Id FROM COMM_FreeVoucher__c LIMIT 1];
        Assert.areEqual(fvList.isEmpty(), false, 'Free Voucher not found.');

        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock('{}'));

        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_SL_FreeVoucherReservation.createFreeReservationVouchers(new List<Id>{ fvList[0].Id });
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        List<COMM_FreeVoucher__c> actualFvList = [SELECT Id, COMM_QRCodeImage__c FROM COMM_FreeVoucher__c WHERE Id = :fvList[0].Id];

        Assert.isTrue(errorOccured, 'expected an error to occur');
        Assert.isNull(actualFvList[0].COMM_QRCodeImage__c, 'expected QR Codes to not be created');
    }
}