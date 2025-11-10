/**
 * @author Jose Passos
 * @description COMM_SL_OCIStockGeneration test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      12/03/2024      97             Original version
 * Jose Passos      15/05/2024      97             Update makeData method
 **/
@isTest
private class COMM_SL_OCIStockGenerationTest {
    @TestSetup
    static void makeData() {
        List<Product2> productList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_1',
                'productCode' => 'OPO_P3_economy_1',
                'description' => 'OPO_P3_economy_1',
                'stockKeepingUnit' => 'OPO_P3_economy_1',
                'family' => 'Parking',
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Capacity__c' => 50,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addDays(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(4),
                'COMM_ProcessStatus__c' => 'NOT PROCESSED'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Capacity__c' => 25,
                'COMM_IsDefaultCapacity__c' => false,
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addDays(2),
                'COMM_ValidTo__c' => Datetime.now().addDays(3),
                'COMM_ProcessStatus__c' => 'NOT PROCESSED'
            }
        );

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Capacity__c' => 5,
                'COMM_Product__c' => productList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addDays(4),
                'COMM_ValidTo__c' => Datetime.now().addDays(5),
                'COMM_ProcessStatus__c' => 'PENDING',
                'COMM_ProcessId__c' => '123'
            }
        );

        Product2 product = productList[0];
        product.isActive = true;
        upsert product;
    }

    @isTest
    private static void uploadStockTest() {
        //Scenario: Batch to generate stock records is initiated
        //Expected: Rep to update product records is called and no error occurs
        List<Product2> lstProd = [SELECT ID, ProductCode FROM Product2];

        List<String> productList = new List<String>();
        productList.add(lstProd[0].ProductCode);

        List<COMM_Capacity__c> capacityRecsToProcess = [
            SELECT id, COMM_Product__r.ProductCode, COMM_ValidFrom__c, COMM_ValidTo__c, COMM_CalculatedCapacity__c
            FROM COMM_Capacity__c
            WHERE COMM_ProcessStatus__c = 'NOT PROCESSED'
        ];

        COMM_SL_OCIStockGeneration stockGenerationService = new COMM_SL_OCIStockGeneration();

        Test.startTest();
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output;
        output = stockGenerationService.uploadStock(capacityRecsToProcess);
        Test.stopTest();

        System.assert(output.uploadId != null, 'expected a process uploadId.');
    }

    @isTest
    private static void getProcessStatusTest() {
        //Scenario: Batch to generate stock records is initiated
        //Expected: Rep to update product records is called and no error occurs
        List<Product2> lstProd = [SELECT ID, ProductCode FROM Product2];

        List<String> productList = new List<String>();
        productList.add(lstProd[0].ProductCode);

        List<COMM_Capacity__c> capacityRecsToProcess = [
            SELECT id, COMM_Product__r.ProductCode, COMM_ProcessId__c
            FROM COMM_Capacity__c
            WHERE COMM_ProcessStatus__c = 'PENDING'
            LIMIT 1
        ];

        COMM_SL_OCIStockGeneration stockGenerationService = new COMM_SL_OCIStockGeneration();
        List<String> errorMessageList = new List<String>();

        Test.startTest();
        String jobIdStatus = stockGenerationService.getJobIdStatus(capacityRecsToProcess[0].COMM_ProcessId__c, errorMessageList);
        Test.stopTest();

        // This will call an internall mock that will return a 'COMPLETED' status but with some validation errors
        System.assertEquals(jobIdStatus, 'FAILED', 'expected status = FAILED with some errors.');
    }
}