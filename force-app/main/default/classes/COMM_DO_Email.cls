/**
 * @author Daniel Lascas
 * @description Email Template object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/01/2024       Original version
 **/
public inherited sharing class COMM_DO_Email {
    public final static string ENCODED_USERID_BASE64 = 'dXNlcklk';
    public final static string ENCODED_USERID_BASE64_STRING = '?dXNlcklk=';
    public final static string ENCODED_CHANGE_PASSWORD_BASE64_STRING = '?Y2hhbmdlUGFzc3dvcmQ=';
    public final static string EMAIL_TEMPLATE_FORGOT_PASSWORD = 'COMM_ResetPassword';
    public final static string EMAIL_TEMPLATE_CHANGE_PASSWORD = 'COMM_ChangePassword';
    public final static string EMAIL_TEMPLATE_PASSWORD_RESETED = 'COMM_PasswordConfirmed';
    public final static string NEW_EMAIL_CHANGE_TEMPLATE_NAME = 'COMM_EMAIL_ChangeEmailNewAddress';
    public final static string OLD_EMAIL_CHANGE_TEMPLATE_NAME = 'COMM_EMAIL_ChangeEmailOldAddress';
    public final static string EMAIL_TEMPLATE_EMAIL_VALIDATION = 'COMM_EMAIL_EmailValidation';
    public final static string EMAIL_TEMPLATE_AFFILIATE_EMAIL_VALIDATION = 'COMM_Affiliate_EmailValidation';
    public final static string EMAIL_TEMPLATE_SUCCESSFUL_EMAIL_VALIDATION = 'COMM_EMAIL_SuccessfulEmailValidation';
    public final static string DEFAULT_EMAIL_LANGUAGE = 'en_US';
    public final static string EMAIL_TEMPLATE_REPLACE_URL_STRING = '###CurrentOrganizationSFURL###';
    public final static string EMAIL_TEMPLATE_REPLACE_SITEURL_STRING = '###CurrentOrganizationURL###';
    public final static string EMAIL_TEMPLATE_REPLACE_CASE_RECORD_TO_ENCRYPT_STRING = '###CaseRecordId###';
    public final static string EMAIL_TEMPLATE_REPLACE_TOKEN_TO_ENCRYPT_STRING = '###TokenToEncrypt###';
    public final static string EMAIL_TEMPLATE_REPLACE_MANUAL_RENEWAL_LIST = '###ManualRenewalRecordList###';
    public final static string EMAIL_TEMPLATE_REPLACE_AUTOMATIC_RENEWAL_LIST = '###AutomaticRenewalRecordList###';
    public final static string EMAIL_TEMPLATE_REPLACE_MANUAL_RENEWAL_LIST_BLOCK = '###ManualRenewalRecordListBlock###';
    public final static string EMAIL_TEMPLATE_REPLACE_AUTOMATIC_RENEWAL_LIST_BLOCK = '###AutomaticRenewalRecordListBlock###';
    public final static string EMAIL_TEMPLATE_REPLACE_LIST_PRODUCT_BY_FAMILY = '###ListOfProductsByFamily###';

    private static final String START_URL_PARAMETER = '&startURL=';
    private static final String URL_LANGUAGE_PARAMETER = '&language=';
    //Retrieve Checkout URL from Custom Metadata
    private static final String CHECKOUT_URL = EncodingUtil.urlEncode(
        COMM_DO_PortalValidationSetting.getPortalSetting('Customers_Portal1', 'CheckoutRedirection')?.COMM_ValidationPageURL__c,
        'UTF-8'
    );

    /**
     * @description Method to send email to Recipient using Template. Email is sent with Org Default Address if provided.
     *
     * @param recipientId Id of the Recipient (User, Contact) to receive the Email
     * @param templateId Id of the Template to be used in the generated Email
     * @param orgDefaultAddressId (Opcional) Id of an Org Default Address if email is to be sent as from that address
     */
    public static void sendEmail(Id recipientId, Id templateId, Id orgDefaultAddressId) {
        // Build Email
        Messaging.SingleEmailMessage emailRecord = Messaging.renderStoredEmailTemplate(templateId, recipientId, null);
        emailRecord.setSaveAsActivity(false);
        emailRecord.setUseSignature(false);
        if (String.isNotBlank(orgDefaultAddressId)) {
            //Send Email with Default No-Reply Org Wide Address if it exists
            emailRecord.setOrgWideEmailAddressId(orgDefaultAddressId);
        }
        // Send Email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ emailRecord }, false);
    }

    /**
     * @description Method to encode the user id and create the link that will be sent in the validation email.
     *
     * @param userRecord User created
     * @param redirectUrl URL that user is redirected after logging in when confirming account
     * @param emailTemplateName Email template to send
     * @param goToCheckout Boolean indicating that user is to be redirected to checkout page instead of url
     */
    public static void encodeIdAndSetEmail(User userRecord, String redirectUrl, String emailTemplateName, Boolean goToCheckout) {
        // Encode userId
        String encodedUserId = COMM_GEN_Utility.convertToBase64(userRecord.Id);
        // Get Environment Metadata Record
        COMM_PortalValidationSetting__mdt portalValidationSetting = COMM_DO_PortalValidationSetting.getPortalSettingByEnvironmentId(
            UserInfo.getOrganizationId()
        );
        // Update Url
        String portalValidationUrl =
            portalValidationSetting.COMM_EnvironmentCustomersUrl__c +
            portalValidationSetting.COMM_EnvironmentSelfRegPageLabel__c +
            COMM_DO_Email.ENCODED_USERID_BASE64_STRING +
            encodedUserId +
            URL_LANGUAGE_PARAMETER +
            userRecord.languagelocalekey;
        //Add Start URL to URL so User is redirected when Logging in on first try (ex: User redirected to commerce)
        if (goToCheckout) {
            //If User is to Go to Commerce Checkout on Login then add checkout url
            portalValidationUrl += START_URL_PARAMETER + CHECKOUT_URL;
        } else if (String.isNotBlank(redirectUrl)) {
            portalValidationUrl += START_URL_PARAMETER + EncodingUtil.urlEncode(redirectUrl, 'UTF-8');
        }
        // Call Queuable class to update user and send email
        System.enqueueJob(new COMM_Async_UpdateAfterRegisterQueuable(userRecord, portalValidationUrl, emailTemplateName));
    }
}