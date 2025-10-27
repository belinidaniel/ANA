/**
 * @author Ricardo Dias
 * @description COMM_REP_PricebookEntry test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias     23/02/2024		100            Original version
 * Daniel Lascas    10/04/2024		100            ECOMM-194: Added test for getCardPBEByIds
 * Daniel Reto      01/05/2024		100            ECOMM-997: Added test for getPBEByProductCodeDataBaseQueryList
 * Daniel Lascas    07/06/2024		100            ECOMM-997: Added test for getPBEByProductAndPricebookIds
 **/
@isTest
private class COMM_REP_PricebookEntryTest {
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

        //Insert Card Product and Pricebook Entry for testing
        Product2 cardProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Card',
                'ProductCode' => 'Card',
                'Description' => 'Card',
                'IsActive' => false,
                'Family' => COMM_DO_Product2.CATEGORY_CARD,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime
            }
        )[0];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => Test.getStandardPricebookId(),
                'Product2Id' => cardProduct.Id,
                'UnitPrice' => 0,
                'IsActive' => true
            }
        );
    }

    @isTest
    static void getPBEByProductCodeList() {
        // Retrieve the Product2 record to get its ProductCode for the test
        Product2 testProduct = [SELECT Id, ProductCode FROM Product2 WHERE Name = 'Parking Service0' LIMIT 1];

        Test.startTest();
        List<PricebookEntry> actualEntries = new COMM_REP_PricebookEntry().getPBEByProductCodeList(new Set<String>{ testProduct.ProductCode });
        Test.stopTest();

        // Verify the number of entries retrieved matches expectations
        System.assertEquals(1, actualEntries.size(), 'Expected to retrieve 1 Pricebook Entries for the given product code.');
    }

    @isTest
    static void getCardPBEByIdsTest() {
        // Retrieve the Card Product record to get its Id for the test
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Family = :COMM_DO_Product2.CATEGORY_CARD LIMIT 1];

        Test.startTest();
        List<PricebookEntry> actualEntries = new COMM_REP_PricebookEntry().getCardPBEByIds(new Set<Id>{ testProduct.Id });
        Test.stopTest();

        // Verify the number of entries retrieved matches expectations
        Assert.areEqual(1, actualEntries.size(), 'Expected to retrieve 1 Pricebook Entries for the given product Id.');
    }

    @isTest
    static void getPBEByProductCodeDataBaseQueryList() {
        // Retrieve the Product2 record to get its ProductCode for the test
        Product2 testProduct = [SELECT Id, ProductCode FROM Product2 WHERE Name = 'Parking Service0' LIMIT 1];

        Test.startTest();
        List<PricebookEntry> actualEntries = new COMM_REP_PricebookEntry()
            .getPBEByProductCodeDataBaseQueryList(new Set<String>{ testProduct.ProductCode });
        Test.stopTest();

        // Verify the number of entries retrieved matches expectations
        System.assertEquals(1, actualEntries.size(), 'Expected to retrieve 1 Pricebook Entries for the given product code.');
    }

    @isTest
    static void getPBEByProductAndPricebookIdsTest() {
        // Retrieve the Product2 record to get its ProductCode for the test
        PricebookEntry testPB = [SELECT Id, Product2Id, Pricebook2Id FROM PricebookEntry LIMIT 1];

        Test.startTest();
        List<PricebookEntry> actualEntries = new COMM_REP_PricebookEntry()
            .getPBEByProductAndPricebookIds(new Set<Id>{ testPB.Product2Id }, new Set<Id>{ testPB.Pricebook2Id });
        Test.stopTest();

        // Verify the number of entries retrieved matches expectations
        Assert.areEqual(testPB.Id, actualEntries[0].Id, 'Obtained Pricebook Entry does not match expected');
    }
}