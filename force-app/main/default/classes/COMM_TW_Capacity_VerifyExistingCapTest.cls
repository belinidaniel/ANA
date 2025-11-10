/**
 * @author Daniel Lascas
 * @description COMM_TW_Capacity_VerifyExistingCapacity test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024      100            Original version
 **/
@isTest
private class COMM_TW_Capacity_VerifyExistingCapTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Capacity CAPACITY_REP = (COMM_REP_Capacity) MOCKS.mock(COMM_REP_Capacity.class);

    @isTest
    static void noDuplicateTest() {
        //Scenario: Capacity Record's Valid To is updated. There are no Capacity Records with the same values.
        //Expected: Trigger doesn't add validation error to updated record
        COMM_Capacity__c oldCapacity = new COMM_Capacity__c();
        oldCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        oldCapacity.COMM_ValidFrom__c = Datetime.now();
        oldCapacity.COMM_ValidTo__c = Datetime.now().addDays(1);
        oldCapacity.COMM_Capacity__c = 10;

        COMM_Capacity__c newCapacity = oldCapacity.clone(true);
        newCapacity.COMM_ValidTo__c = Datetime.now().addDays(2);

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ oldCapacity.Id => oldCapacity };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(CAPACITY_REP.getNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyExistingCapacity worker = new COMM_TW_Capacity_VerifyExistingCapacity();
        worker = new COMM_TW_Capacity_VerifyExistingCapacity(CAPACITY_REP);
        worker.execute(newCapacityList, oldCapacityMap);
        Test.stopTest();

        Assert.isFalse(newCapacity.hasErrors(), 'expected trigger to not add errors');
    }

    @isTest
    static void duplicateFoundTest() {
        //Scenario: Capacity Record's Product is updated. There exists a Capacity Records with the same values.
        //Expected: Trigger adds validation error to updated record
        COMM_Capacity__c oldCapacity = new COMM_Capacity__c();
        oldCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        oldCapacity.COMM_ValidFrom__c = Datetime.now();
        oldCapacity.COMM_ValidTo__c = Datetime.now().addDays(1);
        oldCapacity.COMM_Capacity__c = 10;

        COMM_Capacity__c newCapacity = oldCapacity.clone(true);
        newCapacity.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ oldCapacity.Id => oldCapacity };

        COMM_Capacity__c existingCapacity = new COMM_Capacity__c();
        existingCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        existingCapacity.COMM_Product__c = newCapacity.COMM_Product__c;
        existingCapacity.COMM_ValidFrom__c = oldCapacity.COMM_ValidFrom__c;
        existingCapacity.COMM_ValidTo__c = oldCapacity.COMM_ValidTo__c;
        existingCapacity.COMM_Capacity__c = 20;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(CAPACITY_REP.getNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>{ existingCapacity });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyExistingCapacity worker = new COMM_TW_Capacity_VerifyExistingCapacity();
        worker = new COMM_TW_Capacity_VerifyExistingCapacity(CAPACITY_REP);
        worker.execute(newCapacityList, oldCapacityMap);
        Test.stopTest();

        Assert.isTrue(newCapacity.hasErrors(), 'expected trigger to add errors');
    }

    @isTest
    static void duplicateFoundInTriggerRecordTest() {
        //Scenario: Four Capacity Record's are inserted but with the same values
        //Expected: Trigger adds validation error to second and third record. First and fourth has no error.
        COMM_Capacity__c newCapacity1 = new COMM_Capacity__c();
        newCapacity1.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        newCapacity1.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        newCapacity1.COMM_ValidFrom__c = Datetime.now();
        newCapacity1.COMM_ValidTo__c = Datetime.now().addDays(1);
        newCapacity1.COMM_Capacity__c = 10;

        COMM_Capacity__c newCapacity2 = newCapacity1.clone();
        newCapacity2.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);

        COMM_Capacity__c newCapacity3 = newCapacity1.clone();
        newCapacity3.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        newCapacity3.COMM_ValidFrom__c = newCapacity1.COMM_ValidFrom__c.addHours(-2);
        newCapacity3.COMM_ValidTo__c = newCapacity1.COMM_ValidTo__c.addHours(-1);

        COMM_Capacity__c newCapacity4 = newCapacity1.clone();
        newCapacity4.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        newCapacity4.COMM_ValidFrom__c = newCapacity1.COMM_ValidTo__c;
        newCapacity4.COMM_ValidTo__c = newCapacity1.COMM_ValidTo__c.addDays(1);

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity1, newCapacity2, newCapacity3, newCapacity4 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(CAPACITY_REP.getNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyExistingCapacity worker = new COMM_TW_Capacity_VerifyExistingCapacity();
        worker = new COMM_TW_Capacity_VerifyExistingCapacity(CAPACITY_REP);
        worker.execute(newCapacityList, null);
        Test.stopTest();

        Assert.isFalse(newCapacity1.hasErrors(), 'expected trigger to not add errors to first record');
        Assert.isTrue(newCapacity2.hasErrors(), 'expected trigger to add errors to second record');
        Assert.isTrue(newCapacity3.hasErrors(), 'expected trigger to add errors to third record');
        Assert.isFalse(newCapacity4.hasErrors(), 'expected trigger to not add errors to fourth record');
    }
}