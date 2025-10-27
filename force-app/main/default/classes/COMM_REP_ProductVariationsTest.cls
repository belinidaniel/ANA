/**
 * @author           Daniel Lascas
 * @description      COMM_REP_ProductVariations test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    07/06/2024      100            ECOMM-386: Original version
 **/
@isTest
private class COMM_REP_ProductVariationsTest {
    @TestSetup
    static void makeData() {
        // Insert Product2
        Time myTime = Time.newInstance(1, 2, 3, 0);
        Product2 bundleProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Parking Service Bundle',
                'ProductCode' => 'PS_B',
                'Description' => 'Parking Service Bundle',
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
                'COMM_SubCategory__c' => 'Park',
                'COMM_ProductType__c' => 'bundle'
            }
        )[0];

        Product2 singleProduct = (Product2) COMM_TestDataFactory.insertRecords(
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
                'COMM_SubCategory__c' => 'Park',
                'COMM_ProductType__c' => 'single'
            }
        )[0];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'COMM_MasterProduct__c' => bundleProduct.Id,
                'COMM_RelatedProduct__c' => singleProduct.Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 4
            }
        );
    }

    @isTest
    static void getProductVariationsByProductIdTest() {
        List<COMM_ProductVariations__c> expectedList = [SELECT Id, COMM_MasterProduct__c FROM COMM_ProductVariations__c];

        Test.startTest();
        List<COMM_ProductVariations__c> resultList = new COMM_REP_ProductVariations()
            .getProductVariationsByProductId(new Set<Id>{ expectedList[0].COMM_MasterProduct__c });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, resultList[0].Id, 'resulting variation does not match expected');
    }
    
    @isTest
    static void getProductVariationsByMasterProductTest() {
        Set<String> masterProductCodes = new Set<String>();
        masterProductCodes.add('ProdCode1');
        COMM_IREP_ProductVariations variationRepo = new COMM_REP_ProductVariations();
        List<COMM_ProductVariations__c> prodVariationList = variationRepo.getProductVariationsByMasterProduct(masterProductCodes);
        Assert.areEqual(
            prodVariationList.size(),
            [SELECT Id FROM COMM_ProductVariations__c WHERE COMM_MasterProduct__r.ProductCode IN :masterProductCodes].size(),
            'The actual record size does not match the expected size'
        );
    }
}