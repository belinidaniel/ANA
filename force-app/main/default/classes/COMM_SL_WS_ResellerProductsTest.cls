/**
 * @author Daniel Lascas
 * @description COMM_SL_WS_ResellerProducts test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/05/2024      100            ECOMM-386: Original version
 * Daniel Reto      04/11/2024      100            ECOMM-327
 **/
@isTest
private class COMM_SL_WS_ResellerProductsTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_IREP_ProductVariations PRODUCT_VARIATION_REP = (COMM_REP_ProductVariations) MOCKS.mock(
        COMM_REP_ProductVariations.class
    );
    private final static COMM_SL_WS_OCIAvailability OCI_AVAILABILITY_SL = (COMM_SL_WS_OCIAvailability) MOCKS.mock(COMM_SL_WS_OCIAvailability.class);
    private final static COMM_IREP_PricebookEntry PRICEBOOK_ENTRY_REP = (COMM_REP_PricebookEntry) MOCKS.mock(COMM_REP_PricebookEntry.class);
    private final static COMM_SL_PricingCalculation PRICING_CALCULATION_SL = (COMM_SL_PricingCalculation) MOCKS.mock(
        COMM_SL_PricingCalculation.class
    );
    private final static COMM_IDO_ResellerApiMapping RESELLER_MAPPING_DO = (COMM_DO_ResellerApiMapping) MOCKS.mock(COMM_DO_ResellerApiMapping.class);

    @isTest
    static void getResellerStockTest() {
        //Scenario: Reseller send request to search for available stock
        //Expected: Response with parking product available for reseller

        //Mock Reseller Acount
        Account resellerAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.SObjectType), 'COMM_IsReseller__c' => true }
        )[0];

        //Mock Reseller Pricebook
        Pricebook2 resellerPricebook = (Pricebook2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Pricebook2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Pricebook2.SObjectType) }
        )[0];

        //Mock Product for Reseller
        Product2 parkingProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-10',
                'COMM_ProductType__c' => 'single'
            }
        )[0];

        //Mock Reseller Assortment Record
        COMM_ResellerAssortment__c resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ResellerAssortment__c.SObjectType),
                'COMM_Product__c' => parkingProduct.Id,
                'COMM_Pricebook__c' => resellerPricebook.Id,
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_CurrentDailyQuantity__c' => 5,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.setField(
            resellerAssortment,
            new Map<String, Object>{
                'COMM_AvailableDailyQuantity__c' => (Integer) (resellerAssortment.COMM_DailyLimit__c -
                resellerAssortment.COMM_CurrentDailyQuantity__c)
            }
        );
        resellerAssortment.COMM_Product__r = parkingProduct;

        //Mock relationship between reseller account and assorment list
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ resellerAccount },
            COMM_ResellerAssortment__c.COMM_Account__c,
            new List<List<COMM_ResellerAssortment__c>>{ new List<COMM_ResellerAssortment__c>{ resellerAssortment } }
        );

        //Mock OCI Availability
        COMM_WS_AvailabilityOutput ociResponse = new COMM_WS_AvailabilityOutput();
        COMM_WS_AvailabilityOutput.Product ociProduct = new COMM_WS_AvailabilityOutput.Product();
        ociProduct.productId = parkingProduct.ProductCode;
        ociProduct.available = 10;
        ociProduct.startDate = Datetime.newInstance(2024, 1, 1, 0, 0, 0);
        ociProduct.endDate = Datetime.newInstance(2024, 1, 1, 23, 59, 59);
        ociResponse.products = new List<COMM_WS_AvailabilityOutput.Product>{ ociProduct };

        //Mock Pricing
        PricebookEntry testPricing = (PricebookEntry) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PricebookEntry',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(PricebookEntry.SObjectType), 'UnitPrice' => 50.00 }
        )[0];
        testPricing = (PricebookEntry) COMM_TestDataFactory.setField(
            testPricing,
            new Map<String, Object>{ 'Product2Id' => parkingProduct.Id, 'Pricebook2Id' => resellerPricebook.Id }
        );

        //Mock Mapping Result
        Map<String, Object> mappedProduct = new Map<String, Object>{ 'productId' => parkingProduct.ProductCode };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getResellerAccountProducts(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(OCI_AVAILABILITY_SL.checkAvailability((COMM_WS_AvailabilityInput) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(ociResponse);
        MOCKS.when(PRICEBOOK_ENTRY_REP.getPBEByProductAndPricebookIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<PricebookEntry>{ testPricing });
        MOCKS.when(
                PRICING_CALCULATION_SL.getPriceByPBE(
                    (List<PricebookEntry>) fflib_Match.anyList(),
                    fflib_Match.anyDatetime(),
                    fflib_Match.anyDatetime()
                )
            )
            .thenReturn(new Map<PricebookEntry, Decimal>{ testPricing => 50.00 });
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject((Product2) fflib_Match.anySobject(), (Map<String, Object>) fflib_Match.anyObject()))
            .thenReturn(mappedProduct);
        MOCKS.stopStubbing();

        String requestJSON =
            '{"resellerId":"' +
            resellerAccount.Id +
            '","airportId":"LIS","productCategory":"Parking",' +
            '"startDate":"2024-01-01T00:00:00","endDate":"2024-12-31T23:59:59","page":1,"pageSize":100}';

        Test.startTest();
        COMM_SL_WS_ResellerProducts worker = new COMM_SL_WS_ResellerProducts();
        worker = new COMM_SL_WS_ResellerProducts(
            ACCOUNT_REP,
            PRODUCT_VARIATION_REP,
            OCI_AVAILABILITY_SL,
            PRICEBOOK_ENTRY_REP,
            PRICING_CALCULATION_SL,
            RESELLER_MAPPING_DO
        );
        COMM_SL_WS_ResellerSearchResponse resultResponse = worker.getResellerStock(requestJSON);
        Test.stopTest();

        Assert.isNotNull(resultResponse, 'expected a response');
    }

    @isTest
    static void getResellerStockBundleTest() {
        //Scenario: Reseller send request to search for available stock. Stock is part of a bundle.
        //Expected: Response with bundle product available for reseller

        //Mock Reseller Acount
        Account resellerAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.SObjectType), 'COMM_IsReseller__c' => true }
        )[0];

        //Mock Reseller Pricebook
        Pricebook2 resellerPricebook = (Pricebook2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Pricebook2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Pricebook2.SObjectType) }
        )[0];

        //Mock Product for Reseller
        Product2 bundleProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-10',
                'COMM_ProductType__c' => 'bundle'
            }
        )[0];
        Product2 childProduct1 = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-11',
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE,
                'COMM_ProductType__c' => 'single'
            }
        )[0];
        Product2 childProduct2 = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-12',
                'Family' => COMM_DO_Product2.CATEGORY_FASTTRACK,
                'COMM_ProductType__c' => 'single'
            }
        )[0];

        //Mock Product Configuration Record
        COMM_ProductVariations__c variationRecord1 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ProductVariations__c.SObjectType),
                'COMM_MasterProduct__c' => bundleProduct.Id,
                'COMM_RelatedProduct__c' => childProduct1.Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 48
            }
        )[0];
        variationRecord1.COMM_RelatedProduct__r = childProduct1;
        COMM_ProductVariations__c variationRecord2 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ProductVariations__c.SObjectType),
                'COMM_MasterProduct__c' => bundleProduct.Id,
                'COMM_RelatedProduct__c' => childProduct2.Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 4
            }
        )[0];
        variationRecord2.COMM_RelatedProduct__r = childProduct2;
        List<COMM_ProductVariations__c> bundleVariationList = new List<COMM_ProductVariations__c>{ variationRecord1, variationRecord2 };

        //Mock Reseller Assortment Record
        COMM_ResellerAssortment__c resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ResellerAssortment__c.SObjectType),
                'COMM_Product__c' => bundleProduct.Id,
                'COMM_Pricebook__c' => resellerPricebook.Id,
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_CurrentDailyQuantity__c' => 5,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.setField(
            resellerAssortment,
            new Map<String, Object>{
                'COMM_AvailableDailyQuantity__c' => (Integer) (resellerAssortment.COMM_DailyLimit__c -
                resellerAssortment.COMM_CurrentDailyQuantity__c)
            }
        );
        resellerAssortment.COMM_Product__r = bundleProduct;

        //Mock relationship between reseller account and assorment list
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ resellerAccount },
            COMM_ResellerAssortment__c.COMM_Account__c,
            new List<List<COMM_ResellerAssortment__c>>{ new List<COMM_ResellerAssortment__c>{ resellerAssortment } }
        );

        //Mock OCI Availability
        COMM_WS_AvailabilityOutput ociResponse = new COMM_WS_AvailabilityOutput();
        COMM_WS_AvailabilityOutput.Product ociChildProduct1 = new COMM_WS_AvailabilityOutput.Product();
        ociChildProduct1.productId = childProduct1.ProductCode;
        ociChildProduct1.available = 20;
        ociChildProduct1.startDate = Datetime.newInstance(2024, 1, 1, 0, 0, 0);
        ociChildProduct1.endDate = Datetime.newInstance(2024, 12, 31, 23, 59, 59);
        COMM_WS_AvailabilityOutput.Product ociChildProduct2 = new COMM_WS_AvailabilityOutput.Product();
        ociChildProduct2.productId = childProduct2.ProductCode;
        ociChildProduct2.available = 30;
        ociChildProduct1.startDate = Datetime.newInstance(2024, 1, 1, 0, 0, 0);
        ociChildProduct1.endDate = Datetime.newInstance(2024, 1, 1, 23, 59, 59);
        ociResponse.products = new List<COMM_WS_AvailabilityOutput.Product>{ ociChildProduct1, ociChildProduct2 };

        //Mock Pricing
        PricebookEntry testPricing = (PricebookEntry) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PricebookEntry',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(PricebookEntry.SObjectType), 'UnitPrice' => 50.00 }
        )[0];
        testPricing = (PricebookEntry) COMM_TestDataFactory.setField(
            testPricing,
            new Map<String, Object>{ 'Product2Id' => bundleProduct.Id, 'Pricebook2Id' => resellerPricebook.Id }
        );

        //Mock Mapping Result
        Map<String, Object> mappedBundleProduct = new Map<String, Object>{ 'productId' => bundleProduct.ProductCode };
        Map<String, Object> mappedChildProduct1 = new Map<String, Object>{ 'productId' => childProduct1.ProductCode };
        Map<String, Object> mappedChildProduct2 = new Map<String, Object>{ 'productId' => childProduct2.ProductCode };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getResellerAccountProducts(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(PRODUCT_VARIATION_REP.getProductVariationsByProductId((Set<Id>) fflib_Match.anyObject())).thenReturn(bundleVariationList);
        MOCKS.when(OCI_AVAILABILITY_SL.checkAvailability((COMM_WS_AvailabilityInput) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(ociResponse);
        MOCKS.when(PRICEBOOK_ENTRY_REP.getPBEByProductAndPricebookIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<PricebookEntry>{ testPricing });
        MOCKS.when(
                PRICING_CALCULATION_SL.getPriceByPBE(
                    (List<PricebookEntry>) fflib_Match.anyList(),
                    fflib_Match.anyDatetime(),
                    fflib_Match.anyDatetime()
                )
            )
            .thenReturn(new Map<PricebookEntry, Decimal>{ testPricing => 50.00 });
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(resellerAssortment, new Map<String, Object>())).thenReturn(mappedBundleProduct);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(bundleProduct, new Map<String, Object>())).thenReturn(mappedBundleProduct);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(childProduct1, new Map<String, Object>())).thenReturn(mappedChildProduct1);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(childProduct2, new Map<String, Object>())).thenReturn(mappedChildProduct2);
        MOCKS.stopStubbing();

        String requestJSON =
            '{"resellerId":"' +
            resellerAccount.Id +
            '","airportId":"LIS","productCategory":"Bundle",' +
            '"startDate":"2024-01-01T00:00:00","endDate":"2024-12-31T23:59:59","page":1,"pageSize":100}';

        Test.startTest();
        COMM_SL_WS_ResellerProducts worker = new COMM_SL_WS_ResellerProducts();
        worker = new COMM_SL_WS_ResellerProducts(
            ACCOUNT_REP,
            PRODUCT_VARIATION_REP,
            OCI_AVAILABILITY_SL,
            PRICEBOOK_ENTRY_REP,
            PRICING_CALCULATION_SL,
            RESELLER_MAPPING_DO
        );
        COMM_SL_WS_ResellerSearchResponse resultResponse = worker.getResellerStock(requestJSON);
        Test.stopTest();

        Assert.isNotNull(resultResponse, 'expected a response');
        Assert.areEqual(5, resultResponse.product[0].stockAvailability, 'expected bundle stock to be 5');
    }

    @isTest
    static void getResellerStockNoDatesTest() {
        //Scenario: Reseller send request to search for available stock. Dates weren't provided.
        //Expected: Response with available products for reseller

        //Mock Reseller Acount
        Account resellerAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.SObjectType), 'COMM_IsReseller__c' => true }
        )[0];

        //Mock Reseller Pricebook
        Pricebook2 resellerPricebook = (Pricebook2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Pricebook2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Pricebook2.SObjectType) }
        )[0];

        //Mock Product for Reseller
        Product2 bundleProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-10',
                'COMM_ProductType__c' => 'bundle'
            }
        )[0];
        Product2 childProduct1 = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-11',
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE,
                'COMM_ProductType__c' => 'single'
            }
        )[0];
        Product2 childProduct2 = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.SObjectType),
                'ProductCode' => 'ALS-12',
                'Family' => COMM_DO_Product2.CATEGORY_FASTTRACK,
                'COMM_ProductType__c' => 'single'
            }
        )[0];

        //Mock Product Configuration Record
        COMM_ProductVariations__c variationRecord1 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ProductVariations__c.SObjectType),
                'COMM_MasterProduct__c' => bundleProduct.Id,
                'COMM_RelatedProduct__c' => childProduct1.Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 4
            }
        )[0];
        variationRecord1.COMM_RelatedProduct__r = childProduct1;
        COMM_ProductVariations__c variationRecord2 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ProductVariations__c.SObjectType),
                'COMM_MasterProduct__c' => bundleProduct.Id,
                'COMM_RelatedProduct__c' => childProduct2.Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 8
            }
        )[0];
        variationRecord2.COMM_RelatedProduct__r = childProduct2;
        List<COMM_ProductVariations__c> bundleVariationList = new List<COMM_ProductVariations__c>{ variationRecord1, variationRecord2 };

        //Mock Reseller Assortment Record
        COMM_ResellerAssortment__c resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ResellerAssortment__c.SObjectType),
                'COMM_Product__c' => bundleProduct.Id,
                'COMM_Pricebook__c' => resellerPricebook.Id,
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_CurrentDailyQuantity__c' => 5,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        resellerAssortment = (COMM_ResellerAssortment__c) COMM_TestDataFactory.setField(
            resellerAssortment,
            new Map<String, Object>{
                'COMM_AvailableDailyQuantity__c' => (Integer) (resellerAssortment.COMM_DailyLimit__c -
                resellerAssortment.COMM_CurrentDailyQuantity__c)
            }
        );
        resellerAssortment.COMM_Product__r = bundleProduct;

        //Mock relationship between reseller account and assorment list
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ resellerAccount },
            COMM_ResellerAssortment__c.COMM_Account__c,
            new List<List<COMM_ResellerAssortment__c>>{ new List<COMM_ResellerAssortment__c>{ resellerAssortment } }
        );

        //Mock Pricing
        PricebookEntry testPricing = (PricebookEntry) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PricebookEntry',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(PricebookEntry.SObjectType), 'UnitPrice' => 50.00 }
        )[0];
        testPricing = (PricebookEntry) COMM_TestDataFactory.setField(
            testPricing,
            new Map<String, Object>{ 'Product2Id' => bundleProduct.Id, 'Pricebook2Id' => resellerPricebook.Id }
        );

        //Mock Mapping Result
        Map<String, Object> mappedBundleProduct = new Map<String, Object>{ 'productId' => bundleProduct.ProductCode };
        Map<String, Object> mappedChildProduct1 = new Map<String, Object>{ 'productId' => childProduct1.ProductCode };
        Map<String, Object> mappedChildProduct2 = new Map<String, Object>{ 'productId' => childProduct2.ProductCode };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getResellerAccountProducts(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(PRODUCT_VARIATION_REP.getProductVariationsByProductId((Set<Id>) fflib_Match.anyObject())).thenReturn(bundleVariationList);
        MOCKS.when(PRICEBOOK_ENTRY_REP.getPBEByProductAndPricebookIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<PricebookEntry>{ testPricing });
        MOCKS.when(
                PRICING_CALCULATION_SL.getPriceByPBE(
                    (List<PricebookEntry>) fflib_Match.anyList(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull()
                )
            )
            .thenReturn(new Map<PricebookEntry, Decimal>{ testPricing => 50.00 });
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(resellerAssortment, new Map<String, Object>())).thenReturn(mappedBundleProduct);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(bundleProduct, new Map<String, Object>())).thenReturn(mappedBundleProduct);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(childProduct1, new Map<String, Object>())).thenReturn(mappedChildProduct1);
        MOCKS.when(RESELLER_MAPPING_DO.mapJsonFromSObject(childProduct2, new Map<String, Object>())).thenReturn(mappedChildProduct2);
        MOCKS.stopStubbing();

        String requestJSON = '{"resellerId":"' + resellerAccount.Id + '","airportId":"LIS","productCategory":"Bundle","page":1,"pageSize":100}';

        Test.startTest();
        COMM_SL_WS_ResellerProducts worker = new COMM_SL_WS_ResellerProducts();
        worker = new COMM_SL_WS_ResellerProducts(
            ACCOUNT_REP,
            PRODUCT_VARIATION_REP,
            OCI_AVAILABILITY_SL,
            PRICEBOOK_ENTRY_REP,
            PRICING_CALCULATION_SL,
            RESELLER_MAPPING_DO
        );
        COMM_SL_WS_ResellerSearchResponse resultResponse = worker.getResellerStock(requestJSON);
        Test.stopTest();

        //Verify that OCI wasn't called
        ((COMM_SL_WS_OCIAvailability) mocks.verify(OCI_AVAILABILITY_SL, 0))
            .checkAvailability((COMM_WS_AvailabilityInput) fflib_Match.anyObject(), fflib_Match.anyBoolean());

        Assert.isNotNull(resultResponse, 'expected a response');
    }

    @isTest
    static void getResellerStockNoAccessTest() {
        //Scenario: Reseller send request for stock. Account was disabled as a reseller.
        //Expected: Error response is returned

        //Mock disabled Reseller Acount
        Account resellerAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Account.SObjectType), 'COMM_IsReseller__c' => false }
        )[0];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getResellerAccountProducts(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(new List<Account>{ resellerAccount });
        MOCKS.stopStubbing();

        String requestJSON =
            '{"resellerId":"' +
            resellerAccount.Id +
            '","airportId":"LIS","productCategory":"Parking",' +
            '"startDate":"2024-01-01T00:00:00","endDate":"2024-12-31T23:59:59","page":1,"pageSize":100}';

        Test.startTest();
        COMM_SL_WS_ResellerProducts worker = new COMM_SL_WS_ResellerProducts();
        worker = new COMM_SL_WS_ResellerProducts(
            ACCOUNT_REP,
            PRODUCT_VARIATION_REP,
            OCI_AVAILABILITY_SL,
            PRICEBOOK_ENTRY_REP,
            PRICING_CALCULATION_SL,
            RESELLER_MAPPING_DO
        );
        Boolean errorOccured = false;
        try {
            COMM_SL_WS_ResellerSearchResponse resultResponse = worker.getResellerStock(requestJSON);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void missingFieldsTest() {
        //Scenario: Request is received but required fields are missing
        //Expected: Exception is throwed

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_SL_WS_ResellerProducts worker = new COMM_SL_WS_ResellerProducts();
            worker = new COMM_SL_WS_ResellerProducts(
                ACCOUNT_REP,
                PRODUCT_VARIATION_REP,
                OCI_AVAILABILITY_SL,
                PRICEBOOK_ENTRY_REP,
                PRICING_CALCULATION_SL,
                RESELLER_MAPPING_DO
            );
            worker.getResellerStock('{}');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }
}