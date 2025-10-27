/**
 * @author Jose Passos
 * @description COMM_SL_OMS_CPMSHandlerTest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      01/04/2024      96             Original version
 * Jose Passos      22/04/2024      94             Updated to support class changes
 * Daniel Reto      22/05/2024      94             Test Class Fix
 * Diogo Gonçalves  19/06/2024      94             ECOMM-1420 Adjust for the QR Code creation
 * Daniel Reto      05/11/2024      94             Test Class Fix
 **/
@isTest
private class COMM_SL_OMS_CPMSHandlerTest {
    @testSetup
    static void setup() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Long SUFFIX = DateTime.now().getTime();
        String USERNAME = 'testuser' + SUFFIX;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test' + UserInfo.getOrganizationId(),
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

        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    /**
     * @description Mock class for HTTP Callouts
     */
    public class HttpResponseSuccessMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            // Prepare responseBody mock
            String responseBody;
            if (request.getEndpoint().contains('barcode')) {
                List<String> responseData = new List<String>{
                    '"content": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdj+Gkf9x8ABmEClm+bvsMAAAAASUVORK5CYII="',
                    '"fileType": "img/png"'
                };
                responseBody = '{' + String.join(responseData, ',') + '}';
            } else {
                List<COMM_OMS_CPMSReservationResponse> cpmsRespList = new List<COMM_OMS_CPMSReservationResponse>();
                COMM_OMS_CPMSReservationResponse cpmsResp = new COMM_OMS_CPMSReservationResponse();
                cpmsResp.reservationId = [SELECT id FROM OrderItemSummary LIMIT 1][0].id;
                cpmsResp.cpmsReservationId = 'CPMS_' + cpmsResp.reservationId;
                cpmsResp.barcodeType = 'EAN128';
                cpmsResp.barcodeString = 'BARCODESTRING';
                cpmsResp.resultCode = 'SUCCESS';
                cpmsResp.resultDesc = null;
                cpmsRespList.add(cpmsResp);
                responseBody = JSON.serialize(cpmsRespList);
            }

            // set response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }

    public class HttpResponseWithErrorsMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            // Prepare responseBody mock
            List<COMM_OMS_CPMSReservationResponse> cpmsRespList = new List<COMM_OMS_CPMSReservationResponse>();
            COMM_OMS_CPMSReservationResponse cpmsResp = new COMM_OMS_CPMSReservationResponse();
            cpmsResp.reservationId = [SELECT id FROM OrderItemSummary LIMIT 1][0].id;
            cpmsResp.cpmsReservationId = 'CPMS_' + cpmsResp.reservationId;
            cpmsResp.barcodeType = 'EAN128';
            cpmsResp.barcodeString = 'BARCODESTRING';
            cpmsResp.resultCode = 'FAIL';
            cpmsResp.resultDesc = 'Failed to Update Reservation';
            cpmsRespList.add(cpmsResp);
            String responseBody = JSON.serialize(cpmsRespList);

            // set response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }

    public class HttpResponseFailMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            // Prepare responseBody mock
            List<COMM_OMS_CPMSReservationResponse> cpmsRespList = new List<COMM_OMS_CPMSReservationResponse>();
            COMM_OMS_CPMSReservationResponse cpmsResp = new COMM_OMS_CPMSReservationResponse();

