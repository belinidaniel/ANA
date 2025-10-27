/**
 * @author Carlos Fusco
 * @description COMM_SL_ClearProductReservations test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    28/02/2024           100                 Original version
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@isTest
private class COMM_SL_ClearProductReservationsTest {
    @TestSetup
    static void makeData() {
        // Insert Product2
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0_premium_1',
                'productCode' => 'LIS_P0_premium_1',
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
                'COMM_Tax__c' => 'Continent',
                'Description' => 'Product Description'
            }
        );

        // Assuming COMM_TestDataFactory.insertRecords returns a list of sObjects, extract the first (and only) Product2 record
        Product2 parkingProduct = (Product2) products[0];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => parkingProduct.Id,
                'COMM_IsDefaultCapacity__c' => true
            }
        );

        List<sObject> updatedProducts = COMM_TestDataFactory.updateRecords(
            new List<Id>{ parkingProduct.Id },
            'Product2',
            new Map<String, Object>{ 'IsActive' => true }
        );
    }

    @isTest
    static void testReleaseProductReservations() {
        COMM_SL_SetProductReservation.InputWrapper wrapper = new COMM_SL_SetProductReservation.InputWrapper();
        wrapper.codes = new List<String>{ 'LIS_P0_premium_1' };

        COMM_SL_ClearProductReservations.InputWrapper wrapper2 = new COMM_SL_ClearProductReservations.InputWrapper();
        wrapper2.startDate = System.now();
        wrapper2.endDate = System.now().addDays(30);
        wrapper2.productCodeList = new List<String>{ 'LIS_P0_premium_1' };

        Boolean errorOccured = false;

        try {
            Test.startTest();
            COMM_SL_ClearProductReservations.releaseProductReservations(new List<COMM_SL_ClearProductReservations.InputWrapper>{ wrapper2 });
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        Assert.isFalse(errorOccured, 'No error expected');
    }
}