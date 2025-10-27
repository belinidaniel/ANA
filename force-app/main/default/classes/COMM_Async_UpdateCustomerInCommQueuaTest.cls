/**
 * @author Daniel Lascas
 * @description COMM_Async_UpdateCustomerInCommQueuable test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    17/06/2024      100            Original version
 **/
@isTest
private class COMM_Async_UpdateCustomerInCommQueuaTest {
    private static string contactId;

    @TestSetup
    static void makeData() {
        //Get Person Account RT
        Id personAccountId = [SELECT Id FROM RecordType WHERE DeveloperName = :COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE].Id;
        //Insert new Customer Person Account
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Customer',
                'RecordTypeId' => personAccountId,
                'COMM_IndividualStaff__c' => true,
                'COMM_IntegrationRequestBody__c' => '{"c_isIndividualStaff":true}'
            }
        );
        //Insert existing Customer Person Account
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Existing',
                'LastName' => 'Customer',
                'RecordTypeId' => personAccountId,
                'COMM_IndividualStaff__c' => true,
                'COMM_CustomerNumber__pc' => '54321',
                'COMM_IntegrationRequestBody__c' => '{"c_isIndividualStaff":true}'
            }
        );
        //Insert new Customer Person Account without request
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{ 'FirstName' => 'NoRequest', 'LastName' => 'Customer', 'RecordTypeId' => personAccountId }
        );

        //Get Business Account RT
        Id businessAccountId = [SELECT Id FROM RecordType WHERE DeveloperName = :COMM_DO_Account.COLLECTIVEPARTNER_ACCOUNT_RECORD_TYPE].Id;
        //Insert new Customer Person Account
        Account affiliateAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Name' => 'Affiliate LDA',
                'BillingCountryCode' => 'PT',
                'COMM_IsAffiliate__c' => true,
                'COMM_AffiliateCategory__c' => 'Others',
                'COMM_PaymentMethod__c' => COMM_DO_Account.PAYMENT_METHOD_CREDIT,
                'COMM_IntegrationRequestBody__c' => '{"COMM_BILLING":{"country_code":null},"COMM_BILLING_COMPANY":{"country_code":null}}'
            }
        )[0];
        //Insert Affiliate Customer Contact
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{
                'FirstName' => 'John',
                'LastName' => 'Doe',
                'AccountId' => affiliateAccount.Id,
                'COMM_IntegrationRequestBody__c' => '{"first_name":"John","last_name":"Doe"}'
            }
        );
    }

    @isTest
    static void splitTest() {
        //Verify that execution is split to ensure limits
        List<Id> accountIdList = new List<Id>();
        for (Integer counter = 0; counter <= 100; counter++) {
            accountIdList.add(fflib_IdGenerator.generate(Account.sObjectType));
        }
        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(accountIdList, 'Account');
        worker.execute(null);
        Integer futureCallNumber = Limits.getFutureCalls();
        Test.stopTest();

        Assert.areEqual(6, futureCallNumber, 'expected 6 future calls');
    }

    @isTest
    static void personAccountUpdateTest() {
        //Scenario: Person Account was updated and callout to Commerce is required. Person Account doesn't have Customer Number.
        //Expected: Callout is performed. Account is updated with Customer Number.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc = NULL AND COMM_IndividualStaff__c = TRUE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Account resultAccount = [SELECT Id, COMM_CustomerNumber__pc FROM Account WHERE Id = :testAccount.Id];
        Assert.isNotNull(resultAccount.COMM_CustomerNumber__pc, 'expected customer number to have been updated');
        Assert.areEqual('12345', resultAccount.COMM_CustomerNumber__pc, 'expected customer number to have been updated to value from mocked server');
    }

    @isTest
    static void contactUpdateTest() {
        //Scenario: Customer Contact was updated and callout to Commerce is required. Contact doesn't have Customer Number.
        //Expected: Callout is performed. Contact is updated with Customer Number.
        Contact testContact = [SELECT Id FROM Contact WHERE COMM_CustomerNumber__c = NULL AND Name = 'John Doe' LIMIT 1];
        contactId = testContact.Id;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testContact.Id }, 'Contact');
        worker.execute(null);
        Test.stopTest();

        Contact resultContact = [SELECT Id, COMM_CustomerNumber__c FROM Contact WHERE Id = :testContact.Id];
        Assert.isNotNull(resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated');
        Assert.areEqual('12345', resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated to value from mocked server');
    }

    @isTest
    static void affiliateTest() {
        //Scenario: An Affiliate Account was updated and callout to Commerce is required. Related Contact doesn't have Customer Number.
        //Expected: Callout are performed. Contact is updated with Customer Number.

        Account testAccount = [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE COMM_IsAffiliate__c = TRUE LIMIT 1];
        contactId = testAccount.Contacts[0].Id;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Contact resultContact = [SELECT Id, COMM_CustomerNumber__c FROM Contact WHERE Id = :testAccount.Contacts[0].Id];
        Assert.isNotNull(resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated');
        Assert.areEqual('12345', resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated to value from mocked server');
    }

    @isTest
    static void updateNoRequestFailTest() {
        //Scenario: Queuable was enqueued but account doesn't have request body created.
        //Expected: Error Log Record is generated.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc = NULL AND COMM_IndividualStaff__c = FALSE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiServerErrorHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been generated');
    }

    @isTest
    static void getNoCustomerTest() {
        //Scenario: Account was updated and callout to Commerce is required.
        //Account doesn't have Customer Number and callout returns no customer found.
        //Expected: Error Log Record is generated.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc = NULL AND COMM_IndividualStaff__c = TRUE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiNoCustomerHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Account resultAccount = [SELECT Id, COMM_CustomerNumber__pc FROM Account WHERE Id = :testAccount.Id];
        Assert.isNull(resultAccount.COMM_CustomerNumber__pc, 'expected customer number to not have been updated');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been generated');
    }

    @isTest
    static void getCustomerFailTest() {
        //Scenario: Account was updated and callout to Commerce is required.
        //Account doesn't have Customer Number and callout returns server error.
        //Expected: Error Log Record is generated.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc = NULL AND COMM_IndividualStaff__c = TRUE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiServerErrorHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Account resultAccount = [SELECT Id, COMM_CustomerNumber__pc FROM Account WHERE Id = :testAccount.Id];
        Assert.isNull(resultAccount.COMM_CustomerNumber__pc, 'expected customer number to not have been updated');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been generated');
    }

    @isTest
    static void updateCustomerFailTest() {
        //Scenario: Account was updated and callout to Commerce is required. Callout returns error.
        //Expected: Error Log Record is generated.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc != NULL AND COMM_IndividualStaff__c = TRUE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiServerErrorHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been generated');
    }

    @isTest
    static void processErrorTest() {
        //Scenario: Logic is executed, an unexpected error occurs.
        //Expected: Error Log Record is generated.
        Account testAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE COMM_CustomerNumber__pc = NULL AND COMM_IndividualStaff__c = TRUE
            LIMIT 1
        ];
        contactId = testAccount.PersonContactId;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new OcapiWrongResponseHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been generated');
    }

    @isTest
    static void addressUpdateFailureTest() {
        //Scenario: An Affiliate Account was updated and callout to Commerce is required. Related Contact doesn't have Customer Number.
        //Expected: Callout are performed. Contact is updated with Customer Number but Address Updates fail so Error Log are generated.

        Account testAccount = [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE COMM_IsAffiliate__c = TRUE LIMIT 1];
        contactId = testAccount.Contacts[0].Id;

        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new AddressFailureHttpResponseGenerator());

        Test.startTest();
        COMM_Async_UpdateCustomerInCommQueuable worker = new COMM_Async_UpdateCustomerInCommQueuable(new List<Id>{ testAccount.Id }, 'Account');
        worker.execute(null);
        Test.stopTest();

        Contact resultContact = [SELECT Id, COMM_CustomerNumber__c FROM Contact WHERE Id = :testAccount.Contacts[0].Id];
        Assert.isNotNull(resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated');
        Assert.areEqual('12345', resultContact.COMM_CustomerNumber__c, 'expected customer number to have been updated to value from mocked server');
        Assert.areEqual(2, [SELECT COUNT() FROM Error_Log__c], 'expected two error logs to have been created');
    }

    /**
     * @description Implements a mocked Commerce Environment that responds with an expected
     * response when making GET and UPDATE calls
     **/
    public class OcapiHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from Commerce
         *
         * @param req HTTP Request that Commerce receives from Salesforce
         * @return HTTP Response expected from Commerce
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            //Build Response for SEARCH request
            if (req.getMethod() == 'POST') {
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"count":1, "hits": [{"data":{"customer_no":"12345","c_comm_contactId":"' + contactId + '"}}]}');
                response.setStatusCode(200);
            } else {
                //Build Response for remaining requests
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"customer_no":"12345"}');
                response.setStatusCode(200);
            }
            return response;
        }
    }

    /**
     * @description Implements a mocked Commerce Environment that responds with an expected
     * response. Used for Address Update Failure Test.
     **/
    public class AddressFailureHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from Commerce
         *
         * @param req HTTP Request that Commerce receives from Salesforce
         * @return HTTP Response expected from Commerce
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            //Build Response for Create Address Failure
            if (reqEndpoint.endsWith('/customer_search')) {
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"count":1, "hits": [{"data":{"customer_no":"12345","c_comm_contactId":"' + contactId + '"}}]}');
                response.setStatusCode(200);
            } else if (reqEndpoint.endsWith('/addresses')) {
                response.setHeader('Content-Type', 'application/json');
                response.setBody('Server Error');
                response.setStatusCode(400);
            } else if (reqEndpoint.endsWith('/addresses/COMM_BILLING')) {
                //Build Response for Address Update Failure
                response.setHeader('Content-Type', 'application/json');
                response.setStatus(COMM_Async_UpdateCustomerInCommQueuable.NOT_FOUND_ERROR_STATUS);
                response.setStatusCode(COMM_Async_UpdateCustomerInCommQueuable.NOT_FOUND_ERROR_CODE);
            } else if (reqEndpoint.endsWith('/addresses/COMM_BILLING_COMPANY')) {
                //Build Response for Address Update Failure
                response.setHeader('Content-Type', 'application/json');
                response.setBody('Server Error');
                response.setStatusCode(400);
            } else {
                //Build Response for remaining requests
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"customer_no":"12345"}');
                response.setStatusCode(200);
            }
            return response;
        }
    }

    /**
     * @description Implements a mocked Commerce Environment that responds with no customer
     * found response
     **/
    private class OcapiNoCustomerHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from Commerce
         *
         * @param req HTTP Request that Commerce receives from Salesforce
         * @return HTTP Response expected from Commerce
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"count":0}');
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Implements a mocked Commerce Environment that responds with a server
     * error response
     **/
    private class OcapiServerErrorHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from Commerce
         *
         * @param req HTTP Request that Commerce receives from Salesforce
         * @return HTTP Response expected from Commerce
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"message":"server error"}');
            response.setStatusCode(400);
            return response;
        }
    }

    /**
     * @description Implements a mocked Commerce Environment that responds with a
     * wrong JSON response (to test logic failure)
     **/
    private class OcapiWrongResponseHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from Commerce
         *
         * @param req HTTP Request that Commerce receives from Salesforce
         * @return HTTP Response expected from Commerce
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{wrongJSON');
            response.setStatusCode(200);
            return response;
        }
    }
}