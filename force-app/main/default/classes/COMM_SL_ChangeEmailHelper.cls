/**
 * @author Daniel Lascas
 * @description Helper Class for Service Layer used to change an external
 * User's Email. Stores logic that requires execution without sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/03/2024       ECOMM-1495: Original version
 **/
public without sharing class COMM_SL_ChangeEmailHelper {
    private COMM_IREP_User userRep;
    private COMM_IREP_Contact contactRep;
    private COMM_IREP_OrgWideEmailAddress orgWideRep;

    /**
     * @description Class constructor to initialize REP
     */
    public COMM_SL_ChangeEmailHelper() {
        this.userRep = new COMM_REP_User();
        this.contactRep = new COMM_REP_Contact();
        this.orgWideRep = new COMM_REP_OrgWideEmailAddress();
    }

    @TestVisible
    private COMM_SL_ChangeEmailHelper(COMM_IREP_User userRep, COMM_IREP_Contact contactRep, COMM_IREP_OrgWideEmailAddress orgWideRep) {
        this.userRep = userRep;
        this.contactRep = contactRep;
        this.orgWideRep = orgWideRep;
    }

    /**
     * @description Method to send the Email Change Validation to the External User's
     * new Email Address
     *
     * @param userId Id of the User whose email is to be changed
     * @param newEmail The new Email to be used by the User
     * @param emailTemplateList List of the Email Templates to be used to generate the emails
     **/
    public void sendEmailChangeValidation(Id userId, String newEmail, List<EmailTemplate> emailTemplateList) {
        try {
            List<OrgWideEmailAddress> orgWideNoReplyAddressList = orgWideRep.getDefaultNoReplyAddress();
            Id newEmailChangeTemplateId;
            Id oldEmailChangeTemplateId;

            //Check in Template List if first Template is for the New Email Address or the Old/Current Address
            if (emailTemplateList[0].Name.startsWith(COMM_DO_Email.NEW_EMAIL_CHANGE_TEMPLATE_NAME)) {
                newEmailChangeTemplateId = emailTemplateList[0].Id;
                oldEmailChangeTemplateId = emailTemplateList[1].Id;
            } else {
                newEmailChangeTemplateId = emailTemplateList[1].Id;
                oldEmailChangeTemplateId = emailTemplateList[0].Id;
            }

            //Generate Email from Template
            Messaging.SingleEmailMessage mailFromTemplateForNewAddress = Messaging.renderStoredEmailTemplate(newEmailChangeTemplateId, userId, null);
            Messaging.SingleEmailMessage oldAddressMailToSend = Messaging.renderStoredEmailTemplate(oldEmailChangeTemplateId, userId, null);

            //Generate Email to send from Email generated from Template (to avoid sending the email for the new address to the User's current address)
            Messaging.SingleEmailMessage newAddressMailToSend = new Messaging.SingleEmailMessage();
            newAddressMailToSend.setPlainTextBody(mailFromTemplateForNewAddress.getPlainTextBody());
            newAddressMailToSend.setHtmlBody(mailFromTemplateForNewAddress.getHtmlBody());
            newAddressMailToSend.setSubject(mailFromTemplateForNewAddress.getSubject());
            newAddressMailToSend.setToAddresses(new List<String>{ newEmail });
            if (!orgWideNoReplyAddressList.isEmpty()) {
                //Send Email with Default No-Reply Org Wide Address if it exists
                newAddressMailToSend.setOrgWideEmailAddressId(orgWideNoReplyAddressList[0].Id);
                oldAddressMailToSend.setOrgWideEmailAddressId(orgWideNoReplyAddressList[0].Id);
            }
            newAddressMailToSend.setSaveAsActivity(false);
            newAddressMailToSend.setUseSignature(false);
            oldAddressMailToSend.setSaveAsActivity(false);
            oldAddressMailToSend.setUseSignature(false);
            List<Messaging.SendEmailResult> resultList = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ newAddressMailToSend, oldAddressMailToSend },
                false
            );
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error Generating and Sending Emails to Customer', 'COMM_SL_ChangeEmailHelper');
            throw e;
        }
    }

    /**
     * @description Method to validate a User's email change request.
     * Checks if user's request is valid, if it is then update User's Records with new email.
     *
     * @param userId Id of the User that requested the email change.
     * @param requestDate Date of when request was made (for validation)
     * @return True if Email was changed successfully, false otherwise.
     **/
    public Boolean emailChangeValidation(String userId, Datetime requestDate) {
        try {
            List<User> userList = userRep.getUsersWithEmailChangeValidationById(new Set<Id>{ userId }, false);

            //Verify is User wasn't found or Email Validation is invalid
            if (
                userList.isEmpty() ||
                userList[0].COMM_EmailValidationExpirationDate__c == null ||
                userList[0].COMM_EmailValidationExpirationDate__c < System.now() ||
                userList[0].COMM_EmailValidationChangedAddress__c == null ||
                !requestDate.toString().equals(userList[0].COMM_EmailValidationExpirationDate__c.toString())
            ) {
                return false;
            }

            //If valid update User's Contact and User Records with new Email and clear validation
            Contact userContact = new Contact(Id = userList[0].ContactId);
            userContact.Email = userList[0].COMM_EmailValidationChangedAddress__c;

            User userRecord = new User(Id = userList[0].Id);
            userRecord.Email = userList[0].COMM_EmailValidationChangedAddress__c;
            userRecord.COMM_EmailValidationChangedAddress__c = null;
            userRecord.COMM_EmailValidationExpirationDate__c = null;
            userRecord.COMM_EmailValidationURL__c = null;

            contactRep.updateSObjects(new List<Contact>{ userContact });
            userRep.updateSObjects(new List<User>{ userRecord });

            return true;
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error Changing Email', 'COMM_SL_ChangeEmailHelper');
            throw e;
        }
    }
    /**
     * @description Method to validate a User's email change request.
     * Checks if is not identity provider user. Checks if the User´s new email can be used
     *
     * @param newEmail New User email
     **/
    public void checkForExistingUser(String newEmail) {
        // Check if a non Partner User alredy exists
        User identityUserRecord = userRep.getActiveNonPartnerUserByEmail(newEmail, false);
        if (identityUserRecord != null) {
            // If an identity user exists with this email already exists trow error
            AuraException newException = new AuraException(System.label.COMM_REGISTER_REGISTRATION_FAILED);
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_ChangeEmailHelper');
            throw newException;
        }
    }
}