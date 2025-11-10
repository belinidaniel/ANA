/**
 * @author           Miguel Freire
 * @description      Handle of Registration Email Expiration process
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    19/12/2023       Original version
 **/
global without sharing class COMM_SL_RegistrationEmailExpiration {
    private COMM_IREP_User commRepUser;
    private COMM_IREP_UserLogin commRepUserLogin;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_SL_RegistrationEmailExpiration() {
        this.commRepUser = new COMM_REP_User();
        this.commRepUserLogin = new COMM_REP_UserLogin();
    }
    @TestVisible
    private COMM_SL_RegistrationEmailExpiration(COMM_REP_User commRepUser, COMM_REP_UserLogin commRepUserLogin) {
        this.commRepUser = commRepUser;
        this.commRepUserLogin = commRepUserLogin;
    }

    /**
     * @description Method to get the user inputs from email validation.
     *
     * @param pageReference String contaning the encoded userId
     */
    @AuraEnabled
    global static void validateEmailExpiration(String pageReference) {
        new COMM_SL_RegistrationEmailExpiration().handlerValidateEmailExpiration(pageReference);
    }

    /**
     * @description Method to handle the user inputs from email validation.
     * Decodes the userId
     *
     * @param pageReference String contaning the encoded userId
     */
    @TestVisible
    private void handlerValidateEmailExpiration(String pageReference) {
        // Get the parameters from the URL
        String encodedId = COMM_GEN_Utility.getTokenValueFromPageReference(pageReference);
        // Decode userId
        String decodedUserId = COMM_GEN_Utility.decodeBase64(encodedId);
        // Get User information
        List<User> userRecords = commRepUser.getUsersByIdEmailValidation(new Set<Id>{ decodedUserId }, false);
        // Trow error if user wasnt found
        if (userRecords.isEmpty() || userRecords[0].COMM_EmailValidationExpirationDate__c <= Datetime.now()) {
            AuraException newException = new AuraException(System.label.COMM_REGISTER_EMAIL_VALIDATION_FAILED);
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_RegistrationEmailExpiration');
            throw newException;
        }
        // Validate Expiration fields
        validateExpirationFields(userRecords[0]);
        // Query Email Templates by language
        EmailTemplate emailTemplate = new COMM_SL_Email()
            .getEmailTemplates(
                new List<String>{ COMM_DO_Email.EMAIL_TEMPLATE_SUCCESSFUL_EMAIL_VALIDATION },
                userRecords[0].languagelocalekey,
                true
            )[0];
        // Get the OrgWide email address
        List<OrgWideEmailAddress> orgWideNoReplyAddressList = new COMM_REP_OrgWideEmailAddress().getDefaultNoReplyAddress();
        //Send Email with Default No-Reply Org Wide Address if it exists
        if (!orgWideNoReplyAddressList.isEmpty()) {
            COMM_DO_Email.sendEmail(userRecords[0].Id, emailTemplate.Id, orgWideNoReplyAddressList[0].Id);
        }
    }

    /**
     * @description Method to update the user validation email fields.
     *
     * @param userRecord User to be updated
     */
    private void validateExpirationFields(User userRecord) {
        // Update validation status to Validated
        userRecord.COMM_EmailValidationStatus__c = COMM_DO_User.EMAIL_VALIDATION_PICKLIST_VALIDATED;
        // Update validation date to current date
        userRecord.COMM_EmailValidationExpirationDate__c = Datetime.now();
        // Get non-frozen users by Id
        UserLogin userLoginRecord = commRepUserLogin.getUserLoginsByUserId(new Set<Id>{ userRecord.Id })[0];
        // Unfroze the user
        userLoginRecord.IsFrozen = false;
        // update the logins to unfreeze the user
        commRepUserLogin.updateSObjects(new List<UserLogin>{ userLoginRecord });
        // Update User
        try {
            commRepUser.updateSObjects(new List<User>{ userRecord });
        } catch (exception newException) {
            // If of user update fails trow erros
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_RegistrationEmailExpiration');
            throw newException;
        }
    }
}