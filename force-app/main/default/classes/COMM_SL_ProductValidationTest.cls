/**
 * @author Ruben Rodrigues
 * @description COMM_SL_ProductValidation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer          Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues    07/06/2024      90             Original version
 **/
@isTest
public class COMM_SL_ProductValidationTest {
    @testSetup
    static void setup() {
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
                'COMM_ValidFrom__c' => Datetime.now().addSeconds(2),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => parkingProduct.Id,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'PENDING'
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
        Product2 fastTrackProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Fast Track Product',
                'ProductCode' => 'FTrack',
                'Description' => 'FTrack',
                'IsActive' => false,
                'Family' => COMM_DO_Product2.CATEGORY_FASTTRACK,
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
                'Product2Id' => fastTrackProduct.Id,
                'UnitPrice' => 10,
                'IsActive' => true
            }
        );

        //Insert Lounge Product and Pricebook Entry for testing
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
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_SubCategory__c' => 'Lounge'
            }
        )[0];
        products.add(loungeProduct);

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addSeconds(2),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => loungeProduct.Id,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'PENDING'
            }
        );

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
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_ParentProduct__c' => loungeProduct.id,
                'COMM_SubCategory__c' => 'Lounge',
                'COMM_WhereProductAvailable__c' => COMM_DO_Product2.PRODUCT_AVAILABLE_IN_COMMERCE
            }
        )[0];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addSeconds(2),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => pForCap.Id,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'PENDING'
            }
        );

        //Generate Product Settings
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductSetting__c',
            new Map<String, Object>{
                'Name' => 'Payment Type Settings (Test)',
                'COMM_FieldName__c' => 'Payment Type',
                'COMM_CoreEssential__c' => true,
                'COMM_CommerceEssential__c' => false,
                'COMM_FieldAPIName__c' => 'COMM_PaymentType__c',
                'COMM_CommerceMappingAttribute__c' => null,
                'COMM_EligibleProductType__c' => 'Parking;Lounge;Fast Track;Subscription'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductSetting__c',
            new Map<String, Object>{
                'Name' => 'Price determined in Core Setting (Test)',
                'COMM_FieldName__c' => 'Price determined in Core',
                'COMM_CoreEssential__c' => false,
                'COMM_CommerceEssential__c' => true,
                'COMM_FieldAPIName__c' => 'COMM_PriceDeterminedInCore__c',
                'COMM_CommerceMappingAttribute__c' => 'c_externalPricing',
                'COMM_EligibleProductType__c' => 'Parking;Lounge;Fast Track;Subscription'
            }
        );
    }

    @isTest
    static void verifyReadinessTest() {
        //Scenario: Three products with missing field are verified
        //Expected: Three Product Readiness instances are generated

        //Query expected list
        List<Product2> productList = [
            SELECT
                Id,
                Family,
                IsActive,
                COMM_ValidFrom__c,
                COMM_ValidTo__c,
                COMM_IsIntegratedInCommerce__c,
                COMM_HasUpdateForCommerce__c,
                COMM_ParentProduct__c,
                ProductCode,
                (
                    SELECT
                        Id,
                        UnitPrice,
                        COMM_First15MinuteUnit__c,
                        COMM_Second15MinuteUnit__c,
                        COMM_Third15MinuteUnit__c,
                        COMM_Remaining15MinuteUnit__c,
                        COMM_FirstPeriodStartDay__c,
                        COMM_FirstPeriodEndDay__c,
                        COMM_FirstPeriodDailyMaximum__c,
                        Pricebook2.IsStandard
                    FROM PricebookEntries
                    WHERE IsActive = TRUE
                ),
                (
                    SELECT Id
                    FROM Capacities__r
                    WHERE COMM_Active__c = TRUE AND COMM_IsDefaultCapacity__c = TRUE AND COMM_ProcessStatus__c IN ('COMPLETED', 'PENDING')
                )
            FROM Product2
        ];

        Test.startTest();
        List<COMM_ProductReadiness__c> resultList = new COMM_SL_ProductValidation().verifyReadiness(productList);
        Test.stopTest();

        Assert.areEqual(productList.size(), resultList.size(), 'expected result list to contain a readiness record for each Product');
        for (Integer index = 0; index < resultList.size(); index++) {
            Assert.areEqual(productList[0].Id, resultList[0].COMM_Product__c, 'expected readiness record to be associated with product record');
        }
    }
}