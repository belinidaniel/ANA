/**
 * @author Daniel Lascas
 * @description COMM_SL_VerifyAvailabilityAndPricing test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/04/2024      100            Original version
 **/
@isTest
private class COMM_SL_VerifyAvailabilityAndPricingTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Product2 PRODUCT_REP = (COMM_IREP_Product2) MOCKS.mock(COMM_IREP_Product2.class);
    private final static COMM_IREP_PricebookEntry PRICEBOOK_REP = (COMM_REP_PricebookEntry) MOCKS.mock(COMM_REP_PricebookEntry.class);

    @isTest
    static void verifyTest() {
        //Scenario: Two Products are verified if they are available and have pricing.
        //First Product is a child with Parent (available and has pricing)
        //Second Product does not have child (available but without pricing)
        //Expected: Only Child Product's Code is returned

        Product2 mockedProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Product2.sObjectType),
                'ProductCode' => 'test_code',
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE
            }
        )[0];

        Product2 mockedProductWithoutChild = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Product2.sObjectType),
                'ProductCode' => 'test_code_2',
                'Family' => COMM_DO_Product2.CATEGORY_CARD
            }
        )[0];

        Product2 mockedChildProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Product2.sObjectType),
                'ProductCode' => 'test_code_child',
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE,
                'COMM_ParentProduct__c' => mockedProduct.Id
            }
        )[0];
        mockedChildProduct = (Product2) COMM_TestDataFactory.setField(
            mockedChildProduct,
            new Map<String, Object>{ 'COMM_ParentProduct__r' => mockedProduct }
        );

        COMM_Capacity__c mockedCapacity = (COMM_Capacity__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(COMM_Capacity__c.sObjectType) }
        )[0];
        mockedCapacity = (COMM_Capacity__c) COMM_TestDataFactory.setField(
            mockedCapacity,
            new Map<String, Object>{ 'COMM_CalculatedCapacity__c' => 15 }
        );

        COMM_Capacity__c mockedCapacityForNoChild = (COMM_Capacity__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(COMM_Capacity__c.sObjectType) }
        )[0];
        mockedCapacityForNoChild = (COMM_Capacity__c) COMM_TestDataFactory.setField(
            mockedCapacityForNoChild,
            new Map<String, Object>{ 'COMM_CalculatedCapacity__c' => 25 }
        );

        //Mock Relationship (Child with none)
        List<Product2> productList = (List<Product2>) fflib_ApexMocksUtils.makeRelationship(
            List<Product2>.class,
            new List<Product2>{ mockedChildProduct, mockedProductWithoutChild },
            COMM_Capacity__c.COMM_Product__c,
            new List<List<COMM_Capacity__c>>{ new List<COMM_Capacity__c>(), new List<COMM_Capacity__c>{ mockedCapacityForNoChild } }
        );

        //Mock Relationship (only Parent with Capacity Record)
        List<Product2> parentProductList = (List<Product2>) fflib_ApexMocksUtils.makeRelationship(
            List<Product2>.class,
            new List<Product2>{ mockedProduct },
            COMM_Capacity__c.COMM_Product__c,
            new List<List<COMM_Capacity__c>>{ new List<COMM_Capacity__c>{ mockedCapacity } }
        );

        PricebookEntry mockedPricebook = (PricebookEntry) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PricebookEntry',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(PricebookEntry.sObjectType), 'UnitPrice' => 20 }
        )[0];
        mockedPricebook = (PricebookEntry) COMM_TestDataFactory.setField(
            mockedPricebook,
            new Map<String, Object>{ 'Product2' => mockedChildProduct }
        );

        Set<String> hasAvailabilitySet = new Set<String>();
        Set<String> hasPricingSet = new Set<String>();

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(
                PRODUCT_REP.getProductAndCapacitiesByProductCodes(
                    new Set<String>{ mockedChildProduct.ProductCode, mockedProductWithoutChild.ProductCode }
                )
            )
            .thenReturn(productList);
        MOCKS.when(PRODUCT_REP.getProductAndCapacitiesByProductCodes(new Set<String>{ mockedProduct.ProductCode })).thenReturn(parentProductList);
        MOCKS.when(PRICEBOOK_REP.getPBEByProductCodeList((Set<String>) fflib_Match.anyObject()))
            .thenReturn(new List<PricebookEntry>{ mockedPricebook });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_VerifyAvailabilityAndPricing worker = new COMM_SL_VerifyAvailabilityAndPricing();
        worker = new COMM_SL_VerifyAvailabilityAndPricing(PRODUCT_REP, PRICEBOOK_REP);
        Set<String> resultSet = worker.verifyProductHasPricingAndAvailableByCode(
            new Set<String>{ mockedChildProduct.ProductCode, mockedProductWithoutChild.ProductCode },
            hasAvailabilitySet,
            hasPricingSet
        );
        Test.stopTest();

        Set<String> expectedResult = new Set<String>{ mockedChildProduct.ProductCode };
        Set<String> expectedAvailabilityResult = new Set<String>{ mockedChildProduct.ProductCode, mockedProductWithoutChild.ProductCode };
        Set<String> expectedPricingResult = new Set<String>{ mockedChildProduct.ProductCode };

        Assert.areEqual(expectedResult, resultSet, 'result does not match expected');
        Assert.areEqual(expectedAvailabilityResult, hasAvailabilitySet, 'availability set does not match expected');
        Assert.areEqual(expectedPricingResult, hasPricingSet, 'pricing set does not match expected');
    }
}