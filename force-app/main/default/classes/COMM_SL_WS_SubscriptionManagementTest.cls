/**
 * @author Daniel Lascas
 * @description COMM_SL_WS_SubscriptionManagement test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    19/06/2024      100            Original version
 * Miguel Justo     22/08/2024      100            Updated
 **/
@isTest
private class COMM_SL_WS_SubscriptionManagementTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Subscription SUBSCRIPTION_REP = (COMM_REP_Subscription) MOCKS.mock(COMM_REP_Subscription.class);
    private final static COMM_IDO_SubscriptionManagementMapping SUB_MAPPING_DO = (COMM_DO_SubscriptionManagementMapping) MOCKS.mock(
        COMM_DO_SubscriptionManagementMapping.class
    );

    @isTest
    static void invalidParameterTest() {
        //Scenario: Request is received. Start date is defined but end date is missing.
        //Expected: Exception is throwed

        Id testAccountId = fflib_IDGenerator.generate(Account.sObjectType);
        Map<String, Object> requestMap = new Map<String, Object>{ 'orderStartDate' => '2024-06-19T00:00:00.000Z' };

        Boolean errorOccured = false;
        Test.startTest();
        try {
            new COMM_SL_WS_SubscriptionManagement().searchSubscriptionList(testAccountId, requestMap);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void searchSubscriptionListSuccessWithNoParametersTest() {
        //Scenario: Request is received with no parameters.
        //Expected: Response Map is returned with data of all account subscriptions.

        //Mock Request Received
        Id testAccountId = fflib_IDGenerator.generate(Account.sObjectType);
        Map<String, Object> requestMap = new Map<String, Object>();

        //Mock Product
        Product2 mockedProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'COMM_Airport__c' => 'LIS' }
        )[0];

        //Mock Existing Subscriptions
        List<COMM_Subscription__c> subscriptionList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            5,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{ 'COMM_Account__c' => testAccountId }
        );
        subscriptionList[0].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[0].COMM_Periodicity__c = 'Monthly';
        subscriptionList[0].COMM_Product__r = mockedProduct;
        subscriptionList[1].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[1].COMM_Periodicity__c = 'Quarterly';
        subscriptionList[1].COMM_Product__r = mockedProduct;
        subscriptionList[2].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[2].COMM_Periodicity__c = 'Half Yearly';
        subscriptionList[2].COMM_Product__r = mockedProduct;
        subscriptionList[3].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[3].COMM_Periodicity__c = 'Yearly';
        subscriptionList[3].COMM_Product__r = mockedProduct;
        subscriptionList[4].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[4].COMM_Product__r = mockedProduct;

        //Set Subscription with Renewal Case in Approval information in formula fields
        subscriptionList[0] = (COMM_Subscription__c) COMM_TestDataFactory.setField(
            subscriptionList[0],
            new Map<String, Object>{
                'COMM_ActiveSubscriptionRequestStatus__c' => COMM_DO_Case.IN_APPROVAL_STATUS,
                'COMM_ActiveSubscriptionRequestRecordType__c' => COMM_DO_Case.MANUAL_RENEWAL_RT
            }
        );

        //Mock expected mapping result
        Map<String, Object> subscriptionMap = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[0].COMM_Periodicity__c
        };
        Map<String, Object> subscription2Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[1].COMM_Periodicity__c
        };
        Map<String, Object> subscription3Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[2].COMM_Periodicity__c
        };
        Map<String, Object> subscription4Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[3].COMM_Periodicity__c
        };
        Map<String, Object> subscription5Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[4].COMM_Periodicity__c
        };

        //Mock Query and Mapping
        MOCKS.startStubbing();
        MOCKS.when(
                SUBSCRIPTION_REP.getSubscriptionsByAccountId(
                    fflib_Match.anyString(),
                    (Id) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (String) fflib_Match.isNull(),
                    (List<String>) fflib_Match.isNull(),
                    (Boolean) fflib_Match.isNull(),
                    (String) fflib_Match.isNull(),
                    (String) fflib_Match.isNull()
                )
            )
            .thenReturn(subscriptionList);

        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[0], new Map<String, Object>())).thenReturn(subscriptionMap);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[1], new Map<String, Object>())).thenReturn(subscription2Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[2], new Map<String, Object>())).thenReturn(subscription3Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[3], new Map<String, Object>())).thenReturn(subscription4Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[4], new Map<String, Object>())).thenReturn(subscription5Map);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_WS_SubscriptionManagement worker = new COMM_SL_WS_SubscriptionManagement(SUBSCRIPTION_REP, SUB_MAPPING_DO);
        Map<String, Object> resultMap = worker.searchSubscriptionList(testAccountId, requestMap);
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected map with data');
        Assert.areEqual(
            subscriptionList.size(),
            resultMap.get(COMM_SL_WS_SubscriptionManagement.COUNT_KEY),
            'expected count field to say that 5 subscriptions exist'
        );
    }

    @isTest
    static void searchSubscriptionListWithEmptyValueRequestTest() {
        //Scenario: Request is received with parameters but they're all empty.
        //Expected: Response Map is returned with data of all account subscriptions.

        //Mock Request Received
        Id testAccountId = fflib_IDGenerator.generate(Account.sObjectType);
        Map<String, Object> requestMap = new Map<String, Object>{
            'page' => '',
            'pageSize' => '',
            'orderStartDate' => '',
            'orderEndDate' => '',
            'reservationStartDate' => '',
            'reservationEndDate' => '',
            'airports' => '',
            'status' => ''
        };

        //Mock Product
        Product2 mockedProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'COMM_Airport__c' => 'LIS' }
        )[0];

        //Mock Existing Subscriptions
        List<COMM_Subscription__c> subscriptionList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            5,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{ 'COMM_Account__c' => testAccountId }
        );
        subscriptionList[0].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[0].COMM_Periodicity__c = 'Monthly';
        subscriptionList[0].COMM_Product__r = mockedProduct;
        subscriptionList[1].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[1].COMM_Periodicity__c = 'Quarterly';
        subscriptionList[1].COMM_Product__r = mockedProduct;
        subscriptionList[2].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[2].COMM_Periodicity__c = 'Half Yearly';
        subscriptionList[2].COMM_Product__r = mockedProduct;
        subscriptionList[3].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[3].COMM_Periodicity__c = 'Yearly';
        subscriptionList[3].COMM_Product__r = mockedProduct;
        subscriptionList[4].Id = fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType);
        subscriptionList[4].COMM_Product__r = mockedProduct;

        //Set Subscription with Renewal Case in Approval information in formula fields
        subscriptionList[0] = (COMM_Subscription__c) COMM_TestDataFactory.setField(
            subscriptionList[0],
            new Map<String, Object>{
                'COMM_ActiveSubscriptionRequestStatus__c' => COMM_DO_Case.IN_APPROVAL_STATUS,
                'COMM_ActiveSubscriptionRequestRecordType__c' => COMM_DO_Case.MANUAL_RENEWAL_RT
            }
        );

        //Mock expected mapping result
        Map<String, Object> subscriptionMap = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[0].COMM_Periodicity__c
        };
        Map<String, Object> subscription2Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[1].COMM_Periodicity__c
        };
        Map<String, Object> subscription3Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[2].COMM_Periodicity__c
        };
        Map<String, Object> subscription4Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[3].COMM_Periodicity__c
        };
        Map<String, Object> subscription5Map = new Map<String, Object>{
            COMM_SL_WS_SubscriptionManagement.PERIODICITY_KEY => subscriptionList[4].COMM_Periodicity__c
        };

        //Mock Query and Mapping
        MOCKS.startStubbing();
        MOCKS.when(
                SUBSCRIPTION_REP.getSubscriptionsByAccountId(
                    fflib_Match.anyString(),
                    (Id) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (Datetime) fflib_Match.isNull(),
                    (String) fflib_Match.isNull(),
                    (List<String>) fflib_Match.isNull(),
                    (Boolean) fflib_Match.isNull(),
                    (String) fflib_Match.isNull(),
                    (String) fflib_Match.isNull()
                )
            )
            .thenReturn(subscriptionList);

        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[0], new Map<String, Object>())).thenReturn(subscriptionMap);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[1], new Map<String, Object>())).thenReturn(subscription2Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[2], new Map<String, Object>())).thenReturn(subscription3Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[3], new Map<String, Object>())).thenReturn(subscription4Map);
        MOCKS.when(SUB_MAPPING_DO.mapJsonFromSObject(subscriptionList[4], new Map<String, Object>())).thenReturn(subscription5Map);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_WS_SubscriptionManagement worker = new COMM_SL_WS_SubscriptionManagement(SUBSCRIPTION_REP, SUB_MAPPING_DO);
        Map<String, Object> resultMap = worker.searchSubscriptionList(testAccountId, requestMap);
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected map with data');
        Assert.areEqual(
            subscriptionList.size(),
            resultMap.get(COMM_SL_WS_SubscriptionManagement.COUNT_KEY),
            'expected count field to say that 5 subscriptions exist'
        );
    }
}