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
public inherited sharing class COMM_SL_WS_GetFormDetails {
    private static final String INVALID_CASEID_PARAMETER_ERROR = 'The Case Id received doesn\'t exist!';
    /**
     * @description Check if any Order record exists for the request order number.
     * @param String caseIdValue - Case Id to search
     * @return COMM_WS_FormDetailsOutput output with Case Details data
     */
    public COMM_WS_FormDetailsOutput checkFormDetails(String caseIdValue) {
        COMM_WS_FormDetailsOutput outputRequest = new COMM_WS_FormDetailsOutput();

        COMM_REP_Case caseRep = new COMM_REP_Case();
        List<Case> caseList = caseRep.getCasesByCaseIds(new Set<Id>{ caseIdValue });

        if (caseList != null && caseList.size() > 0) {
            outputRequest.personalFirstName = caseList.get(0).COMM_FirstName__c;
            outputRequest.personalLastName = caseList.get(0).COMM_LastName__c;
            outputRequest.personalVAT = caseList.get(0).COMM_VATNumber__c;
            outputRequest.personalAddress = caseList.get(0).COMM_Address__Street__s;
            outputRequest.personalCity = caseList.get(0).COMM_Address__City__s;
            outputRequest.personalCountry = caseList.get(0).COMM_Address__CountryCode__s;
            outputRequest.personalZipCode = caseList.get(0).COMM_Address__PostalCode__s;
            outputRequest.personalPhoneCode = caseList.get(0).COMM_PhoneNumber__c?.substringBefore(' ');
            outputRequest.personalPhoneNumber = caseList.get(0).COMM_PhoneNumber__c?.substringAfter(' ');
            outputRequest.personalEmail = caseList.get(0).SuppliedEmail;
            outputRequest.jobRole = caseList.get(0).COMM_JobRole__c;
            outputRequest.vehicleBrand = caseList.get(0).COMM_VehicleBrand__c;
            outputRequest.vehicleModel = caseList.get(0).COMM_VehicleModel__c;
            outputRequest.vehicleLicense = caseList.get(0).COMM_LicensePlate__c;
            outputRequest.secondVehicleBrand = caseList.get(0).COMM_SecondaryVehicleBrand__c;
            outputRequest.secondVehicleModel = caseList.get(0).COMM_SecondaryVehicleModel__c;
            outputRequest.secondVehicleLicense = caseList.get(0).COMM_SecondaryLicensePlate__c;
            outputRequest.recordTypeName = caseList.get(0).RecordType.Name;
            outputRequest.recordTypeDeveloperName = caseList.get(0).RecordType.DeveloperName;
            outputRequest.airport = caseList.get(0).COMM_Airport__c;
            outputRequest.status = caseList.get(0).Status;
        } else {
            throw new COMM_SL_WS_GetFormDetailsException(INVALID_CASEID_PARAMETER_ERROR);
        }

        return outputRequest;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_GetFormDetailsException extends Exception {
    }
}