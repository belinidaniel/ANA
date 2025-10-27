/**
 * @author           Daniel Lascas
 * @description      Service Layer Class with method to send an email to
 *                   a recipient that doesn't have a record in Salesforce.
 *                   For use in Flows.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/01/2024       Original version
 * Daniel Lascas    05/02/2024       Added Target Id to logic (to allow sending to User Record)
 * Daniel Reto      24/04/2024       Open createEmail to be used on other apex classes
 **/
public without sharing class COMM_SL_SendEmail {
    public class InputWrapper {
        @InvocableVariable(label='Template Id' description='Id of the Template to be used' required=true)
        public String templateId;
        @InvocableVariable(label='Address to receive Email')
        public List<String> recipientEmail;
        @InvocableVariable(
            label='Id of recipient Record'
            description='(Opcional) Used when the email is to be sent to a record that isn\'t a Contact Record like a User Record. The recipient email field needs to be empty for this recipient to be used.'
        )
        public String targetId;
        @InvocableVariable(label='Id of the Related Record (for template merge fields)')
        public Id whatId;
        @InvocableVariable(label='Org-Wide Address Id' description='(Opcional) Id of the Organization-Wide Address that will send the Email')
        public Id orgWideId;
        @InvocableVariable(label='Store Email Sent as an Activity' description='(Opcional) Store Email as an Activity on the Related Record')
        public Boolean saveAsActivity;
    }

    private static List<String> emailTemplateBodyReplaces = new List<String>{
        COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_URL_STRING,
        COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_SITEURL_STRING,
        COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_CASE_RECORD_TO_ENCRYPT_STRING,
        COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_TOKEN_TO_ENCRYPT_STRING
    };

    @InvocableMethod(
        label='Send Email Without associating Related Record'
        description='Action to send email without associating a Related Record to another. Used when the need to send email to a email address that doesn\'t exist in Salesforce as a Contact Record or to a User Record where the template requires a related record that isn\'t available for use on the standard send email.'
    )
    public static void sendEmailWithoutRecipientId(List<InputWrapper> inputList) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (InputWrapper inputWrapper : inputList) {
            //Generate Email from Template
            Messaging.SingleEmailMessage mailFromTemplate = Messaging.renderStoredEmailTemplate(inputWrapper.templateId, null, inputWrapper.whatId);
            Boolean saveAsActivity = inputWrapper.saveAsActivity != null ? inputWrapper.saveAsActivity : false;

            if (inputWrapper.recipientEmail == null && inputWrapper.targetId != null) {
                emailsToSend.add(
                    createEmail(
                        mailFromTemplate,
                        inputWrapper.templateId,
                        inputWrapper.targetId,
                        inputWrapper.whatId,
                        inputWrapper.orgWideId,
                        null,
                        saveAsActivity
                    )
                );
            } else if (inputWrapper.recipientEmail != null) {
                for (String recipientEmail : inputWrapper.recipientEmail) {
                    //Generate Email to send from Email generated from Template (to avoid having to associate it with a recipient record)
                    emailsToSend.add(
                        createEmail(
                            mailFromTemplate,
                            inputWrapper.templateId,
                            inputWrapper.targetId,
                            inputWrapper.whatId,
                            inputWrapper.orgWideId,
                            recipientEmail,
                            saveAsActivity
                        )
                    );
                }
            }
        }

        Messaging.sendEmail(emailsToSend, true);
    }

    public static Messaging.SingleEmailMessage createEmail(
        Messaging.SingleEmailMessage mailFromTemplate,
        String templateId,
        String targetId,
        String whatId,
        String orgWideId,
        String recipientEmail,
        Boolean saveAsActivity
    ) {
        Messaging.SingleEmailMessage mailToSend = new Messaging.SingleEmailMessage();
        mailToSend.setPlainTextBody(mailFromTemplate.getPlainTextBody());
        Boolean hasReplacebleValues = false;
        //Verify if Email has HTML Body. If not replace with Plain Text Body.
        String htmlBody = mailFromTemplate.getHtmlBody() != null ? mailFromTemplate.getHtmlBody() : mailFromTemplate.getPlainTextBody();
        for (String replaceString : emailTemplateBodyReplaces) {
            if (htmlBody.contains(replaceString)) {
                hasReplacebleValues = true;
                break;
            }
        }
        if (hasReplacebleValues) {
            if (htmlBody.contains(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_URL_STRING)) {
                htmlBody = htmlBody.replace(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_URL_STRING, URL.getOrgDomainURL().toExternalForm());
            }
            if (htmlBody.contains(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_SITEURL_STRING)) {
                htmlBody = htmlBody.replace(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_SITEURL_STRING, COMM_GEN_Utility.getSubscriptionPortalUrl());
            }
            if (htmlBody.contains(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_TOKEN_TO_ENCRYPT_STRING)) {
                htmlBody = htmlBody.replace(
                    COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_TOKEN_TO_ENCRYPT_STRING,
                    COMM_GEN_Utility.encryptRecordIdentifier('token', COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME)
                );
            }
            if (htmlBody.contains(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_CASE_RECORD_TO_ENCRYPT_STRING)) {
                htmlBody = htmlBody.replace(
                    COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_CASE_RECORD_TO_ENCRYPT_STRING,
                    COMM_GEN_Utility.encryptRecordIdentifier(whatId, COMM_GEN_Utility.SUBSCRIPTION_KEY_NAME)
                );
            }
        }
        mailToSend.setHtmlBody(htmlBody);
        mailToSend.setSubject(mailFromTemplate.getSubject());
        //Send Email to Address. If empty, sent to User Record.
        if (String.isNotBlank(recipientEmail)) {
            mailToSend.setToAddresses(new List<String>{ recipientEmail });
        } else {
            mailToSend.setTargetObjectId(targetId);
        }
        if (String.isNotBlank(orgWideId)) {
            //Send Email with Default No-Reply Org Wide Address if it was provided
            mailToSend.setOrgWideEmailAddressId(orgWideId);
        }
        if (String.isNotBlank(whatId)) {
            mailToSend.setWhatId(whatId);
        }
        mailToSend.setSaveAsActivity(saveAsActivity);
        mailToSend.setUseSignature(false);

        return mailToSend;
    }
}