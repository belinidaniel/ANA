/**
 * @author Carlos Fusco
 * @description COMM_LCC_SubscriptionPartnerRequest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)                 Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco     11/03/2024      85                          Original version
 * Daniel Lascas    24/07/2024      100                         CR-33: Added Case Update Failure Test
 * Daniel Reto      29/10/2024      100                         ECOMM-2145
 **/
@IsTest
private class COMM_LCC_SubscriptionPartnerRequestTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Case CASE_REP = (COMM_REP_Case) MOCKS.mock(COMM_REP_Case.class);
    private final static COMM_IREP_Attachment ATTACHMENT_REP = (COMM_REP_Attachment) MOCKS.mock(COMM_REP_Attachment.class);
    private final static COMM_IREP_Group GROUP_REP = (COMM_REP_Group) MOCKS.mock(COMM_REP_Group.class);

    @TestSetup
    static void makeData() {
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription');
        Product2 testProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'RecordTypeId' => recTypeInfo.recordtypeid,
                'Name' => 'SubscriptionProduct',
                'productCode' => 'SubscriptionProduct',
                'family' => 'Subscription',
                'COMM_SubCategory__c' => 'Park',
                'COMM_Periodicity__c' => 'Monthly',
                'isActive' => false,
                'COMM_Airport__c' => 'LIS',
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P0',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent'
            }
        )[0];

        recTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COMM_NewSubscription');
        Case testCase = (Case) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Case',
            new Map<String, Object>{
                'Status' => COMM_DO_Case.IN_APPROVAL_STATUS,
                'RecordTypeId' => recTypeInfo.recordtypeid,
                'COMM_FirstName__c' => 'test',
                'COMM_LastName__c' => 'client',
                'COMM_PhoneNumber__c' => '+351 930123456',
                'COMM_VATNumber__c' => 'PT290765432',
                'SuppliedEmail' => 'test@client.invalid',
                'COMM_JobRole__c' => 'Manager',
                'COMM_LicensePlate__c' => '00-AA-01',
                'COMM_VehicleBrand__c' => 'FIAT',
                'COMM_VehicleModel__c' => 'Punto',
                'COMM_Address__Street__s' => 'Avenida Teste',
                'COMM_Address__City__s' => 'Lisbon',
                'COMM_Address__PostalCode__s' => '1500',
                'COMM_Address__CountryCode__s' => 'PT',
                'COMM_Periodicity__c' => 'Monthly',
                'COMM_Airport__c' => 'LIS',
                'ProductId' => testProduct.Id,
                'COMM_InitialSubscriptionMonth__c' => 'January',
                'COMM_StartDate__c' => Date.today().addDays(1),
                'COMM_EndDate__c' => Date.today().addDays(30)
            }
        )[0];

        // Create Custom Setting record
        COMM_EmailTemplatesEncryptionSettings__c customSettingEmailTemplatesEncrypt = new COMM_EmailTemplatesEncryptionSettings__c();
        customSettingEmailTemplatesEncrypt.Name = 'Test Setting';
        customSettingEmailTemplatesEncrypt.COMM_SubscriptionKey__c = 'asdfghjklpoiuytr';
        insert customSettingEmailTemplatesEncrypt;
    }

    /**
     * @description Implements a mocked server that responds with an expected
     * response when making GET call
     **/
    public class GetHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response
         *
         * @param req HTTP Request sent from Salesforce
         * @return HTTP Response expected
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"personalFirstName":"Test", "personalLastName":"Test", "personalVAT":"123456789", "personalAddress":"Test Street", "personalCity":"Test City", "personalCountry":"Test Country", "personalZipCode":"1111-111", "personalPhoneCode":"+351", "personalPhoneNumber":"911111111", "personalEmail":"Test@test.com", "jobRole":"Tester", "vehicleBrand":"Brand", "vehicleModel":"Model", "vehicleLicense":"AA-11-AA", "secondVehicleBrand":"", "secondVehicleModel":"", "secondVehicleLicense":"", "recordTypeName":"New Subscription", "recordTypeDeveloperName":"COMM_NewSubscription", "airport":"LIS", "status":"Pending Form"}');
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Implements a mocked server that responds with an expected
     * response when making POST call
     **/
    public class PostHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response
         *
         * @param req HTTP Request sent from Salesforce
         * @return HTTP Response expected
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"caseStatus":"Success"}');
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Implements a mocked server that responds with an expected
     * response when making POST call
     **/
    public class PostHttpResponseFailGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response
         *
         * @param req HTTP Request sent from Salesforce
         * @return HTTP Response expected
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"caseStatus":"Error"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void getCountryPicklistValuesTest() {
        Test.startTest();
        Map<String, String> resultMap = COMM_LCC_SubscriptionPartnerRequest.getCountryPicklistValues();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected a map with values');
        Assert.isTrue(resultMap.containsKey('PT'), 'expected map to contain Portugal country code');
    }

    @isTest
    static void validateVatTest() {
        //Call VAT Validation Test

        Test.startTest();
        Boolean validationResult = COMM_LCC_SubscriptionPartnerRequest.validateVAT('2191', 'PT');
        Test.stopTest();

        Assert.isFalse(validationResult, 'expected validation to fail');
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void getCaseRecord() {
        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new GetHttpResponseGenerator());

        List<Case> testCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'COMM_NewSubscription' LIMIT 1];
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier('token', COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);
        String encryptedId = COMM_GEN_Utility.encryptRecordIdentifier(testCase[0].Id, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);
        String mockUrlParams = 'language=en_US&' + encryptedToken + '=' + encryptedId;

        Test.startTest();
        Map<String, Object> caseData = COMM_LCC_SubscriptionPartnerRequest.getCaseRecord(mockUrlParams);
        Test.stopTest();

        Assert.isFalse(caseData.isEmpty(), 'expected to return Case Data');
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void submitCaseTest() {
        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new PostHttpResponseGenerator());

        List<Case> testCase = [
            SELECT
                Id,
                COMM_FirstName__c,
                COMM_LastName__c,
                COMM_VATNumber__c,
                SuppliedEmail,
                COMM_PhoneNumber__c,
                COMM_Address__Street__s,
                COMM_Address__PostalCode__s,
                COMM_Address__City__s,
                COMM_Address__CountryCode__s,
                COMM_JobRole__c,
                COMM_LicensePlate__c,
                COMM_VehicleBrand__c,
                COMM_VehicleModel__c
            FROM Case
            WHERE RecordType.DeveloperName = 'COMM_NewSubscription'
            LIMIT 1
        ];

        Map<String, Object> caseData = new Map<String, Object>();
        caseData.put('recordId', testCase.get(0).Id);
        caseData.put('personalFirstName', testCase.get(0).COMM_FirstName__c);
        caseData.put('personalLastName', testCase.get(0).COMM_LastName__c);
        caseData.put('personalVAT', testCase.get(0).COMM_VATNumber__c);
        caseData.put('personalEmail', testCase.get(0).SuppliedEmail);
        caseData.put('personalPhoneNumber', testCase.get(0).COMM_PhoneNumber__c);
        caseData.put('personalAddress', testCase.get(0).COMM_Address__Street__s);
        caseData.put('personalZipCode', testCase.get(0).COMM_Address__PostalCode__s);
        caseData.put('personalCity', testCase.get(0).COMM_Address__City__s);
        caseData.put('personalCountry', testCase.get(0).COMM_Address__CountryCode__s);
        caseData.put('jobRole', testCase.get(0).COMM_JobRole__c);
        caseData.put('vehicleLicense', testCase.get(0).COMM_LicensePlate__c);
        caseData.put('vehicleBrand', testCase.get(0).COMM_VehicleBrand__c);
        caseData.put('vehicleModel', testCase.get(0).COMM_VehicleModel__c);
        caseData.put('secondVehicleLicense', '00-AA-02');
        caseData.put('secondVehicleBrand', 'FIAT');
        caseData.put('secondVehicleModel', '500');

        Test.startTest();
        COMM_LCC_SubscriptionPartnerRequest.submitCase(caseData, null, null);
        Test.stopTest();


    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void getCaseRecordFailureTest() {
        //Scenario: User opens form with a case record id that doesn't exist
        //Expected: Error Log Record Generated

        String caseId = fflib_IDGenerator.generate(Case.sObjectType);
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier('token', COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);
        String encryptedId = COMM_GEN_Utility.encryptRecordIdentifier(caseId, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);
        String mockUrlParams = 'language=en_US&' + encryptedToken + '=' + encryptedId;
        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_SubscriptionPartnerRequest.getCaseRecord(mockUrlParams);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an exception to be throwed');
        Assert.areEqual(2, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to be created');
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void submitCaseErrorTest() {
        //Scenario: User Submits Case. An unexpected Error Occurs during attachment insertion.
        //Expected: Error Log Record Generated.
        //Mock server responses
        Test.setMock(HttpCalloutMock.class, new PostHttpResponseFailGenerator());
        List<Case> testCase = [
            SELECT
                Id,
                COMM_FirstName__c,
                COMM_LastName__c,
                COMM_VATNumber__c,
                SuppliedEmail,
                COMM_PhoneNumber__c,
                COMM_Address__Street__s,
                COMM_Address__PostalCode__s,
                COMM_Address__City__s,
                COMM_Address__CountryCode__s,
                COMM_JobRole__c,
                COMM_LicensePlate__c,
                COMM_VehicleBrand__c,
                COMM_VehicleModel__c
            FROM Case
            WHERE RecordType.DeveloperName = 'COMM_NewSubscription'
            LIMIT 1
        ];

        Map<String, Object> caseData = new Map<String, Object>();
        caseData.put('recordId', testCase.get(0).Id);
        caseData.put('airport', 'OPO');
        caseData.put('personalFirstName', testCase.get(0).COMM_FirstName__c);
        caseData.put('personalLastName', testCase.get(0).COMM_LastName__c);
        caseData.put('personalVAT', testCase.get(0).COMM_VATNumber__c);
        caseData.put('personalEmail', testCase.get(0).SuppliedEmail);
        caseData.put('personalPhoneNumber', testCase.get(0).COMM_PhoneNumber__c);
        caseData.put('personalAddress', testCase.get(0).COMM_Address__Street__s);
        caseData.put('personalZipCode', testCase.get(0).COMM_Address__PostalCode__s);
        caseData.put('personalCity', testCase.get(0).COMM_Address__City__s);
        caseData.put('personalCountry', testCase.get(0).COMM_Address__CountryCode__s);
        caseData.put('jobRole', testCase.get(0).COMM_JobRole__c);
        caseData.put('vehicleLicense', testCase.get(0).COMM_LicensePlate__c);
        caseData.put('vehicleBrand', testCase.get(0).COMM_VehicleBrand__c);
        caseData.put('vehicleModel', testCase.get(0).COMM_VehicleModel__c);
        caseData.put('secondVehicleLicense', '00-AA-02');
        caseData.put('secondVehicleBrand', 'FIAT');
        caseData.put('secondVehicleModel', '500');

        Group testGroup = new Group(Id = fflib_IDGenerator.generate(Group.sObjectType));

        //Mock Queue Query, Update Call and Error on Insert
        MOCKS.startStubbing();
        MOCKS.when(GROUP_REP.getQueueIdByDeveloperName(fflib_Match.anyString(), fflib_Match.anyBoolean())).thenReturn(new List<Group>{ testGroup });
        MOCKS.when(CASE_REP.updateSObjects((List<Case>) fflib_Match.anyObject())).thenReturn(new List<Database.SaveResult>());
        ((COMM_REP_Attachment) MOCKS.doThrowWhen(new List<Exception>{ new AuraException('Unexpected Error Inserting File') }, ATTACHMENT_REP))
            .insertSObjects((List<Attachment>) fflib_Match.anyList());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_SubscriptionPartnerRequest worker = new COMM_LCC_SubscriptionPartnerRequest(CASE_REP, ATTACHMENT_REP, GROUP_REP);
            worker.handleSubmitCase(caseData, 'test.pdf', 'testdata');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Integer errorCount = [
            SELECT COUNT()
            FROM Error_Log__c
        ];

        Assert.isTrue(errorOccured, 'expected an exception to be throwed');
        Assert.areEqual(1, errorCount, 'an error log was expected to be generated');
    }
}