            // set response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('');
            response.setStatusCode(500);
            return response;
        }
    }

    @isTest
    static void doCallSuccessWithErrorsTest() {
        // scenario: Callout CPMS and get a 200 response with some errors in response
        // expected: Errors logged in ProcessException
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

        // Run system as User
        System.runAs(userRecord) {
            // Validate that required data was generated by the flows
            List<OrderSummary> osList = [SELECT Id, status, (SELECT id FROM OrderItemSummaries) FROM OrderSummary];
            System.assertEquals(osList.isEmpty(), false, 'Order Summary not found.');
            List<FulfillmentOrder> ofList = [
                SELECT Id, status, (SELECT Id FROM FulfillmentOrderLineItems)
                FROM FulfillmentOrder
                WHERE OrderSummaryId = :osList[0].id
            ];
            System.assertEquals(ofList.isEmpty(), false, 'Order Fulfillment not found.');
            List<Invoice> invcList = [SELECT Id, status, balance, (SELECT id FROM InvoiceLines) FROM Invoice WHERE ReferenceEntityId = :osList[0].id];
            System.assertEquals(invcList.isEmpty(), false, 'Invoice not found.');
            List<Id> incoiceIdList = new List<Id>();
            for (Invoice invc : invcList) {
                incoiceIdList.add(invc.id);
            }

            // call method
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HttpResponseWithErrorsMock());
            COMM_SL_OMS_CPMSHandler.doCall(incoiceIdList);
            Test.stopTest();
        }
        // Check if any errors were generated
        List<ProcessException> processExceptionList = [
            SELECT Id
            FROM ProcessException
            WHERE Category = :COMM_DO_ProcessExceptions.CPMS_CATEGORY
        ];
        System.assertEquals(processExceptionList.isEmpty(), false, 'Expected errors to be logged in ProcessException object.');
    }

    @isTest
    static void doCallFailTest() {
        // scenario: Callout CPMS and get a 500 response
        // expected: Callout error logged in ProcessException
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

        // Run system as User
        System.runAs(userRecord) {
            // Validate that required data was generated by the flows
            List<OrderSummary> osList = [SELECT Id, status, (SELECT id FROM OrderItemSummaries) FROM OrderSummary];
            System.assertEquals(osList.isEmpty(), false, 'Order Summary not found.');
            List<FulfillmentOrder> ofList = [
                SELECT Id, status, (SELECT Id FROM FulfillmentOrderLineItems)
                FROM FulfillmentOrder
                WHERE OrderSummaryId = :osList[0].id
            ];
            System.assertEquals(ofList.isEmpty(), false, 'Order Fulfillment not found.');
            List<Invoice> invcList = [SELECT Id, status, balance, (SELECT id FROM InvoiceLines) FROM Invoice WHERE ReferenceEntityId = :osList[0].id];
            System.assertEquals(invcList.isEmpty(), false, 'Invoice not found.');
            List<Id> incoiceIdList = new List<Id>();
            for (Invoice invc : invcList) {
                incoiceIdList.add(invc.id);
            }

            // call method
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HttpResponseFailMock());
            COMM_SL_OMS_CPMSHandler.doCall(incoiceIdList);
            Test.stopTest();
        }
        // Check if any errors were generated
        List<ProcessException> processExceptionList = [
            SELECT Id
            FROM ProcessException
            WHERE Category = :COMM_DO_ProcessExceptions.CPMS_CATEGORY
        ];
        System.assertEquals(processExceptionList.isEmpty(), false, 'Expected errors to be logged in ProcessException object.');
    }

    @isTest
    static void doCallGeneralExceptionTest() {
        // scenario: missing callout configurations
        // expected: generic exception logged in ProcessException
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

        // Run system as User
        System.runAs(userRecord) {
            // Validate that required data was generated by the flows
            List<OrderSummary> osList = [SELECT Id, status, (SELECT id, Product2Id FROM OrderItemSummaries) FROM OrderSummary LIMIT 1];
            System.assertEquals(osList.isEmpty(), false, 'Order Summary not found.');
            List<FulfillmentOrder> ofList = [
                SELECT Id, status, (SELECT Id FROM FulfillmentOrderLineItems)
                FROM FulfillmentOrder
                WHERE OrderSummaryId = :osList[0].id
                LIMIT 1
            ];
            System.assertEquals(ofList.isEmpty(), false, 'Order Fulfillment not found.');
            List<Invoice> invcList = [
                SELECT Id, status, balance, (SELECT id FROM InvoiceLines)
                FROM Invoice
                WHERE ReferenceEntityId = :osList[0].id
                LIMIT 1
            ];
            System.assertEquals(invcList.isEmpty(), false, 'Invoice not found.');
            List<Id> incoiceIdList = new List<Id>();
            for (Invoice invc : invcList) {
                incoiceIdList.add(invc.id);
            }

            // call method
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock());
            COMM_SL_OMS_CPMSHandler.doCall(incoiceIdList);
            Test.stopTest();
        }
        // Check if any errors were generated
        List<ProcessException> processExceptionList = [
            SELECT Id
            FROM ProcessException
            WHERE Category = :COMM_DO_ProcessExceptions.CPMS_CATEGORY
        ];
        System.assertEquals(processExceptionList.isEmpty(), false, 'Expected errors to be logged in ProcessException object.');
    }
}