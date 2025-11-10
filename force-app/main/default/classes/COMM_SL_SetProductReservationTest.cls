/**
 * @author Carlos Fusco
 * @description COMM_SL_GetProductAvailabilityTest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    28/02/2024           100                 Original version
 **/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@isTest
private class COMM_SL_SetProductReservationTest {
    @TestSetup
    static void makeData() {
        List<Product2> parentProductList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'LIS_P0',
                'ProductCode' => 'LIS_P0',
                'Description' => 'LIS_P0',
                'Family' => 'Parking',
                'IsActive' => false,
                'COMM_Airport__c' => 'LIS',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P0',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => parentProductList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );

        Product2 product = parentProductList[0];
        product.isActive = true;
        upsert product;

        parentProductList = (List<Product2>) COMM_TestDataFactory.insertRecords(
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
                'COMM_Tax__c' => 'Continent',
                'COMM_ParentProduct__c' => parentProductList.get(0).Id,
                'COMM_WhereProductAvailable__c' => 'Subscriptions Portal'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => parentProductList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );

        product = parentProductList[0];
        product.isActive = true;
        upsert product;
    }

    @isTest
    static void test() {
        COMM_SL_SetProductReservation.InputWrapper wrapper = new COMM_SL_SetProductReservation.InputWrapper();
        wrapper.codes = new List<String>{ 'LIS_P0_premium_1' };

        Boolean errorOccured = false;

        try {
            Test.startTest();
            List<List<COMM_SL_FlowChoice>> flowChoices = COMM_SL_SetProductReservation.setProductReservation(
                new List<COMM_SL_SetProductReservation.InputWrapper>{ wrapper }
            );
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        Assert.isFalse(errorOccured, 'No error expected');
    }
}