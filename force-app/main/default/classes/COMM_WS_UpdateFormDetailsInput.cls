/**
 * @author Daniel Reto
 * @description Model for update Form Details.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      23/10/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_UpdateFormDetailsInput {
    global String caseId;
    global String personalFirstName;
    global String personalLastName;
    global String personalVAT;
    global String personalEmail;
    global String personalPhoneNumber;
    global String personalAddress;
    global String personalZipCode;
    global String personalCity;
    global String personalCountry;
    global String jobRole;
    global String vehicleLicense;
    global String vehicleBrand;
    global String vehicleModel;
    global String secondVehicleLicense;
    global String secondVehicleBrand;
    global String secondVehicleModel;
    global String privacyConsent;
    global String licenseReadingConsent;
    global String marketingConsent;
    global String formLanguage;
    global String status;
    global String fileName;
    global String fileData;
    global String airport;

    public static COMM_WS_UpdateFormDetailsInput parse(String json) {
        return (COMM_WS_UpdateFormDetailsInput) System.JSON.deserialize(json, COMM_WS_UpdateFormDetailsInput.class);
    }
}