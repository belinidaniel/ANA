/**
 * @author Daniel Lascas
 * @description Service Layer Class with methods used to change an external
 * User's Email
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/03/2024       ECOMM-343: Original version
 * Daniel Lascas    26/06/2024       ECOMM-1495: Refactor logic
 **/
public with sharing class COMM_SL_ChangeEmail {
    //Validation Setting
    private COMM_PortalValidationSetting__mdt portalSetting;
    private static final String PORTAL_SETTING_PROCESS_NAME = 'ChangeEmail';

    private COMM_IREP_User userRep;
    private COMM_ISL_Email getEmailSL;
    private COMM_SL_ChangeEmailHelper changeEmailHelperSl;

    /**
     * @description Class constructor to initialize REP and SLs
     */
    public COMM_SL_ChangeEmail() {
        this.userRep = new COMM_REP_User();
        this.getEmailSL = new COMM_SL_Email();
        this.changeEmailHelperSl = new COMM_SL_ChangeEmailHelper();
    }

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_SL_ChangeEmail(COMM_IREP_User userRep, COMM_ISL_Email getEmailSL, COMM_SL_ChangeEmailHelper changeEmailHelperSl) {
        this.userRep = userRep;
        this.getEmailSL = getEmailSL;
        this.changeEmailHelperSl = changeEmailHelperSl;
    }

    /**
     * @description Method to initiate the change user's email process
     *
     * @param userId Id of the User whose Email is to be changed
     * @param languageCode Language to be used on the emails sent to the User's email addresses
     * @param newEmail The new email address the user will use
     * @param communityURL The url of the community where the request was made
     * @param communityName The API Name of the Community whose setting is to be retrieved
     **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void changeEmail(Id userId, String languageCode, String newEmail, String communityURL, String communityName) {
        // Check if User login type is Google or Facebook
        List<User> userRecords = userRep.getUsersById(new Set<Id>{ userId });
        if (
            userRecords[0].COMM_LoginType__c == COMM_DO_User.GOOGLE_SSO_IDENTIFIER ||
            userRecords[0].COMM_LoginType__c == COMM_DO_User.FACEBOOK_SSO_IDENTIFIER
        ) {
            // If the user login type is Google or Facebook trow error
            AuraException newException = new AuraException(System.label.COMM_REGISTER_REGISTRATION_FAILED);
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_ChangeEmail');
            throw newException;
        }
        //Check if User is allowed to change email, and if the new email is available to be used
        changeEmailHelperSl.checkForExistingUser(newEmail);
        //Retrieve Validation Setting for Portal Site
        portalSetting = COMM_DO_PortalValidationSetting.getPortalSetting(communityName, PORTAL_SETTING_PROCESS_NAME);

        //Retrieve Email Template to be sent to old and new email address
        List<String> emailTemplateNameList = new List<String>{
            COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME,
            COMM_DO_Email.OLD_EMAIL_CHANGE_TEMPLATE_NAME
        };
        List<EmailTemplate> emailTemplateList = getEmailSL.getEmailTemplates(emailTemplateNameList, languageCode, false);

        //Instatiate Token with User Id and Request Datetime
        TokenWrapper token = new TokenWrapper();
        token.userId = userId;
        token.requestDate = Datetime.now().addHours(Integer.valueOf(portalSetting.COMM_ExpirationTimeHours__c));
        // Encrypt token and encode it to be usable as URL parameter
        String encriptedToken = EncodingUtil.urlEncode(
            COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME),
            'UTF-8'
        );
        // Update Url
        String validationUrl = communityURL + String.valueOf(portalSetting.COMM_ValidationPageURL__c) + encriptedToken;

        // Update User Record with Validation Values (to detect expiration or invalid link)
        updateUserValidation(userId, newEmail, validationUrl, token.requestDate);
        changeEmailHelperSl.sendEmailChangeValidation(userId, newEmail, emailTemplateList);

        return;
    }

    /**
     * @description Method to update the User's Contact Record with Email Change Request Detail
     * to detect expiration or invalid link
     *
     * @param userId Id of the User whose email is to be changed
     * @param newEmail The new Email to be used by the User
     * @param validationUrl URL Link that the User will use to validate the email change
     * @param requestDate Datetime of when Email Change request was made (for validation)
     **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void updateUserValidation(Id userId, String newEmail, String validationUrl, Datetime requestDate) {
        try {
            User userRecord = new User(Id = userId);
            userRecord.COMM_EmailValidationChangedAddress__c = newEmail;
            userRecord.COMM_EmailValidationExpirationDate__c = requestDate;
            userRecord.COMM_EmailValidationURL__c = validationUrl;
            userRep.updateSObjects(new List<User>{ userRecord });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error setting up Email Change Validation', 'COMM_SL_ChangeEmail');
            throw e;
        }
    }

    /**
     * @description Method to validate a User's email change request.
     * Checks if user's request is valid, if it is then update User's Records with new email.
     *
     * @param token Token with encrypted request.
     * @return True if token is valid and Email was changed successfully, false otherwise.
     **/
    public Boolean validateEmailChange(String token) {
        TokenWrapper tokenWrapper;
        try {
            //Decrypt to obtain Token
            String decryptedToken = COMM_GEN_Utility.decryptRecordIdentifier(token, COMM_GEN_Utility.USER_KEY_NAME);
            tokenWrapper = (TokenWrapper) JSON.deserializeStrict(decryptedToken, TokenWrapper.class);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error Decrypting Token', 'COMM_SL_ChangeEmail');
            throw e;
        }
        return changeEmailHelperSl.emailChangeValidation(tokenWrapper.userId, tokenWrapper.requestDate);
    }

    /**
     * @description Wrapper of Token used to validate Email Change request.
     * Stores User Id and Datetime of when request was made.
     */
    @TestVisible
    private class TokenWrapper {
        public String userId;
        public Datetime requestDate;
    }
}