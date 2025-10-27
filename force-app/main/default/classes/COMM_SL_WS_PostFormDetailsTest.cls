/**
 * @author Daniel Reto
 * @description COMM_SL_WS_PostFormDetails Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      29/10/2024    100           Original version
 **/
@isTest
private class COMM_SL_WS_PostFormDetailsTest {
    @TestSetup
    static void makeData() {
        // Create Custom Setting record
        COMM_EmailTemplatesEncryptionSettings__c customSettingEmailTemplatesEncrypt = new COMM_EmailTemplatesEncryptionSettings__c();
        customSettingEmailTemplatesEncrypt.Name = 'Test Setting';
        customSettingEmailTemplatesEncrypt.COMM_SubscriptionKey__c = 'asdfghjklpoiuytr';
        insert customSettingEmailTemplatesEncrypt;
        
        //Products for Mocking Test
        List<Product2> productRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'T-0',
                'ProductCode' => 'T-0',
                'description' => 'T-0',
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
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
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        //Mock Person Account
        Account accountRecord = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Name' => 'Test Account'
            }
        )[0];
        
        //Case for Mocking Test
        Case caseRecord = (Case) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Case',
            new Map<String, Object>{
                'ProductId' => productRecordList[0].Id,
                'AccountId' => accountRecord.Id,
                'Status' => COMM_DO_Case.IN_APPROVAL_STATUS,
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
                'COMM_InitialSubscriptionMonth__c' => 'January',
                'COMM_EndDate__c' => Date.today().addDays(-1),
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(), 12, Date.today().day()).addYears(-1),
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Case.sObjectType, 'COMM_NewSubscription')
            }
        )[0];
    }

    @isTest
    static void updateSubscriptionRequestTest() {
        
        Case caseRecord = [SELECT Id FROM Case][0];
        String encryptedId = COMM_GEN_Utility.encryptRecordIdentifier(caseRecord.Id, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);

        COMM_WS_UpdateFormDetailsInput inputRequest = new COMM_WS_UpdateFormDetailsInput();
        inputRequest.caseId = encryptedId;
        inputRequest.personalFirstName = 'Test';
        inputRequest.personalLastName = 'Test';
        inputRequest.personalVAT = '123456779';
        inputRequest.personalEmail = 'Test@test.com';
        inputRequest.personalPhoneNumber = '+351 988888888';
        inputRequest.personalAddress = 'Test';
        inputRequest.personalZipCode = '1111-222';
        inputRequest.personalCity = 'Évora';
        inputRequest.personalCountry = 'PT';
        inputRequest.jobRole = 'Tester';
        inputRequest.vehicleLicense = 'AA-11-AA';
        inputRequest.vehicleBrand = 'Test';
        inputRequest.vehicleModel = 'Test';
        inputRequest.secondVehicleLicense = '';
        inputRequest.secondVehicleBrand = '';
        inputRequest.secondVehicleModel = '';
        inputRequest.privacyConsent = '';
        inputRequest.licenseReadingConsent = '';
        inputRequest.marketingConsent = '';
        inputRequest.formLanguage = '';
        inputRequest.status = 'Waiting Approval';
        inputRequest.fileName = 'Test';
        inputRequest.fileData = 'Test';
        inputRequest.airport = 'LIS';

        COMM_WS_UpdateFormDetailsOutput outputRequest = new COMM_WS_UpdateFormDetailsOutput();

        Test.startTest();
        COMM_SL_WS_PostFormDetails postFormDetailsClass = new COMM_SL_WS_PostFormDetails();
        outputRequest = postFormDetailsClass.updateSubscriptionRequest(inputRequest);
        Test.stopTest();

        // Asserts - Expecting a success response
        System.assertEquals('Success', outputRequest.caseStatus, 'Status incorrect.');
    }

    @isTest
    static void updateSubscriptionRequestFailTest() {
                
        Id caseRecordId = fflib_IDGenerator.generate(Case.sObjectType);
        String encryptedId = COMM_GEN_Utility.encryptRecordIdentifier(caseRecordId, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);

        COMM_WS_UpdateFormDetailsInput inputRequest = new COMM_WS_UpdateFormDetailsInput();
        inputRequest.caseId = encryptedId;
        inputRequest.personalFirstName = 'Test';
        inputRequest.personalLastName = 'Test';
        inputRequest.personalVAT = '123456779';
        inputRequest.personalEmail = 'Test@test.com';
        inputRequest.personalPhoneNumber = '988888888';
        inputRequest.personalAddress = 'Test';
        inputRequest.personalZipCode = '1111-222';
        inputRequest.personalCity = 'Test';
        inputRequest.personalCountry = 'Test';
        inputRequest.jobRole = 'Tester';
        inputRequest.vehicleLicense = 'AA-11-AA';
        inputRequest.vehicleBrand = 'Test';
        inputRequest.vehicleModel = 'Test';
        inputRequest.secondVehicleLicense = '';
        inputRequest.secondVehicleBrand = '';
        inputRequest.secondVehicleModel = '';
        inputRequest.privacyConsent = '';
        inputRequest.licenseReadingConsent = '';
        inputRequest.marketingConsent = '';
        inputRequest.formLanguage = '';
        inputRequest.status = 'Waiting Approval';
        inputRequest.fileName = '';
        inputRequest.fileData = '';
        inputRequest.airport = 'LIS';

        COMM_WS_UpdateFormDetailsOutput outputRequest = new COMM_WS_UpdateFormDetailsOutput();

        Test.startTest();
        COMM_SL_WS_PostFormDetails postFormDetailsClass = new COMM_SL_WS_PostFormDetails();
        outputRequest = postFormDetailsClass.updateSubscriptionRequest(inputRequest);
        Test.stopTest();

        // Asserts - Expecting a success response
        System.assertEquals('Error', outputRequest.caseStatus, 'Status incorrect.');

    }
}