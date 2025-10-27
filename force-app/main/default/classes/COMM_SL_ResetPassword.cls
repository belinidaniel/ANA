/**
 * @author Daniel Lascas
 * @description Service Layer class for Reset Password logic used by the
 * Forgot Password and Change Password components in Community
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 **/
public without sharing class COMM_SL_ResetPassword {
    //Validation Setting
    private COMM_PortalValidationSetting__mdt portalSetting;
    private static final String PORTAL_SETTING_PROCESS_NAME = 'ResetPassword';
    private static final String START_URL_PARAMETER = '&startURL=';
    private static final String URL_LANGUAGE_PARAMETER = '&language=';

    private COMM_IREP_User userRep;
    private COMM_IREP_OrgWideEmailAddress oweaRep;
    private COMM_ISL_Email getTemplateSl;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_SL_ResetPassword() {
        this.userRep = new COMM_REP_User();
        this.oweaRep = new COMM_REP_OrgWideEmailAddress();
        this.getTemplateSl = new COMM_SL_Email();
    }

    @TestVisible
    private COMM_SL_ResetPassword(COMM_IREP_User userRep, COMM_IREP_OrgWideEmailAddress oweaRep, COMM_ISL_Email getTemplateSl) {
        this.userRep = userRep;
        this.oweaRep = oweaRep;
        this.getTemplateSl = getTemplateSl;
    }

    /**
     * @description Method to validate the Reset Password Token.
     * Receive an encrypted token, decrypt it and verify that it's the expected structure, has a valid User Id,
     * said User exists, User resetted his password and link is valid.
     *
     * @param token Token to validate
     * @return User Record if token is valid. NULL if invalid.
     */
    public User handleValidateResetToken(String token) {
        //Decrypt to obtain Token
        String decryptedToken = COMM_GEN_Utility.decryptRecordIdentifier(token, COMM_GEN_Utility.USER_KEY_NAME);
        TokenWrapper tokenWrapper = (TokenWrapper) JSON.deserializeStrict(decryptedToken, TokenWrapper.class);

        List<User> userRecordsList = userRep.getUserValidationById(new Set<Id>{ tokenWrapper.userId }, false);
        // Check if expiration date is expired, User resetted his password and token has expected request datetime
        if (
            !userRecordsList.isEmpty() &&
            userRecordsList[0].COMM_IsPasswordReseted__c &&
            Datetime.now() <= userRecordsList[0].COMM_ResetPasswordEmailExpirationDate__c &&
            tokenWrapper.requestDate.toString().equals(userRecordsList[0].COMM_ResetPasswordEmailExpirationDate__c.toString())
        ) {
            return userRecordsList[0];
        }

        return null;
    }

    /**
     * @description Method to handle the Change Password Login
     *
     * @param userId Id of the User whose Password will change
     * @param newPassword The User's new password
     */
    public void handleChangePassword(Id userId, String newPassword) {
        try {
            List<User> userRecords = userRep.getUserWithLaguageFieldById(new Set<Id>{ userId }, false);
            if (userRecords.isEmpty()) {
                throw new AuraException('No User Found');
            }

            System.setPassword(userId, newPassword);

            // Query Email Templates by language
            List<EmailTemplate> templateList = getTemplateSl
                .getEmailTemplates(new List<String>{ COMM_DO_Email.EMAIL_TEMPLATE_PASSWORD_RESETED }, userRecords[0].LanguageLocaleKey, true);
            if (!templateList.isEmpty()) {
                // Send Email
                sendEmail(userId, templateList[0].Id);
                // Update the is password reseted field
                User userRecord = new User(Id = userId, COMM_IsPasswordReseted__c = false);
                // Update Contact(PersonAccount)
                userRep.updateSObjects(new List<User>{ userRecord });
            }
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error Resetting User Password', 'COMM_SL_ResetPassword');
            throw e;
        }
    }

    /**
     * @description Method to handle the Forgot Password Request.
     * Checks if a User that uses the Normal Login exists with the provided email.
     * If he does start the Forgot Password Logic, if not throw execption that User doesn't exist
     *
     * @param email Email of the User's that forgot his password
     * @param communityURL The Community Site's Url where the request was made
     * @param communityName API Name of the Community
     * @param startUrl URL user is redirected on login after password set
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void resetPassword(String email, String communityURL, String communityName, String startUrl) {
        // Check if a External Identity User alredy exists with the provider email and login type 'Normal'
        List<User> userRecords = userRep.getUserByEmailAndLoginType(
            new Set<String>{ email },
            new Set<String>{ COMM_DO_User.NORMAL_LOGIN_IDENTIFIER },
            false
        );

        if (userRecords.isEmpty()) {
            AuraException error = new AuraException(System.Label.COMM_FORGOT_PASSWORD_RESET_FAILED);
            COMM_GEN_Utility.logError(error, 'No user found when resetting password', 'COMM_SL_ResetPassword');
            throw error;
        } else if (
            userRecords[0].COMM_LoginType__c == COMM_DO_User.GOOGLE_SSO_IDENTIFIER ||
            userRecords[0].COMM_LoginType__c == COMM_DO_User.FACEBOOK_SSO_IDENTIFIER
        ) {
            AuraException error = new AuraException(System.Label.COMM_FORGOT_PASSWORD_RESET_FAILED);
            COMM_GEN_Utility.logError(error, 'This user can´t reset his password', 'COMM_SL_ResetPassword');
            throw error;
        }
        String userId = userRecords[0].Id;
        String languageCode = userRecords[0].LanguageLocaleKey;

        resetUserPassword(userId, languageCode, communityURL, communityName, startUrl, true);
    }

    /**
     * @description Method to handle the Reset Password.
     * Logic is shared for Forgot Password and Change Password Request
     *
     * @param userId Id of the User whose password will be reset
     * @param languageCode Code of the Language that is used on the sent Email Templates
     * @param communityURL The Community Site's Url where the request was made
     * @param communityName API Name of the Community
     * @param startUrl URL user is redirected on login after password set
     * @param isForgotPassword Boolean indicating if reset is due to Forgot Password component or Change Password
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void resetUserPassword(
        Id userId,
        String userLanguage,
        String communityURL,
        String communityName,
        String startUrl,
        Boolean isForgotPassword
    ) {
        portalSetting = COMM_DO_PortalValidationSetting.getPortalSetting(communityName, PORTAL_SETTING_PROCESS_NAME);

        //Verify User exists
        List<User> userRecords = userRep.getUserValidationById(new Set<Id>{ userId }, !isForgotPassword);
        if (userRecords.isEmpty()) {
            AuraException error = new AuraException(System.Label.COMM_FORGOT_PASSWORD_RESET_FAILED);
            throw error;
        }
        //Verify User Reset Window Limits
        Datetime lastRequestDate = userRecords[0].COMM_LastPasswordRetrievalTime__c;
        Datetime nextRequestResetDate = lastRequestDate?.addMinutes(Integer.valueOf(portalSetting.COMM_PasswordRetrievalWindow__c));
        if (
            lastRequestDate != null &&
            Datetime.now() < nextRequestResetDate &&
            userRecords[0].COMM_PasswordRetrievalCount__c >= portalSetting.COMM_MaxPasswordRetrievals__c
        ) {
            AuraException error = new AuraException(System.Label.COMM_FORGOT_PASSWORD_RESET_FAILED);
            throw error;
        }
        //Obtain new reset number. If last requets window is in the past then number is reset to 1.
        Decimal resetNumber = userRecords[0].COMM_PasswordRetrievalCount__c == null ||
            lastRequestDate == null ||
            Datetime.now() >= nextRequestResetDate
            ? 1
            : userRecords[0].COMM_PasswordRetrievalCount__c + 1;

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
        String tokenKey = isForgotPassword ? COMM_DO_Email.ENCODED_USERID_BASE64_STRING : COMM_DO_Email.ENCODED_CHANGE_PASSWORD_BASE64_STRING;
        String resetUrl =
            communityURL +
            String.valueOf(portalSetting.COMM_ValidationPageURL__c) +
            tokenKey +
            encriptedToken +
            URL_LANGUAGE_PARAMETER +
            userLanguage;

        //Add Start URL to URL so User is redirected when Logging in after setting new password (ex: User redirected to commerce)
        if (String.isNotBlank(startUrl)) {
            resetUrl += START_URL_PARAMETER + startUrl;
        }
        //Update User's Record with Reset Validation Details
        updateUserAccount(userId, resetUrl, token.requestDate, resetNumber);
        // Reset Password and Send Email
        resetPasswordWithEmail(userId, userLanguage, isForgotPassword);
    }

    /**
     * @description Update User's Record with the Validation Values used in the Password Request
     *
     * @param userId Id of the User that requested the Password Reset
     * @param resetUrl The page Url where the User will be able to set his new Password
     * @param requestDate Datetime of when request was made
     * @param resetNumber Number of Password Resets performed
     */
    private void updateUserAccount(Id userId, String resetUrl, Datetime requestDate, Decimal resetNumber) {
        User userRecord = new User(Id = userId);
        // Update Url field
        userRecord.COMM_ResetPasswordEmailUrl__c = resetUrl;
        // Update the expiration date
        userRecord.COMM_ResetPasswordEmailExpirationDate__c = requestDate;
        // Update the is password reseted field
        userRecord.COMM_IsPasswordReseted__c = true;
        // Update fields used to verify reset limit windows
        userRecord.COMM_PasswordRetrievalCount__c = resetNumber;
        userRecord.COMM_LastPasswordRetrievalTime__c = Datetime.now();
        // Update Record
        try {
            userRep.updateSObjects(new List<User>{ userRecord });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error Setting User Password Reset Validation', 'COMM_SL_ResetPassword');
            throw e;
        }
    }

    /**
     * @description Reset the User's Password and send email with instructions with how to proceed.
     *
     * @param userId Id of the User that requested the Password Reset
     * @param languageCode The language to be used in the email
     * @param isForgotPassword Boolean indicating if reset is due to Forgot Password component or Change Password
     */
    private void resetPasswordWithEmail(Id userId, String languageCode, Boolean isForgotPassword) {
        //Obtain Forgot Email Template for User's Language
        List<EmailTemplate> templateList = getTemplateSl.getEmailTemplates(
            new List<String>{ isForgotPassword ? COMM_DO_Email.EMAIL_TEMPLATE_FORGOT_PASSWORD : COMM_DO_Email.EMAIL_TEMPLATE_CHANGE_PASSWORD },
            languageCode,
            true
        );

        if (!templateList.isEmpty()) {
            //Send Email to User with Custom Password Page URL
            sendEmail(userId, templateList[0].Id);
        }
    }

    /**
     * @description Send Email to User
     *
     * @param userId Id of the User that will receive the email
     * @param templateId Id of the Template to be used
     */
    private void sendEmail(Id userId, Id templateId) {
        // Check for a OrgWide email address to be used
        List<OrgWideEmailAddress> orgWideNoReplyAddressList = oweaRep.getDefaultNoReplyAddress();
        //Send Email with Default No-Reply Org Wide Address if it exists
        COMM_DO_Email.sendEmail(userId, templateId, orgWideNoReplyAddressList.isEmpty() ? null : orgWideNoReplyAddressList[0].Id);
    }

    /**
     * @description Wrapper of Token used to validate Reset Password request.
     * Stores User Id and Datetime of when request was made.
     */
    @TestVisible
    private class TokenWrapper {
        public String userId;
        public Datetime requestDate;
    }
}