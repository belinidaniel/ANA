/**
 * @author Ricardo Dias
 * @description COMM_SL_WS_Pricing test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias     23/02/2024      100            Original version
 * Ricardo Dias     08/04/2024      100            Update tests
 * Daniel Reto      08/04/2024      86             Update tests
 **/
@isTest
public class COMM_SL_WS_PricingTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_REP_PricebookEntry PBE_REP = (COMM_REP_PricebookEntry) MOCKS.mock(COMM_REP_PricebookEntry.class);

    @TestSetup
    static void makeData() {
        // Insert Custom Parking Pricebook2
        List<Object> customPbs = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Pricebook2',
            new Map<String, Object>{
                'Name' => 'Custom Parking Price Book',
                'Description' => 'Custom Parking Price Book',
                'IsActive' => true,
                'Type__c' => COMM_GEN_Utility.TYPE_PUBLIC,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2)
            }
        );

        // Assuming COMM_TestDataFactory.insertRecords returns a list of sObjects, extract the first (and only) Pricebook2 record
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
                'Family' => 'Parking', // Assuming 'Parking' is a valid Family value for your org
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

        parkingProduct = (Product2) updatedProducts[0];
        // Insert PricebookEntry for Standard Pricebook
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => Test.getStandardPricebookId(), // This method is provided by Salesforce to get the standard pricebook's Id in test context
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

    // Test method for getPricing
    @isTest
    static void testGetPricing() {
        Test.startTest();
        COMM_SL_WS_Pricing pricingCalculation = new COMM_SL_WS_Pricing();
        String startDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');
        String endDate = Datetime.now().addDays(3).format('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');

        String jsonBody = '{"product":[{"startDate":"' + startDate + '","endDate":"' + endDate + '","productId": "PS"}]}';

        Map<String, Object> resultMap = pricingCalculation.calculatePricingResponse(COMM_RestServices_Utility.parseRequest(jsonBody));
        Test.stopTest();

        // Verify the results are as expected
        System.assertNotEquals(null, resultMap, 'The result should not be null');
        String valid = resultMap.keySet().iterator().next();
        List<Object> productsList = (List<Object>) resultMap.get('product');
        System.assert(!productsList.isEmpty(), 'The list should not be empty');
        Map<String, Object> firstProduct = (Map<String, Object>) productsList.get(0);
        Decimal price = (Decimal) firstProduct.get('price');
        System.assertEquals(price, 1, 'The result should be 1');
    }

    // Test method for getPricing
    @isTest
    static void testGetResellerPricing() {
        Test.startTest();
        COMM_SL_WS_Pricing pricingCalculation = new COMM_SL_WS_Pricing();
        String startDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');
        String endDate = Datetime.now().addDays(3).format('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');

        String jsonBody = '{"product":[{"startDate":"' + startDate + '","endDate":"' + endDate + '","productId": "PS"}]}';

        Id productId = [SELECT Id FROM Product2 WHERE ProductCode = 'PS'].Id;

        COMM_ResellerAssortment__c resellerAssortmentRecord = new COMM_ResellerAssortment__c(
            COMM_Product__c = productId,
            COMM_PriceBook__c = Test.getStandardPricebookId(),
            COMM_Active__c = true
        );
        insert resellerAssortmentRecord;

        Map<String, Object> resultMap = pricingCalculation.calculatePricingResellerResponse(COMM_RestServices_Utility.parseRequest(jsonBody), new List<COMM_ResellerAssortment__c>{resellerAssortmentRecord});
        Test.stopTest();

        // Verify the results are as expected
        System.assertNotEquals(null, resultMap, 'The result should not be null');
    }
}