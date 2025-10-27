/**
 * @author Carlos Fusco
 * @description Controller for comm_subscriptionPartnerRequest Lightning Web Component.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco             03/04/2024       Original version
 * Daniel Lascas            24/07/2024       CR-33: Added Airport Admin Queue Assignment
 * Daniel Reto              29/10/2024       ECOMM-2145
 **/
public without sharing class COMM_LCC_SubscriptionPartnerRequest {
    private static final String WAITING_APPROVAL_CASE_STATUS = 'Waiting Approval';
    private COMM_IREP_Case caseRep;
    private COMM_IREP_Attachment attachmentRep;
    private COMM_IREP_Group groupRep;
    private static final String OUTPUT_CASE_STATUS_ERROR = 'Error';

    /**
     * @description Constructor to initialize Repository Classes
     */
    public COMM_LCC_SubscriptionPartnerRequest() {
        this.caseRep = new COMM_REP_Case();
        this.attachmentRep = new COMM_REP_Attachment();
        this.groupRep = new COMM_REP_Group();
    }

    @TestVisible
    private COMM_LCC_SubscriptionPartnerRequest(COMM_IREP_Case caseRep, COMM_IREP_Attachment attachmentRep, COMM_IREP_Group groupRep) {
        this.caseRep = caseRep;
        this.attachmentRep = attachmentRep;
        this.groupRep = groupRep;
    }

    /**
     * @description Method to retrieve the picklist values for the Country Field in Addresses
     * @return Map of Country name by Country code
     **/
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCountryPicklistValues() {
        Map<String, String> countryByCode = new Map<String, String>();

        for (Schema.PicklistEntry picklistEntry : Account.COMM_CompanyBillingAddress__CountryCode__s.getDescribe().getPicklistValues()) {
            countryByCode.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }

        return countryByCode;
    }

    /**
     * @description LWC accessible method to validate if provided VAT Number is valid.
     *
     * @return True if VAT is Valid, false otherwise
     */
    @AuraEnabled
    public static Boolean validateVAT(String vatToValidate, String countryCode) {
        return COMM_GEN_Utility.validateVAT(vatToValidate, countryCode);
    }

    /**
     * @description Get case record still encrypted
     *
     * @param urlParameters Parameters of form url
     * @return String with encrypted record
     */
    private static String getEncryptedRecord(String urlParameters) {
        String decryptedToken = COMM_GEN_Utility.encryptRecordIdentifier('token', COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME);
        String encryptedCase = urlParameters.substringAfter(decryptedToken + +'=');
        return encryptedCase;
    }

    /**
     * @description LWC accessible method to retrieve Case Data
     *
     * @param recordId Case record identifier
     * @return Map with the Case data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCaseRecord(String urlParameters) {
        Map<String, String> HTTP_CONTENT_JSON_HEADER = new Map<String, String>{ 'Content-Type' => 'application/json' };
        String encryptedCase = getEncryptedRecord(urlParameters);
        if(encryptedCase.contains('/')){
            encryptedCase = encryptedCase.replace('/','&');
        }
        String ENDPOINT = COMM_GEN_Utility.getSubscriptionPortalUrl().removeEnd('/s') + '/services/apexrest/getFormDetails/' + encryptedCase;
        Case caseRecord = new Case();
        HttpResponse httpResponse;

        try {
            httpResponse = COMM_HttpCallout_Utility.httpGetCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, null);
            COMM_WS_FormDetailsOutput responseBody = (COMM_WS_FormDetailsOutput) JSON.deserialize(httpResponse.getBody(), COMM_WS_FormDetailsOutput.class);

            return new Map<String, Object>{
                'recordId' => getEncryptedRecord(urlParameters),
                'personalFirstName' => responseBody.personalFirstName,
                'personalLastName' => responseBody.personalLastName,
                'personalVAT' => responseBody.personalVAT,
                'personalAddress' => responseBody.personalAddress,
                'personalCity' => responseBody.personalCity,
                'personalCountry' => responseBody.personalCountry,
                'personalZipCode' => responseBody.personalZipCode,
                'personalPhoneCode' => responseBody.personalPhoneCode,
                'personalPhoneNumber' => responseBody.personalPhoneNumber,
                'personalEmail' => responseBody.personalEmail,
                'jobRole' => responseBody.jobRole,
                'vehicleBrand' => responseBody.vehicleBrand,
                'vehicleModel' => responseBody.vehicleModel,
                'vehicleLicense' => responseBody.vehicleLicense,
                'secondVehicleBrand' => responseBody.secondVehicleBrand,
                'secondVehicleModel' => responseBody.secondVehicleModel,
                'secondVehicleLicense' => responseBody.secondVehicleLicense,
                'recordTypeName' => responseBody.recordTypeName,
                'recordTypeDeveloperName' => responseBody.recordTypeDeveloperName,
                'airport' => responseBody.airport,
                'status' => responseBody.status
            };
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error getting Case Data with Id: ' + getEncryptedRecord(urlParameters), 'COMM_LCC_SubscriptionPartnerRequest');
            throw e;
        }
    }

    /**
     * @description LWC accessible method to update Case Data with the data filled on form
     *
     * @param recordData Identifier of record related in form
     * @param fileName Name of attachment file related in form
     * @param fileData Data of attachment file related in form
     **/
    @AuraEnabled
    public static void submitCase(Map<String, Object> recordData, String fileName, String fileData) {
        new COMM_LCC_SubscriptionPartnerRequest().handleSubmitCase(recordData, fileName, fileData);
    }

    /**
     * @description Handles the Case Update Logic.
     * Update the Case record with the data filled on the LWC's subscription request form by the Community End User.
     *
     * @param recordData Identifier of record related in form
     * @param fileName Name of attachment file related in form
     * @param fileData Data of attachment file related in form
     */
    @TestVisible
    private void handleSubmitCase(Map<String, Object> recordData, String fileName, String fileData) {
        Map<String, String> HTTP_CONTENT_JSON_HEADER = new Map<String, String>{ 'Content-Type' => 'application/json' };
        String ENDPOINT = COMM_GEN_Utility.getSubscriptionPortalUrl().removeEnd('/s') + '/services/apexrest/postFormDetails/';
        COMM_WS_UpdateFormDetailsInput inputRequest = new COMM_WS_UpdateFormDetailsInput();
        HttpResponse httpResponse;

        try {
            inputRequest.caseId = (String) recordData.get('recordId');
            inputRequest.personalFirstName = (String) recordData.get('personalFirstName');
            inputRequest.personalLastName = (String) recordData.get('personalLastName');
            inputRequest.personalVAT = (String) recordData.get('personalVAT');
            inputRequest.personalEmail = (String) recordData.get('personalEmail');
            inputRequest.personalPhoneNumber = (String) recordData.get('personalPhoneNumber');
            inputRequest.personalAddress = (String) recordData.get('personalAddress');
            inputRequest.personalZipCode = (String) recordData.get('personalZipCode');
            inputRequest.personalCity = (String) recordData.get('personalCity');
            inputRequest.personalCountry = (String) recordData.get('personalCountry');
            inputRequest.jobRole = (String) recordData.get('jobRole');
            inputRequest.vehicleLicense = (String) recordData.get('vehicleLicense');
            inputRequest.vehicleBrand = (String) recordData.get('vehicleBrand');
            inputRequest.vehicleModel = (String) recordData.get('vehicleModel');
            inputRequest.secondVehicleLicense = (String) recordData.get('secondVehicleLicense');
            inputRequest.secondVehicleBrand = (String) recordData.get('secondVehicleBrand');
            inputRequest.secondVehicleModel = (String) recordData.get('secondVehicleModel');
            inputRequest.privacyConsent = (String) recordData.get('privacyConsent');
            inputRequest.licenseReadingConsent = (String) recordData.get('licenseReadingConsent');
            inputRequest.marketingConsent = (String) recordData.get('marketingConsent');
            inputRequest.formLanguage = (String) recordData.get('formLanguage');
            inputRequest.status = WAITING_APPROVAL_CASE_STATUS;
            inputRequest.fileName = fileName;
            inputRequest.fileData = fileData;
            inputRequest.airport = (String) recordData.get('airport');
            httpResponse = COMM_HttpCallout_Utility.httpPostCallout(ENDPOINT, HTTP_CONTENT_JSON_HEADER, JSON.serialize(inputRequest));
            COMM_WS_UpdateFormDetailsOutput responseBody = (COMM_WS_UpdateFormDetailsOutput) JSON.deserialize(httpResponse.getBody(), COMM_WS_UpdateFormDetailsOutput.class);
            if(responseBody.caseStatus == OUTPUT_CASE_STATUS_ERROR){
                throw new COMM_LCC_SubscriptionPartnerRequestException(responseBody.caseStatus);
            }

        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error updating Case with Subscription Form Data ', 'COMM_LCC_SubscriptionPartnerRequest');
            throw e;
        }
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_LCC_SubscriptionPartnerRequestException extends Exception {
    }
}