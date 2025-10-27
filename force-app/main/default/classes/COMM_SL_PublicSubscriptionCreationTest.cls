/**
 * @author Carlos Fusco
 * @description COMM_SL_PublicSubscriptionCreation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date            Coverage(%)          Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco      19/06/2024             92              Original version
 * Daniel Reto       16/07/2024             79              Original version
 **/
@isTest
private class COMM_SL_PublicSubscriptionCreationTest {
    @testSetup
    static void setup() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Long suffix = DateTime.now().getTime();
        String username = 'testuser' + suffix;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test' + UserInfo.getOrganizationId(),
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'CommunityNickname' => username,
                'Alias' => 'testUser',
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        );

        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();

        List<Product2> productList = [SELECT Id, COMM_ParentProduct__c FROM Product2];
        System.debug('productList: '+productList);
        
        for(Product2 productRecord : productList){
            Product2 parentProductRecord = (Product2) COMM_TestDataFactory.insertRecords(
                1,
                true,
                'Product2',
                new Map<String, Object>{
                    'Name' => 'T-0'+productRecord.Id,
                    'ProductCode' => 'T-0'+productRecord.Id,
                    'description' => 'T-0'+productRecord.Id,
                    'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                    'isActive' => false,
                    'COMM_Airport__c' => 'LIS',
                    'COMM_Alarmistic__c' => 25,
                    'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                    'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                    'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                    'COMM_ValidTo__c' => DateTime.now().addDays(2),
                    'COMM_CPMS__c' => 'SKIDATA',
                    'COMM_Park__c' => 'P3',
                    'COMM_Periodicity__c' => null,
                    'COMM_Tax__c' => 'Continent',
                    'COMM_SubCategory__c' => 'Park',
                    'COMM_WhereProductAvailable__c' => 'eCommerce',
                    'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
                }
            )[0];

            productRecord.COMM_ParentProduct__c = parentProductRecord.Id;
            productRecord.COMM_WhereProductAvailable__c = 'eCommerce';
            productRecord.COMM_Periodicity__c = 'Monthly';
            update productRecord;

            COMM_TestDataFactory.insertRecords(
                1,
                true,
                'COMM_Capacity__c',
                new Map<String, Object>{
                    'COMM_Capacity__c' => 50,
                    'COMM_IsDefaultCapacity__c' => true,
                    'COMM_Product__c' => parentProductRecord.Id,
                    'COMM_ValidFrom__c' => Datetime.now().addDays(1),
                    'COMM_ValidTo__c' => Datetime.now().addDays(3),
                    'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED,
                    'RecordTypeId' => Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
                }
            );
            parentProductRecord.IsActive = true;
            update parentProductRecord;
        }
        
    }

    /**
     * @description Test method of COMM_SL_PublicSubscriptionCreation.createPublicSubscription
     */
    @isTest
    static void createPublicSubscriptionTest() {
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];

        List<PermissionSet> permissionSetList = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'COMM_ANAAdmin' OR Name = 'COMM_Lightning_Order_Management_Operations_Manager'
        ];

        List<PermissionSetAssignment> permissionSetAssignmentList = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSetRecord : permissionSetList) {
            permissionSetAssignmentList.add(new PermissionSetAssignment(PermissionSetId = permissionSetRecord.Id, AssigneeId = userRecord.Id));
        }
        insert permissionSetAssignmentList;

        List<OrderSummary> orderSummaryList = new List<OrderSummary>();
        List<Id> invoiceIdList = new List<Id>();

        System.runAs(userRecord) {
            orderSummaryList = [SELECT Id, Status, (SELECT Id FROM OrderItemSummaries) FROM OrderSummary];
            System.assertEquals(orderSummaryList.isEmpty(), false, 'Order Summary not found.');

            List<FulfillmentOrder> fulfillmentOrderList = [
                SELECT Id, Status, (SELECT Id FROM FulfillmentOrderLineItems)
                FROM FulfillmentOrder
                WHERE OrderSummaryId = :orderSummaryList.get(0).Id
            ];
            System.assertEquals(fulfillmentOrderList.isEmpty(), false, 'Order Fulfillment not found.');

            List<Invoice> invoiceList = [
                SELECT Id, Status, Balance, (SELECT id FROM InvoiceLines)
                FROM Invoice
                WHERE ReferenceEntityId = :orderSummaryList.get(0).Id
            ];
            System.assertEquals(invoiceList.isEmpty(), false, 'Invoice not found.');

            for (Invoice invoice : invoiceList) {
                invoiceIdList.add(invoice.id);
            }

            Test.startTest();
            COMM_SL_PublicSubscriptionCreation.createPublicSubscription(invoiceIdList);
            Test.stopTest();
        }

        List<COMM_Subscription__c> subscriptionList = [SELECT Id FROM COMM_Subscription__c WHERE COMM_OrderSummary__c = :orderSummaryList.get(0).Id];
        System.assertEquals(1, subscriptionList.size(), 'Expected to have 1 Public Subscription record created.');

        List<Case> caseList = [SELECT Id, COMM_Subscription__c FROM Case WHERE COMM_Subscription__c = :subscriptionList.get(0).Id];
        System.assertEquals(1, caseList.size(), 'Expected to have 1 Case record created related on Public Subscription.');

        List<ProcessException> processExceptionList = [SELECT Id FROM ProcessException];
        System.assertEquals(processExceptionList.isEmpty(), true, processExceptionList);
    }
}