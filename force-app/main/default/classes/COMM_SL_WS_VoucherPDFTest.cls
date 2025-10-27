/**
 * @author Diogo Gonçalves
 * @description Class to test the class COMM_SL_WS_VoucherPDF
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date        Coverage(%)     Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  01/07/2024  96              Original version
 * Daniel Reto      05/11/2024  96              Test Class Fix
 **/
@isTest
private class COMM_SL_WS_VoucherPDFTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'CommunityNickname' => USERNAME,
                'Alias' => 'testUser',
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        );
    }

    @isTest
    static void shouldReturnBlob() {
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
        System.runAs(userRecord) {
            List<OrderSummary> osList = [SELECT Id, OrderNumber, AccountId FROM OrderSummary];
            Assert.areEqual(osList.isEmpty(), false, 'Order Summary not found.');

            Test.startTest();
            COMM_WS_VoucherPDFInput input = new COMM_WS_VoucherPDFInput();
            input.orderNumber = osList[0].OrderNumber;
            input.accountId = osList[0].AccountId;
            input.email = 'test@test.com.invalid';
            COMM_WS_VoucherPDFOutput output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
            Test.stopTest();

            Assert.areEqual(Blob.valueOf('Test'), output.data, 'Output data does not match');
        }
    }

    @isTest
    static void shouldHaveBlankAccountAndEmail() {
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
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
        System.runAs(userRecord) {
            List<OrderSummary> osList = [SELECT Id, OrderNumber FROM OrderSummary];
            Assert.areEqual(osList.isEmpty(), false, 'Order Summary not found.');

            Test.startTest();
            COMM_WS_VoucherPDFInput input = new COMM_WS_VoucherPDFInput();
            input.orderNumber = osList[0].OrderNumber;
            COMM_WS_VoucherPDFOutput output;
            try {
                output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
            } catch (Exception e) {
                Assert.areEqual(COMM_WS_VoucherPDF.INVALID_USER, e.getMessage(), 'Error should be INVALID_USER');
            }
            Test.stopTest();

            Assert.areEqual(null, output, 'No output should have been returned');
        }
    }

    @isTest
    static void shouldHaveBlankOrderNumber() {
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
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
        System.runAs(userRecord) {
            List<OrderSummary> osList = [SELECT Id, OrderNumber FROM OrderSummary];
            Assert.areEqual(osList.isEmpty(), false, 'Order Summary not found.');

            Test.startTest();
            COMM_WS_VoucherPDFInput input = new COMM_WS_VoucherPDFInput();
            input.accountId = account.Id;
            COMM_WS_VoucherPDFOutput output;
            try {
                output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
            } catch (Exception e) {
                Assert.areEqual(COMM_WS_VoucherPDF.BLANK_ORDER_NUMBER, e.getMessage(), 'Error should be BLANK_ORDER_NUMBER');
            }
            Test.stopTest();

            Assert.areEqual(null, output, 'No output should have been returned');
        }
    }

    @isTest
    static void shouldHaveInvalidOrderNumber() {
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
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
        System.runAs(userRecord) {
            List<OrderSummary> osList = [SELECT Id, OrderNumber FROM OrderSummary];
            Assert.areEqual(osList.isEmpty(), false, 'Order Summary not found.');

            Test.startTest();
            COMM_WS_VoucherPDFInput input = new COMM_WS_VoucherPDFInput();
            input.orderNumber = 'ORDER_NOT_FOUND';
            input.accountId = account.Id;
            COMM_WS_VoucherPDFOutput output;
            try {
                output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
            } catch (Exception e) {
                Assert.areEqual(COMM_WS_VoucherPDF.ORDER_NOT_FOUND, e.getMessage(), 'Error should be ORDER_NOT_FOUND');
            }
            Test.stopTest();

            Assert.areEqual(null, output, 'No output should have been returned');
        }
    }

    @isTest
    static void shouldHaveInvalidAccount() {
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
        System.runAs(userRecord) {
            List<OrderSummary> osList = [SELECT Id, OrderNumber FROM OrderSummary];
            Assert.areEqual(osList.isEmpty(), false, 'Order Summary not found.');

            Test.startTest();
            Account account = new Account(Name = 'Test Account');
            insert account;
            COMM_WS_VoucherPDFInput input = new COMM_WS_VoucherPDFInput();
            input.orderNumber = osList[0].OrderNumber;
            input.accountId = account.Id;
            COMM_WS_VoucherPDFOutput output;
            try {
                output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
            } catch (Exception e) {
                Assert.areEqual(COMM_WS_VoucherPDF.ACCOUNT_MISMATCH, e.getMessage(), 'Error should be ACCOUNT_MISMATCH');
            }
            Test.stopTest();

            Assert.areEqual(null, output, 'No output should have been returned');
        }
    }
}