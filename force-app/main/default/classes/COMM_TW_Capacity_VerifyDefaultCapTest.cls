/**
 * @author Daniel Lascas
 * @description COMM_TW_Capacity_VerifyDefaultCapacities test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/02/2024      100            Original version
 **/
@isTest
private class COMM_TW_Capacity_VerifyDefaultCapTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Capacity CAPACITY_REP = (COMM_REP_Capacity) MOCKS.mock(COMM_REP_Capacity.class);
    private final static COMM_IREP_Product2 PRODUCT_REP = (COMM_IREP_Product2) MOCKS.mock(COMM_IREP_Product2.class);

    @isTest
    static void noExistingDefaultTest() {
        //Scenario: Two Capacity Record are inserted for a given Product with the second being a Default Capacity. There are no Default Capacity Records for the Product.
        //Expected: Trigger doesn't add validation error to inserted records
        COMM_Capacity__c newCapacity1 = new COMM_Capacity__c();
        newCapacity1.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        newCapacity1.COMM_IsDefaultCapacity__c = false;

        COMM_Capacity__c newCapacity2 = new COMM_Capacity__c();
        newCapacity2.COMM_Product__c = newCapacity1.COMM_Product__c;
        newCapacity2.COMM_IsDefaultCapacity__c = true;

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity1, newCapacity2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>());
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(newCapacityList, null, false);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isFalse(newCapacity1.hasErrors(), 'expected trigger to not add errors');
        Assert.isFalse(newCapacity2.hasErrors(), 'expected trigger to not add errors');
    }

    @isTest
    static void noExistingDefaultFailureTest() {
        //Scenario: Two Capacity Record are inserted for a given Product, none are Default. There are no Default Capacity Records for the Product.
        //Expected: Trigger adds validation error to inserted records
        COMM_Capacity__c newCapacity1 = new COMM_Capacity__c();
        newCapacity1.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        newCapacity1.COMM_IsDefaultCapacity__c = false;

        COMM_Capacity__c newCapacity2 = new COMM_Capacity__c();
        newCapacity2.COMM_Product__c = newCapacity1.COMM_Product__c;
        newCapacity2.COMM_IsDefaultCapacity__c = false;

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity1, newCapacity2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>());
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(newCapacityList, null, false);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(newCapacity1.hasErrors(), 'expected trigger to add errors');
        Assert.isTrue(newCapacity2.hasErrors(), 'expected trigger to add errors');
    }

    @isTest
    static void existingDefaultUpdateTest() {
        //Scenario: A Capacity Record is updated to Default. There is an existing Default Capacity Records for the same Product.
        //Expected: Trigger adds validation error to updated record
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        );

        COMM_Capacity__c oldCapacity = new COMM_Capacity__c();
        oldCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity.COMM_Product__c = capacityList[0].COMM_Product__c;
        oldCapacity.COMM_IsDefaultCapacity__c = false;

        COMM_Capacity__c newCapacity = oldCapacity.clone(true);
        newCapacity.COMM_ValidFrom__c = Datetime.now().addDays(1);
        newCapacity.COMM_IsDefaultCapacity__c = true;

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ oldCapacity.Id => oldCapacity };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>());
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(capacityList);
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<AggregateResult>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(newCapacityList, oldCapacityMap, false);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(newCapacity.hasErrors(), 'expected trigger to add errors');
    }

    @isTest
    static void updateProductOnDefaultTest() {
        //Scenario: A Default Capacity Record's Product Lookup is updated to another. The current Product is Active and the new Product doesn't have a Default Capacity.
        //Expected: Trigger adds validation error to updated record

        //Insert Existing Active Product
        Product2 activeProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Test Product',
                'ProductCode' => 'test',
                'Description' => 'Product to test capacity logic',
                'Family' => 'Lounge',
                'COMM_SubCategory__c' => 'Lounge',
                'COMM_Airport__c' => 'PDL',
                'COMM_Tax__c' => 'Azores',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(20, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => Datetime.now().addDays(3),
                'COMM_ValidTo__c' => Datetime.now().addDays(4)
            }
        )[0];

        //Insert Capacity to Activate the Product
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => activeProduct.Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        );

        activeProduct.IsActive = true;
        update activeProduct;

        COMM_Capacity__c oldCapacity = new COMM_Capacity__c();
        oldCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity.COMM_Product__c = capacityList[0].COMM_Product__c;
        oldCapacity.COMM_IsDefaultCapacity__c = true;

        COMM_Capacity__c newCapacity = oldCapacity.clone(true);
        newCapacity.COMM_Product__c = fflib_IDGenerator.generate(Product2.sObjectType);

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ oldCapacity.Id => oldCapacity };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>{ activeProduct });
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(newCapacityList, oldCapacityMap, false);
        Test.stopTest();

        ((COMM_IREP_Product2) mocks.verify(PRODUCT_REP, 1)).getActiveProductsByIds(new Set<Id>{ activeProduct.Id });
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(newCapacity.hasErrors(), 'expected trigger to add errors');
    }

    @isTest
    static void updateProductOnDefaultBulkTest() {
        //Scenario: A Default Capacity Record's Product Lookup is updated to another. The current Product is Active and the new Product doesn't have a Default Capacity.
        //Expected: Trigger adds validation error to updated record

        //Insert Existing Active Product
        Product2 activeProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Test Product',
                'ProductCode' => 'test',
                'Description' => 'Product to test capacity logic',
                'Family' => 'Lounge',
                'COMM_SubCategory__c' => 'Lounge',
                'COMM_Airport__c' => 'PDL',
                'COMM_Tax__c' => 'Azores',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(20, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => Datetime.now().addDays(3),
                'COMM_ValidTo__c' => Datetime.now().addDays(4)
            }
        )[0];

        //Insert Capacity to Activate the Product
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => activeProduct.Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        );

        activeProduct.IsActive = true;
        update activeProduct;

        COMM_Capacity__c oldCapacity = new COMM_Capacity__c();
        oldCapacity.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity.COMM_Product__c = capacityList[0].COMM_Product__c;
        oldCapacity.COMM_IsDefaultCapacity__c = true;

        COMM_Capacity__c newCapacity = oldCapacity.clone(true);
        newCapacity.COMM_Product__c = fflib_IDGenerator.generate(Product2.sObjectType);

        COMM_Capacity__c oldCapacity2 = new COMM_Capacity__c();
        oldCapacity2.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        oldCapacity2.COMM_Product__c = capacityList[0].COMM_Product__c;
        oldCapacity2.COMM_Capacity__c = 10;
        oldCapacity2.COMM_IsDefaultCapacity__c = false;

        COMM_Capacity__c newCapacity2 = oldCapacity2.clone(true);
        newCapacity2.COMM_Capacity__c = 20;

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity, newCapacity2 };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ oldCapacity.Id => oldCapacity, oldCapacity2.Id => oldCapacity2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>{ activeProduct });
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(newCapacityList, oldCapacityMap, false);
        Test.stopTest();

        ((COMM_IREP_Product2) mocks.verify(PRODUCT_REP, 1)).getActiveProductsByIds(new Set<Id>{ activeProduct.Id });
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(newCapacity.hasErrors(), 'expected trigger to add errors');
        Assert.isTrue(newCapacity2.hasErrors(), 'expected trigger to add errors');
    }

    @isTest
    static void existingDefaultUpdateWithBulkTest() {
        //Scenario: Three Capacity Record are updated for the same Product, the last two in the list being set to Default. There is an existing Default Capacity Records for the same Product.
        //Expected: Trigger adds validation error to updated records to Default
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => true
            }
        );

        COMM_Capacity__c newCapacity1 = new COMM_Capacity__c();
        newCapacity1.COMM_Product__c = capacityList[0].COMM_Product__c;
        newCapacity1.COMM_IsDefaultCapacity__c = false;
        newCapacity1.COMM_ValidFrom__c = Datetime.now().addHours(2);

        COMM_Capacity__c newCapacity2 = new COMM_Capacity__c();
        newCapacity2.COMM_Product__c = capacityList[0].COMM_Product__c;
        newCapacity2.COMM_IsDefaultCapacity__c = true;
        newCapacity2.COMM_ValidFrom__c = Datetime.now().addHours(2);

        COMM_Capacity__c newCapacity3 = new COMM_Capacity__c();
        newCapacity3.COMM_Product__c = capacityList[0].COMM_Product__c;
        newCapacity3.COMM_IsDefaultCapacity__c = true;
        newCapacity3.COMM_ValidFrom__c = Datetime.now().addDays(1);

        COMM_Capacity__c newCapacity4 = new COMM_Capacity__c();
        newCapacity4.COMM_Product__c = capacityList[0].COMM_Product__c;
        newCapacity4.COMM_IsDefaultCapacity__c = true;
        newCapacity4.COMM_ValidFrom__c = Datetime.now().addDays(3);

        List<COMM_Capacity__c> newCapacityList = new List<COMM_Capacity__c>{ newCapacity1, newCapacity2, newCapacity3, newCapacity4 };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{
            newCapacity1.Id => newCapacity1,
            newCapacity2.Id => newCapacity2,
            newCapacity3.Id => newCapacity3,
            newCapacity4.Id => newCapacity4
        };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>());
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(capacityList);
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        System.debug('**** new cap list size: ' + newCapacityList.size());
        worker.execute(newCapacityList, oldCapacityMap, false);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isFalse(newCapacity1.hasErrors(), 'expected trigger to not add errors');
        Assert.isTrue(newCapacity2.hasErrors(), 'expected trigger to add errors');
        Assert.isTrue(newCapacity3.hasErrors(), 'expected trigger to add errors');
        Assert.isFalse(newCapacity4.hasErrors(), 'expected trigger to not add errors');
    }

    @isTest
    static void deleteDefaultTest() {
        //Scenario: Three Default Capacity Record are set for deletion. Product of first one has non-default capacities, Product of second and third does not.
        //Expected: Trigger adds validation error to first record, second and third records doesnn't
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => false
            }
        );
        capacityList[0].COMM_IsDefaultCapacity__c = true;
        insert capacityList;

        List<COMM_Capacity__c> expectedResultList = [
            SELECT COMM_Product__c
            FROM COMM_Capacity__c
            WHERE COMM_IsDefaultCapacity__c = FALSE
        ];

        COMM_Capacity__c deletedDefault1 = capacityList[0];
        deletedDefault1 = (COMM_Capacity__c) COMM_TestDataFactory.setField(deletedDefault1, new Map<String, Object>{ 'COMM_Active__c' => true });

        COMM_Capacity__c deletedDefault2 = new COMM_Capacity__c();
        deletedDefault2.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        deletedDefault2.COMM_Product__c = fflib_IDGenerator.generate(Product2.sobjectType);
        deletedDefault2.COMM_IsDefaultCapacity__c = true;
        deletedDefault2 = (COMM_Capacity__c) COMM_TestDataFactory.setField(deletedDefault2, new Map<String, Object>{ 'COMM_Active__c' => true });

        COMM_Capacity__c deletedDefault3 = new COMM_Capacity__c();
        deletedDefault3.Id = fflib_IDGenerator.generate(COMM_Capacity__c.sobjectType);
        deletedDefault3.COMM_Product__c = deletedDefault2.COMM_Product__c;
        deletedDefault3.COMM_IsDefaultCapacity__c = true;
        deletedDefault3 = (COMM_Capacity__c) COMM_TestDataFactory.setField(deletedDefault3, new Map<String, Object>{ 'COMM_Active__c' => true });

        List<COMM_Capacity__c> deletedList = new List<COMM_Capacity__c>{ deletedDefault1, deletedDefault2, deletedDefault3 };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{
            deletedDefault1.Id => deletedDefault1,
            deletedDefault2.Id => deletedDefault2,
            deletedDefault3.Id => deletedDefault3
        };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>());
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(expectedResultList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(deletedList, oldCapacityMap, true);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 1))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(deletedDefault1.hasErrors(), 'expected trigger to add errors');
        Assert.isFalse(deletedDefault2.hasErrors(), 'expected trigger to not add errors');
        Assert.isFalse(deletedDefault3.hasErrors(), 'expected trigger to not add errors');
    }

    @isTest
    static void deleteDefaultWithActiveCapacityTest() {
        //Scenario: A Default Capacity Record is set for deletion. Product is Active.
        //Expected: Trigger adds validation error.
        List<COMM_Capacity__c> capacityList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_IsDefaultCapacity__c' => false
            }
        );
        capacityList[0].COMM_IsDefaultCapacity__c = true;
        insert capacityList;

        List<COMM_Capacity__c> expectedResultList = [
            SELECT COMM_Product__c
            FROM COMM_Capacity__c
            WHERE COMM_IsDefaultCapacity__c = FALSE
        ];

        Product2 mockedProduct = new Product2(Id = capacityList[0].COMM_Product__c, IsActive = true);

        COMM_Capacity__c deletedDefault1 = capacityList[0];
        deletedDefault1 = (COMM_Capacity__c) COMM_TestDataFactory.setField(deletedDefault1, new Map<String, Object>{ 'COMM_Active__c' => true });

        List<COMM_Capacity__c> deletedList = new List<COMM_Capacity__c>{ deletedDefault1 };
        Map<Id, COMM_Capacity__c> oldCapacityMap = new Map<Id, COMM_Capacity__c>{ deletedDefault1.Id => deletedDefault1 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCT_REP.getActiveProductsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new List<Product2>{ mockedProduct });
        MOCKS.when(CAPACITY_REP.getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(new List<COMM_Capacity__c>());
        MOCKS.when(CAPACITY_REP.getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject()))
            .thenReturn(expectedResultList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Capacity_VerifyDefaultCapacities worker = new COMM_TW_Capacity_VerifyDefaultCapacities();
        worker = new COMM_TW_Capacity_VerifyDefaultCapacities(CAPACITY_REP, PRODUCT_REP);
        worker.execute(deletedList, oldCapacityMap, true);
        Test.stopTest();

        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_Capacity) mocks.verify(CAPACITY_REP, 0))
            .getCountNonDefaultCapacityByProductIds((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        Assert.isTrue(deletedDefault1.hasErrors(), 'expected trigger to add errors');
    }
}