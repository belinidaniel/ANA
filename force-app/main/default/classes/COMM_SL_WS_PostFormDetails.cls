/**
 * @author Daniel Reto
 * @description Class to support the Web Service to get Case details for Subscription form.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      21/10/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_PostFormDetails {
    private static final String INVALID_CASEID_PARAMETER_ERROR = 'The Case Id received doesn\'t exist!';
    private static final String OUTPUT_CASE_STATUS_SUCCESS = 'Success';
    private static final String OUTPUT_CASE_STATUS_ERROR = 'Error';
    private static final String ANA_ADMIN_CASE_QUEUE = 'COMM_SubscriptionRequestANAAdmin';
    private static final String AIRPORT_ADMIN_CASE_QUEUE = 'COMM_SubscriptionRequestAirportAdmin_';
    /**
     * @description Check if any Order record exists for the request order number.
     * @param inputRequest input request with Case data to update
     * @return COMM_WS_UpdateFormDetailsOutput output with Case dml status
     */ 
    public COMM_WS_UpdateFormDetailsOutput updateSubscriptionRequest(COMM_WS_UpdateFormDetailsInput inputRequest) {
        COMM_WS_UpdateFormDetailsOutput outputRequest = new COMM_WS_UpdateFormDetailsOutput();
        COMM_REP_Case caseRep = new COMM_REP_Case();
        COMM_REP_Attachment attachmentRep = new COMM_REP_Attachment();
        COMM_REP_Group groupRep = new COMM_REP_Group();

        try {
            //Obtain Id of Airport Admin Queue for the Case Airport. If Case doesn't have an Airport then obtain Id for ANA Admin Queue.
            String queueName = inputRequest.airport != null ? AIRPORT_ADMIN_CASE_QUEUE + inputRequest.airport : ANA_ADMIN_CASE_QUEUE;
            Group adminQueue = groupRep.getQueueIdByDeveloperName(queueName, false).get(0);

            Case caseToUpdate = new Case(
                Id = COMM_GEN_Utility.decryptRecordIdentifier(inputRequest.caseId, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME),
                COMM_FirstName__c = inputRequest.personalFirstName,
                COMM_LastName__c = inputRequest.personalLastName,
                COMM_VATNumber__c = inputRequest.personalVAT,
                SuppliedEmail = inputRequest.personalEmail,
                COMM_PhoneNumber__c = inputRequest.personalPhoneNumber,
                COMM_Address__Street__s = inputRequest.personalAddress,
                COMM_Address__PostalCode__s = inputRequest.personalZipCode,
                COMM_Address__City__s = inputRequest.personalCity,
                COMM_Address__CountryCode__s = inputRequest.personalCountry,
                COMM_JobRole__c = inputRequest.jobRole,
                COMM_LicensePlate__c = inputRequest.vehicleLicense,
                COMM_VehicleBrand__c = inputRequest.vehicleBrand,
                COMM_VehicleModel__c = inputRequest.vehicleModel,
                COMM_SecondaryLicensePlate__c = inputRequest.secondVehicleLicense,
                COMM_SecondaryVehicleBrand__c = inputRequest.secondVehicleBrand,
                COMM_SecondaryVehicleModel__c = inputRequest.secondVehicleModel,
                COMM_PrivacyPolicyConsent__c = inputRequest.privacyConsent,
                COMM_LicensePlateReadingConsent__c = inputRequest.licenseReadingConsent,
                COMM_ConsentUseofDataforMarketing__c = inputRequest.marketingConsent,
                COMM_Language__c = inputRequest.formLanguage,
                Status = inputRequest.status,
                OwnerId = adminQueue.Id
            );
            caseRep.updateSObjects(new List<Case>{ caseToUpdate });

            if (inputRequest.fileData != null) {
                Blob fileBody = EncodingUtil.base64Decode(inputRequest.fileData);
                Attachment fileRecord = new Attachment();
                fileRecord.Name = inputRequest.fileName;
                fileRecord.Body = fileBody;
                fileRecord.ParentId = caseToUpdate.Id;
                attachmentRep.insertSObjects(new List<Attachment>{ fileRecord });
            }

            outputRequest.caseStatus = OUTPUT_CASE_STATUS_SUCCESS;

        } catch (Exception e){
            outputRequest.caseStatus = OUTPUT_CASE_STATUS_ERROR;
        }
        return outputRequest;
    }
}