/**
 * @author         Miguel Freire
 * @description    COMM_Async_UpdateUserAfterRegistration Queuable class to update the user fields and send the validation email after the registration
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date          Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire     21/03/2024     Original version
 * Daniel Reto	     05/07/2024     ECOMM-1660: New Parameter
 **/
public without sharing class COMM_Async_UpdateAfterRegisterQueuable implements Queueable {
    private COMM_IREP_User commRepUser;
    private COMM_IREP_UserLogin commRepUserLogin;

    @TestVisible
    private User userRecord;
    private String resetUrl;
    private String emailTemplateName;

    /**
     * @description Class Constructor to initiate REP classes
     */
    @TestVisible
    private COMM_Async_UpdateAfterRegisterQueuable(COMM_REP_User commRepUser) {
        this.commRepUser = commRepUser;
        this.commRepUserLogin = commRepUserLogin;
    }

    /**
     * @description Method to get the user inputs from self register.
     *
     * @param userRecord User input from self register page
     * @param contactRecord User input from self register page
     * @param resetUrl String to insert on the User field
     */
    public COMM_Async_UpdateAfterRegisterQueuable(User userRecord, String resetUrl, String emailTemplateName) {
        this.userRecord = userRecord;
        this.resetUrl = resetUrl;
        this.emailTemplateName = emailTemplateName;
        this.commRepUser = new COMM_REP_User();
        this.commRepUserLogin = new COMM_REP_UserLogin();
    }

    /**
     * @description Method to execute Queuable class that updates the user and send a validation email.
     *
     * @param context Queuable context
     */
    public void execute(QueueableContext context) {
        userRecord.COMM_EmailValidationURL__c = resetUrl;
        // Update expiration date field
        userRecord.COMM_EmailValidationExpirationDate__c = Datetime.now()
            .addDays(
                Integer.valueOf(
                    COMM_DO_PortalValidationSetting.getPortalSettingByEnvironmentId(UserInfo.getOrganizationId())
                        .COMM_EnvironmentLinkExpirationTermLenght__c
                )
            );
        // Update validation status field
        userRecord.COMM_EmailValidationStatus__c = COMM_DO_User.EMAIL_VALIDATION_PICKLIST_INVALIDATION;
        // Update User
        commRepUser.updateSObjects(new List<User>{ userRecord });
        // Get non-frozen users by Id
        UserLogin userLoginRecord = commRepUserLogin.getUserLoginsByUserId(new Set<Id>{ userRecord.Id })[0];
        // Froze the user
        userLoginRecord.IsFrozen = true;
        // update the logins to freeze the users
        commRepUserLogin.updateSObjects(new List<UserLogin>{ userLoginRecord });
        // Query Email Templates by language
        EmailTemplate emailTemplate = new COMM_SL_Email()
            .getEmailTemplates(new List<String>{ emailTemplateName }, userRecord.languagelocalekey, true)[0];
        // Get the OrgWide email address
        List<OrgWideEmailAddress> orgWideNoReplyAddressList = new COMM_REP_OrgWideEmailAddress().getDefaultNoReplyAddress();
        //Send Email with Default No-Reply Org Wide Address if it exists
        if (!orgWideNoReplyAddressList.isEmpty()) {
            COMM_DO_Email.sendEmail(userRecord.Id, emailTemplate.Id, orgWideNoReplyAddressList[0].Id);
        }
    }
}