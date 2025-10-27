/**
 * @author Daniel Reto
 * @description COMM_SL_GetProductByPeriodicity test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)     Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      01/05/2024      100             Original version
 **/
@isTest
private class COMM_SL_GetProductByPeriodicityTest {
    @TestSetup
    static void makeData() {
        List<Object> customPbs = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Pricebook2',
            new Map<String, Object>{
                'Name' => 'Custom Subscription Price Book',
                'Description' => 'Custom Subscription Price Book',
                'IsActive' => true,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2)
            }
        );

        Pricebook2 customPb = (Pricebook2) customPbs[0];
        Time myTime = Time.newInstance(1, 2, 3, 0);
        // Insert Parent Product
        List<Product2> parentProducts = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Subscription Service',
                'ProductCode' => 'P0',
                'Description' => 'Subscription Service',
                'IsActive' => false,
                'Family' => 'Subscription',
                'COMM_WhereProductAvailable__c' => 'Subscriptions Portal',
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        // Insert Parent Product Capacity
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addDays(2),
                'COMM_Capacity__c' => 10,
                'COMM_Product__c' => parentProducts[0].Id,
                'COMM_IsDefaultCapacity__c' => true,
                'RecordTypeId' => Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        // Insert Child Product
        List<Product2> childProducts = (List<Product2>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Subscription Service',
                'ProductCode' => 'P0-0000',
                'Description' => 'Subscription Service',
                'IsActive' => false,
                'Family' => 'Subscription',
                'COMM_WhereProductAvailable__c' => 'Subscriptions Portal',
                'COMM_ParentProduct__c' => parentProducts[0].Id,
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
                'COMM_PaymentType__c' => 'Credit',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );
        childProducts[1].ProductCode = 'P0-0001';
        childProducts[1].COMM_Periodicity__c = 'Quarterly';
        insert childProducts;

        List<Product2> updatedProducts = (List<Product2>) COMM_TestDataFactory.updateRecords(
            new List<Id>{ parentProducts[0].Id },
            'Product2',
            new Map<String, Object>{ 'IsActive' => true }
        );

        List<Product2> updatedChildProducts = (List<Product2>) COMM_TestDataFactory.updateRecords(
            new List<Id>{ childProducts[0].Id, childProducts[1].Id },
            'Product2',
            new Map<String, Object>{ 'COMM_ParentProduct__c' => parentProducts[0].Id, 'IsActive' => true }
        );

        // Insert PricebookEntrys for Standard Pricebook
        List<PricebookEntry> pricebookEntrys = (List<PricebookEntry>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'PricebookEntry',
            new Map<String, Object>{
                'Pricebook2Id' => Test.getStandardPricebookId(),
                'Product2Id' => childProducts[0].Id,
                'UnitPrice' => 50,
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
        pricebookEntrys[1].Product2Id = childProducts[1].Id;
        pricebookEntrys[1].UnitPrice = 90;
        insert pricebookEntrys;

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

    @isTest
    static void getProductByPeriodicityTest() {
        List<List<COMM_SL_FlowChoice>> productFlowChoice = new List<List<COMM_SL_FlowChoice>>();
        List<List<Product2>> productListList = new List<List<Product2>>{ new List<Product2>{ new Product2(ProductCode = 'P0-0000') } };

        Test.startTest();
        productFlowChoice = COMM_SL_GetProductByPeriodicity.getProductByPeriodicity(productListList);
        Test.stopTest();

        Assert.isFalse(productFlowChoice.isEmpty(), 'List of product pricing information should not be empty');
    }
}