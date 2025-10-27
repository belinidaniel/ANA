/**
 * @author Daniel Lascas
 * @description Controller for the comm_individualStaffRegistration lwc.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/03/2024       ECOMM-368: Original version
 *
 **/
public with sharing class COMM_LCC_IndividualStaffRegistration {
    private COMM_IREP_Case caseRep;
    private COMM_IREP_User userRep;
    private COMM_IREP_Attachment attachmentRep;

    /**
     * @description Constructor to initialize Repository Classes
     */
    public COMM_LCC_IndividualStaffRegistration() {
        this.userRep = new COMM_REP_User();
        this.caseRep = new COMM_REP_Case();
        this.attachmentRep = new COMM_REP_Attachment();
    }

    @TestVisible
    private COMM_LCC_IndividualStaffRegistration(COMM_IREP_Case caseRep, COMM_IREP_User userRep, COMM_IREP_Attachment attachmentRep) {
        this.caseRep = caseRep;
        this.userRep = userRep;
        this.attachmentRep = attachmentRep;
    }

    /**
     * @description LWC Accessible method to retrieve the picklist values for the Country Field in Addresses
     * Values are returned in a Map where Key = Country Code, Value = Country Name
     **/
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCountryPicklistValues() {
        //Retrieve Country Picklist Values
        Map<String, String> countryPicklistMap = new Map<String, String>();
        for (Schema.PicklistEntry picklistEntry : Account.COMM_CompanyBillingAddress__CountryCode__s.getDescribe().getPicklistValues()) {
            countryPicklistMap.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }
        return countryPicklistMap;
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
     * @description LWC accessible method to verify if User already has a pending Individual Staff Request.
     * @return True if there is a Case Pending, false otherwise.
     */
    @AuraEnabled
    public static Boolean verifyPendingCases() {
        return new COMM_LCC_IndividualStaffRegistration().handleVerifyPendingCases();
    }

    /**
     * @description Handles the Pending Individual Staff Request Pending verification.
     * @return True if there are cases associated with User's Account. False otherwise.
     */
    @TestVisible
    private Boolean handleVerifyPendingCases() {
        //Retrieve User Data and check if he has an Account to return
        List<User> userList = userRep.getUserAccountAndContactDataById(new Set<Id>{ UserInfo.getUserId() });
        if (userList.isEmpty() || userList[0].AccountId == null) {
            //If no Account was found, log error then return false
            AuraException error = new AuraException(System.Label.COMM_ACCOUNT_INFORMATION_NO_DATA_FOUND);
            COMM_GEN_Utility.logError(
                error,
                'Error finding Account Data for User in Individual Staff Request',
                'COMM_LCC_IndividualStaffRegistration'
            );
            return false;
        }
        //Verify if any Pending Cases exist
        List<Case> caseList = caseRep.getIndividualStaffRequestPendingByAccountId(new Set<Id>{ userList[0].AccountId }, false);
        return !caseList.isEmpty();
    }

    /**
     * @description LWC Accessible method to create a new case with inputed data
     *
     * @param caseRecord Case Data obtained from front-end
     * @param fileName Name of the file attached to request
     * @param fileData Data of the file attached to request
     **/
    @AuraEnabled
    public static void submitCase(Case caseRecord, String fileName, String fileData) {
        new COMM_LCC_IndividualStaffRegistration().handleSubmitCase(caseRecord, fileName, fileData);
    }

    /**
     * @description LWC Accessible method to get user info data
     *
     * @param userId User Id
     **/
    @AuraEnabled(cacheable=true)
    public static User getUserInfo(Id userId) {
        if (String.isBlank(userId)) {
            return null;
        }

        return [
            SELECT Id,
                   FirstName,
                   LastName,
                   ContactId,
                   Contact.FirstName,
                   Contact.LastName,
                   Email,
                   Contact.Account.COMM_VATNumberWithCode__c,
                   Contact.Account.PersonMobilePhone,
                   Contact.Account.BillingPostalCode,
                   Contact.Account.BillingStreet,
                   Contact.Account.BillingCountry,
                   Contact.Account.BillingCountryCode,
                   Contact.Account.BillingCity
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
    }

    /**
     * @description Method to create Case based on data provided by the User on the Component
     * Attaches User uploaded file to Case after creation
     *
     * @param caseRecord Case Data obtained from front-end
     * @param fileName Name of the file attached to request
     * @param fileData Data of the file attached to request
     **/
    @TestVisible
    private void handleSubmitCase(Case caseRecord, String fileName, String fileData) {
        try {
            //If a Pending Case already exists throw error message
            if (handleVerifyPendingCases()) {
                throw new AuraException('A Pending Case already exists');
            }

            //Set Case's Language to User's and Status to In Approval
            caseRecord.COMM_Language__c = UserInfo.getLanguage();
            caseRecord.Status = COMM_DO_Case.WAITING_APPROVAL_STATUS;
            caseRecord.Type = COMM_DO_Case.INDIVIDUAL_STAFF_TYPE;
            caseRecord.Origin = COMM_DO_Case.WEB_ORIGIN;
            caseRecord.RecordTypeId = COMM_GEN_Utility.getRecordTypeIdByDevName(Case.SObjectType, COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT);

            //Set assignment rules to run on Case Insert
            Database.DMLOptions dmlOptn = new Database.DMLOptions();
            dmlOptn.assignmentRuleHeader.useDefaultRule = true;
            caseRecord.setOptions(dmlOptn);

            caseRep.insertSObjects(new List<Case>{ caseRecord });
            //Add Attached File to Case if it has Data
            if (fileData != null) {
                Blob fileBody = EncodingUtil.base64Decode(fileData);
                Attachment fileRecord = new Attachment();
                fileRecord.Name = fileName;
                fileRecord.Body = fileBody;
                fileRecord.ParentId = caseRecord.Id;
                attachmentRep.insertSObjects(new List<Attachment>{ fileRecord });
            }
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Submitting Case', 'COMM_LCC_IndividualStaffRegistration');
            throw e;
        }
    }
}