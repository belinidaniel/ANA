/**
 * @author Carlos Fusco
 * @description COMM_SL_GetProductPrice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer           Date            Coverage(%)          Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco      25/03/2024           100              Original version
 **/
@isTest
private class COMM_SL_GetProductPriceTest {
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
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_SubCategory__c' => 'Park'
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

    @isTest
    static void getProductPriceTest() {
        List<List<COMM_SL_FlowChoice>> producPriceInfo = new List<List<COMM_SL_FlowChoice>>();
        COMM_SL_GetProductPrice.InputWrapper wrapper = new COMM_SL_GetProductPrice.InputWrapper();
        wrapper.airports = 'LIS';
        wrapper.categories = 'Parking';
        wrapper.periodicities = 'Monthly';
        wrapper.subCategories = 'Park';
        wrapper.codes = new List<String>{ 'P2' };

        Test.startTest();
        producPriceInfo = COMM_SL_GetProductPrice.getProductPrice(new List<COMM_SL_GetProductPrice.InputWrapper>{ wrapper });
        Test.stopTest();

        Assert.isFalse(producPriceInfo.isEmpty(), 'List of product pricing information should not be empty');
    }
}