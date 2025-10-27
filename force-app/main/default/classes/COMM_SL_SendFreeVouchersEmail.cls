/**
 * @author Daniel Lascas
 * @description Service class to send Free Voucher Reservations
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024       ECOMM-2248: Original version
 **/
public inherited sharing class COMM_SL_SendFreeVouchersEmail {
    private static final String RESERVATION_CONFIRMATION_TEMPLATE = 'COMM_FreeReservationConfirm';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static final String PROCESS_EXCEPTION_MESSAGE = 'Error sending email with vouchers';
    public static final String VOUCHER_NO_TEMPLATE_MESSAGE = 'No email template found';
    private static final FW_ISObjectRep SOBJECT_REPO = new FW_SObjectRep();

    /**
     * @description Method to send an email with the reservation vouchers.
     *
     * @param freeVouchers Vouchers to be sent to customers.
     * @returns List of Result for each email sent. True if Email sent successfully, false otherwise.
     */
    @InvocableMethod(category='Free Voucher' label='Send Free Reservation Vouchers' description='Send Email with the reservation voucher')
    public static List<Boolean> sendVouchers(List<COMM_FreeVoucher__c> freeVouchers) {
        List<Boolean> wereEmailsSentList = new List<Boolean>();
        List<Messaging.SingleEmailMessage> emailMessages = getFreeVoucherSingleEmailMessages(freeVouchers);
        if (emailMessages != null) {
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(emailMessages, false);

            for (Messaging.SendEmailResult result : emailResults) {
                wereEmailsSentList.add(result.isSuccess());
            }
        }
        return wereEmailsSentList;
    }

    /**
     * @description Get the SingleEmailMessage with the PDF attached for each COMM_FreeVoucher__c record.
     *
     * @param freeVouchers List of Free Vouchers to be sent
     * @return List of Emails generated
     */
    private static List<Messaging.SingleEmailMessage> getFreeVoucherSingleEmailMessages(List<COMM_FreeVoucher__c> freeVouchers) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        COMM_IREP_ReservationEmailBCCMdt bccAddressesRepo = new COMM_REP_ReservationEmailBCCMdt();
        COMM_IREP_OrgWideEmailAddress orgWideAddressRep = new COMM_REP_OrgWideEmailAddress();
        Map<Id, Id> freeVoucherToTemplateMap = getFreeVoucherToTemplateMap(freeVouchers);

        //Check for Default No-Reply Email Address (to send email)
        List<OrgWideEmailAddress> orgWideAddresses = orgWideAddressRep.getDefaultNoReplyAddress();
        Id orgWideAddressId = !orgWideAddresses.isEmpty() ? orgWideAddresses[0].Id : null;

        List<String> bccAddresses = bccAddressesRepo.getAllEmails();
        for (COMM_FreeVoucher__c freeVoucher : freeVouchers) {
            Id templateId = freeVoucherToTemplateMap.get(freeVoucher.Id);
            emailMessages.add(getVoucherSingleEmailMessage(freeVoucher, templateId, bccAddresses, orgWideAddressId));
        }
        return emailMessages;
    }

    /**
     * @description Get the SingleEmailMessage with the PDF attached for the given FreeVoucher.
     *
     * @param freeVoucher Free Voucher Record to be sent.
     * @param templateId Id of the Email Template to be used.
     * @param bccAddresses List of Addresses to add to BCC field on emails.
     * @param orgWideAddressId Id of the Org-Wide Email Address to be set as the sender.
     * @return Instance of the SingleEmailMessage that is to be sent to client.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Messaging.SingleEmailMessage getVoucherSingleEmailMessage(
        COMM_FreeVoucher__c freeVoucher,
        Id templateId,
        List<String> bccAddresses,
        Id orgWideAddressId
    ) {
        if (templateId == null) {
            throw new COMM_SL_SendVoucherEmailException(VOUCHER_NO_TEMPLATE_MESSAGE);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment pdfAttachment = getVoucherPDFAttachment(freeVoucher);
        mail.setWhatId(freeVoucher.Id);
        mail.setTargetObjectId(freeVoucher.OwnerId);
        mail.setBccAddresses(bccAddresses);
        mail.setTemplateId(templateId);
        mail.setSaveAsActivity(false);
        mail.setToAddresses(new List<String>{ freeVoucher.COMM_Email__c });
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ pdfAttachment });
        if (String.isNotBlank(orgWideAddressId)) {
            mail.setOrgWideEmailAddressId(orgWideAddressId);
        }
        return mail;
    }

    /**
     * @description Maps the free voucher to the email template to be used with it.
     * There are multiple versions of the template depending on the language,
     * this method gets the correct one for the order summary language.
     *
     * @param freeVouchers List of Free Voucher Records.
     * @return Map of the Template Id to be used for each Free Voucher.
     */
    private static Map<Id, Id> getFreeVoucherToTemplateMap(List<COMM_FreeVoucher__c> freeVouchers) {
        Map<Id, Id> templateIdsByVoucherId = new Map<Id, Id>();
        COMM_IREP_EmailTemplate emailRep = new COMM_REP_EmailTemplate();
        List<EmailTemplate> emailTemplates = emailRep.getEmailTemplateLanguageVersions(RESERVATION_CONFIRMATION_TEMPLATE);
        Map<String, EmailTemplate> templateIdsByLanguage = getTemplatesByLanguage(emailTemplates);

        for (COMM_FreeVoucher__c fv : freeVouchers) {
            Id templateId = templateIdsByLanguage.get(fv.COMM_Language__c)?.Id;
            templateIdsByVoucherId.put(fv.Id, templateId);
        }

        return templateIdsByVoucherId;
    }

    /**
     * @description Gets the email templates mapped by language.
     *
     * @param emailTemplates List of Email Templates to filter.
     * @return Map with the Email Template by language.
     */
    private static Map<String, EmailTemplate> getTemplatesByLanguage(List<EmailTemplate> emailTemplates) {
        Map<String, EmailTemplate> templatesByLanguage = new Map<String, EmailTemplate>();
        for (EmailTemplate template : emailTemplates) {
            //Get language from template name suffix
            String language = template.DeveloperName.removeStart(RESERVATION_CONFIRMATION_TEMPLATE).substring(1);
            templatesByLanguage.put(language, template);
        }
        return templatesByLanguage;
    }

    /**
     * @description Get the EmailFileAttatchmente for a given Free Voucher Record.
     *
     * @param freeVoucher Record of the Free Voucher.
     * @retun EmailFileAttachment to be sent.
     */
    public static Messaging.EmailFileAttachment getVoucherPDFAttachment(COMM_FreeVoucher__c freeVoucher) {
        PageReference pdf = Page.COMM_VFP_FreeVoucherPDF;
        pdf.getParameters().put('id', freeVoucher.Id);
        pdf.getParameters().put('lang', freeVoucher.COMM_Language__c);
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test');
        } else {
            pdfBlob = pdf.getContentAsPdf();
        }

        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setContentType('application/pdf');
        efa.setFileName('Reservation Vouchers.pdf');
        efa.setBody(pdfBlob);
        efa.setInline(false);
        return efa;
    }
}