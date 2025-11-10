/**
 * @author Daniel Lascas
 * @description COMM_REP_Capacity test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024      100            Original version
 * Jose Passos      28/03/2024      100            added methods getCapacityRecordsToProcessByProductCodesTest
 * Jose Passos      10/05/2024      100            Added methods lockCapacityRecordsToProcessTest, getCapacityByProductIdsTest
 **/
@isTest
private class COMM_REP_CapacityTest {
    private final static COMM_REP_Capacity CAPACITY_REP = new COMM_REP_Capacity();

    @TestSetup
    static void makeData() {
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_1',
                'productCode' => 'OPO_P3_economy_1',
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

        List<Product2> lstProd = [SELECT ID FROM Product2 LIMIT 1];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => lstProd[0].id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => 'PENDING'
            }
        );
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => lstProd[0].id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(1),
                'COMM_Capacity__c' => 15,
                'COMM_IsDefaultCapacity__c' => false,
                'COMM_ProcessStatus__c' => 'NOT PROCESSED'
            }
        );
    }

    @isTest
    static void getNonDefaultCapacityByProductIdsTest() {
        //Scenario: One Default and one non-Default Capacity exists
        //Expected: Retrieved the existing Default Capacity by it's Product value
        List<COMM_Capacity__c> expectedList = [
            SELECT Id, COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_IsDefaultCapacity__c = FALSE
            LIMIT 1
        ];

        Test.startTest();
        List<COMM_Capacity__c> actualList = CAPACITY_REP.getNonDefaultCapacityByProductIds(
            new Set<Id>{ expectedList[0].COMM_Product__c },
            new Set<Id>()
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'the capacity found does not match expected');
    }

    @isTest
    static void getCountNonDefaultCapacityByProductIdsTest() {
        //Scenario: Two Capacity exists, one default and another non-default
        //Expected: Retrieved the counter for the non-default capacities
        List<COMM_Capacity__c> expectedList = [
            SELECT Id, COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_IsDefaultCapacity__c = FALSE
            LIMIT 1
        ];

        Test.startTest();
        List<COMM_Capacity__c> actualList = CAPACITY_REP.getCountNonDefaultCapacityByProductIds(
            new Set<Id>{ expectedList[0].COMM_Product__c },
            new Set<Id>()
        );
        Test.stopTest();

        Assert.areEqual(1, actualList.size(), 'number of found non-default capacities does not match expected');
    }

    @isTest
    static void getCountDefaultCapacityByProductIdsTest() {
        //Scenario: One Default Capacity exists
        //Expected: Retrieved the counter for the default capacities
        List<COMM_Capacity__c> expectedList = [
            SELECT Id, COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_IsDefaultCapacity__c = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<COMM_Capacity__c> actualList = CAPACITY_REP.getCountDefaultCapacityByProductIds(
            new Set<Id>{ expectedList[0].COMM_Product__c },
            new Set<Id>()
        );
        Test.stopTest();

        Assert.areEqual(1, actualList.size(), 'number of found default capacities does not match expected');
    }

    @isTest
    static void getCapacityRecordsToProcessByProductCodesTest() {
        //Scenario: Several records for the same product with different process status
        //Expected: Ensure the query returns the same number of records passing those same process status
        List<COMM_Capacity__c> expectedList = [
            SELECT COMM_Product__r.ProductCode, COMM_ProcessStatus__c
            FROM COMM_Capacity__c
            WHERE COMM_ProcessStatus__c IN ('NOT PROCESSED', 'PENDING') AND COMM_Product__r.ProductCode = 'OPO_P3_economy_1'
        ];
        List<String> productsList = new List<String>();
        productsList.add(expectedList[0].COMM_Product__r.ProductCode);

        List<String> statusList = new List<String>{ 'NOT PROCESSED', 'PENDING' };

        Test.startTest();
        List<COMM_Capacity__c> actualList = CAPACITY_REP.getCapacityRecordsToProcessByProductCodes(productsList, statusList);
        Test.stopTest();

        Assert.areEqual(expectedList.size(), actualList.size(), 'Number of records does not match');
    }

    @isTest
    static void lockCapacityRecordsToProcessTest() {
        Boolean recordsLocked = false;
        // Create test data
        List<COMM_Capacity__c> capacityIdList = [
            SELECT id
            FROM COMM_Capacity__c
            WHERE COMM_Product__r.ProductCode = 'OPO_P3_economy_1'
        ];
        Set<Id> ids = new Set<Id>(new Map<Id, COMM_Capacity__c>(capacityIdList).keySet());

        // Call the method to be tested
        Test.startTest();
        try {
            CAPACITY_REP.lockCapacityRecords(ids);
            recordsLocked = true;
        } catch (DmlException e) {
            recordsLocked = false;
        }
        Test.stopTest();

        Assert.areEqual(true, recordsLocked, 'Records not locked');
    }

    @isTest
    static void getCapacityByProductIdsTest() {
        List<Product2> productIdList = [
            SELECT id
            FROM Product2
            WHERE ProductCode = 'OPO_P3_economy_1'
        ];
        Set<String> productIds = new Set<String>(new Map<String, Product2>(productIdList).keySet());

        List<COMM_Capacity__c> expectedCapacityList = [
            SELECT id, COMM_Active__c
            FROM COMM_Capacity__c
            WHERE COMM_Product__c IN :productIds
        ];

        // Call the method to be tested
        Test.startTest();
        List<COMM_Capacity__c> resultCapacityList = CAPACITY_REP.getCapacityByProductIds(productIds);
        Test.stopTest();

        Assert.areEqual(expectedCapacityList.size(), resultCapacityList.size(), 'Expected records do not match');
    }
}