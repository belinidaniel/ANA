/**
 * @author Daniel Reto
 * @description COMM_REP_CaCOMM_REP_Subscriptionpacity test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)     Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      17/04/2024      100             Original version
 * Daniel Reto      03/05/2024		100             ECOMM-1027
 * Daniel Lascas    19/06/2024		100             Added getSubscriptionsByAccountIdTest
 * Daniel Reto      12/11/2024      100             Added getSubscriptionsByIdTest
 **/
@isTest
private class COMM_REP_SubscriptionTest {
    private final static COMM_REP_Subscription SUBSCRIPTION_REP = new COMM_REP_Subscription();

    @TestSetup
    static void makeData() {
        Date endDateValue = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));

        List<Product2> parentProductList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_1',
                'ProductCode' => 'OPO_P3_economy_1',
                'Family' => 'Parking',
                'IsActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId,
                'Description' => 'Test'
            }
        );

        List<Product2> childProductList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'OPO_P3_economy_2',
                'ProductCode' => 'OPO_P3_economy_2',
                'Family' => 'Parking',
                'IsActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId,
                'COMM_ParentProduct__c' => parentProductList[0].Id,
                'COMM_WhereProductAvailable__c' => 'eCommerce',
                'Description' => 'Test'
            }
        );

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => parentProductList[0].Id,
                'COMM_ValidFrom__c' => Datetime.now().addHours(1),
                'COMM_ValidTo__c' => Datetime.now().addYears(2),
                'COMM_Capacity__c' => 100,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
            }
        );

        List<Account> accountRecordList = (List<Account>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{ 'FirstName' => 'Test', 'LastName' => 'User', 'PersonEmail' => 'test@user.com.invalid' }
        );

        List<Contact> contactRecordList = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{ 'LastName' => 'Contact', 'FirstName' => 'Portal' }
        );

        List<Order> orderList = (List<Order>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Order',
            new Map<String, Object>{
                'AccountId' => accountRecordList[0].Id,
                'EffectiveDate' => System.today(),
                'EndDate' => System.today().addMonths(1),
                'Status' => 'Draft'
            }
        );

        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'COMM_Account__c' => accountRecordList[0].Id,
                'COMM_Contact__c' => contactRecordList[0].Id,
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => true,
                'COMM_CancellationDate__c' => Date.today(),
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Contact__c' => contactRecordList[0].Id,
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => Date.today().addYears(1),
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => Date.today().addYears(1),
                'COMM_Order__c' => orderList[0].Id,
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_YEARLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => childProductList[0].Id,
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
                    .get(COMM_DO_Subscription.RECORDTYPE_PARTNER)
                    .RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(), 12, Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321'
            }
        );
    }

    @isTest
    static void getSubscriptionsByParentProductIdsTest() {
        List<Product2> parentProductList = [
            SELECT Id
            FROM Product2
            WHERE COMM_ParentProduct__c = NULL
        ];
        Set<String> parentProdcutIdSet = new Set<String>();
        for (Product2 productRecord : parentProductList) {
            parentProdcutIdSet.add(productRecord.Id);
        }

        Test.startTest();
        List<COMM_Subscription__c> actualList = SUBSCRIPTION_REP.getSubscriptionsByParentProductIds(parentProdcutIdSet);
        Test.stopTest();

        COMM_Subscription__c expectedSubscriptionRecord = [
            SELECT Id, COMM_OCIEndDate__c, COMM_Product__c, COMM_Product__r.ProductCode, COMM_Product__r.COMM_ParentProduct__c
            FROM COMM_Subscription__c
        ];

        Assert.areEqual(expectedSubscriptionRecord.Id, actualList[0].Id, 'the Subscriptions found does not match expected');
        Assert.areEqual(
            expectedSubscriptionRecord.COMM_OCIEndDate__c,
            actualList[0].COMM_OCIEndDate__c,
            'the Subscriptions found does not match expected'
        );
        Assert.areEqual(expectedSubscriptionRecord.COMM_Product__c, actualList[0].COMM_Product__c, 'the Subscriptions found does not match expected');
        Assert.areEqual(
            expectedSubscriptionRecord.COMM_Product__r.ProductCode,
            actualList[0].COMM_Product__r.ProductCode,
            'the Subscriptions found does not match expected'
        );
        Assert.areEqual(
            expectedSubscriptionRecord.COMM_Product__r.COMM_ParentProduct__c,
            actualList[0].COMM_Product__r.COMM_ParentProduct__c,
            'the Subscriptions found does not match expected'
        );
    }

    @isTest
    static void getSubscriptionsByIdsTest() {
        List<COMM_Subscription__c> subscriptionList = [
            SELECT Id
            FROM COMM_Subscription__c
        ];
        Set<Id> subscriptionSet = new Set<Id>();
        for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
            subscriptionSet.add(subscriptionRecord.Id);
        }

        Test.startTest();
        List<COMM_Subscription__c> actualList = SUBSCRIPTION_REP.getSubscriptionsByIds(subscriptionSet);
        Test.stopTest();

        COMM_Subscription__c expectedSubscriptionRecord = [
            SELECT Id, COMM_Account__c, COMM_Product__c, COMM_Price__c
            FROM COMM_Subscription__c
        ];

        Assert.areEqual(expectedSubscriptionRecord.Id, actualList[0].Id, 'the Subscriptions found does not match expected');
        Assert.areEqual(expectedSubscriptionRecord.COMM_Account__c, actualList[0].COMM_Account__c, 'the Subscriptions found does not match expected');
        Assert.areEqual(expectedSubscriptionRecord.COMM_Product__c, actualList[0].COMM_Product__c, 'the Subscriptions found does not match expected');
        Assert.areEqual(expectedSubscriptionRecord.COMM_Price__c, actualList[0].COMM_Price__c, 'the Subscriptions found does not match expected');
    }

    @isTest
    static void getSubscriptionsByAccountIdTest() {
        List<COMM_Subscription__c> expectedList = [
            SELECT
                Id,
                COMM_Account__c,
                COMM_Contact__c,
                COMM_StartDate__c,
                COMM_EndDate__c,
                COMM_Order__r.OrderNumber,
                COMM_Order__r.EffectiveDate,
                COMM_Order__r.EndDate,
                COMM_Product__r.COMM_Airport__c,
                COMM_Active__c,
                COMM_LicensePlate__c,
            	COMM_SecondaryLicensePlate__c 
            FROM COMM_Subscription__c
        ];

        Test.startTest();
        List<COMM_Subscription__c> actualList = SUBSCRIPTION_REP.getSubscriptionsByAccountId(
            expectedList[0].COMM_Account__c,
            expectedList[0].COMM_Contact__c,
            expectedList[0].COMM_StartDate__c,
            expectedList[0].COMM_EndDate__c,
            expectedList[0].COMM_Order__r.EffectiveDate,
            expectedList[0].COMM_Order__r.EndDate,
            expectedList[0].COMM_Order__r.OrderNumber,
            new List<String>{ expectedList[0].COMM_Product__r.COMM_Airport__c },
            expectedList[0].COMM_Active__c,
            expectedList[0].COMM_LicensePlate__c,
            expectedList[0].COMM_SecondaryLicensePlate__c
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'retrieved subscription does not match expected');
    }

    @isTest
    static void getSubscriptionsByProductIdsTest() {
        List<COMM_Subscription__c> subscriptionList = [
            SELECT Id, COMM_Product__c
            FROM COMM_Subscription__c
            WHERE COMM_Product__c != NULL
        ];

        Test.startTest();
        List<COMM_Subscription__c> actualList = SUBSCRIPTION_REP.getSubscriptionsByProductIds(new Set<Id>{ subscriptionList[0].COMM_Product__c });
        Test.stopTest();

        Assert.areEqual(subscriptionList[0].Id, actualList[0].Id, 'the Subscriptions found does not match expected');
    }

    @isTest
    static void getSubscriptionsByIdTest() {
        COMM_Subscription__c subscriptionRecord = [
            SELECT Id FROM COMM_Subscription__c LIMIT 1
        ][0];

        Test.startTest();
        List<COMM_Subscription__c> actualList = SUBSCRIPTION_REP.getSubscriptionsById(new Set<String>{ subscriptionRecord.Id });
        Test.stopTest();

        Assert.areEqual(subscriptionRecord.Id, actualList[0].Id, 'the Subscriptions found does not match expected');
    }
}