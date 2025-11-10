/**
 * @author Ricardo Dias
 * @description COMM_SL_PricingCalculation test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024		100            Original version
 **/
@isTest
private class COMM_SL_PricingCalculationTest {
    @TestSetup
    static void makeData() {
        List<Object> customPbs = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Pricebook2',
            new Map<String, Object>{
                'Name' => 'Custom Parking Price Book',
                'Description' => 'Custom Parking Price Book',
                'IsActive' => true,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2)
            }
        );

        Pricebook2 customPb = (Pricebook2) customPbs[0];
        Time myTime = Time.newInstance(1, 2, 3, 0);
        // Insert Product2
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Parking Service',
                'ProductCode' => 'PS',
                'Description' => 'Parking Service',
                'IsActive' => false,
                'Family' => 'Parking',
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_Periodicity__c' => 'Monthly'
            }
        );

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

        parkingProduct = (Product2) updatedProducts[0];

        // Insert PricebookEntry for Standard Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => Test.getStandardPricebookId(),
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

        // Insert PricebookEntry for Custom Parking Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => customPb.Id,
                'Product2Id' => parkingProduct.Id,
                'UnitPrice' => 0,
                'IsActive' => true,
                'COMM_First15MinuteUnit__c' => 2,
                'COMM_Second15MinuteUnit__c' => 2,
                'COMM_Third15MinuteUnit__c' => 2,
                'COMM_Remaining15MinuteUnit__c' => 2,
                'COMM_FirstPeriodStartDay__c' => 1,
                'COMM_FirstPeriodEndDay__c' => 366,
                'COMM_FirstPeriodDailyMaximum__c' => 2
            }
        );

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true,
            Type__c = COMM_GEN_Utility.TYPE_PUBLIC,
            COMM_ValidFrom__c = DateTime.newInstance(Date.today().year(), 1, 1, 0, 0, 0),
            COMM_ValidTo__c = DateTime.newInstance(Date.today().year(), 12, 31, 23, 59, 0)
        );
        update standardPricebook;
    }

    // Test method for getPrice
    @isTest
    static void testGetPriceByPBE() {
        List<PricebookEntry> pricebookEntriesList = [
            SELECT
                Id,
                ProductCode,
                Pricebook2.Id,
                Pricebook2.IsStandard,
                Pricebook2.Name,
                UnitPrice,
                Product2Id,
                Pricebook2.COMM_ValidFrom__c,
                Pricebook2.COMM_ValidTo__c,
                Product2.Family,
                Pricebook2Id,
                COMM_First15MinuteUnit__c,
                COMM_Second15MinuteUnit__c,
                COMM_Third15MinuteUnit__c,
                COMM_Remaining15MinuteUnit__c,
                COMM_FirstPeriodStartDay__c,
                COMM_FirstPeriodEndDay__c,
                COMM_FirstPeriodDailyMaximum__c,
                COMM_SecondPeriodStartDay__c,
                COMM_SecondPeriodEndDay__c,
                COMM_SecondPeriodDailyMaximum__c,
                COMM_ThirdPeriodStartDay__c,
                COMM_ThirdPeriodEndDay__c,
                COMM_ThirdPeriodDailyMaximum__c,
                COMM_FourthPeriodStartDay__c,
                COMM_FourthPeriodEndDay__c,
                COMM_FourthPeriodDailyMaximum__c
            FROM PricebookEntry
        ];

        DateTime startDateTime = DateTime.newInstance(2024, 1, 1, 0, 0, 0);
        DateTime endDateTime = DateTime.newInstance(2024, 1, 31, 23, 59, 59);

        Test.startTest();
        COMM_SL_PricingCalculation pricingCalculation = new COMM_SL_PricingCalculation();
        Map<PricebookEntry, Decimal> resultMap = pricingCalculation.getPriceByPBE(pricebookEntriesList, startDateTime, endDateTime);
        Test.stopTest();

        // Verify the results are as expected
        System.assertNotEquals(null, resultMap, 'The result should not be null.');
        Decimal value = resultMap.get(resultMap.keySet().iterator().next());
        System.assertNotEquals(0, value, 'The result should not 0.');
    }
}