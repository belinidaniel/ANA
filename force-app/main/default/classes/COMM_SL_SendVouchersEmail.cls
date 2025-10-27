/**
 * @author           Diogo Gonçalves
 * @description      Service class to send Voucher Reservations
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    08/04/2024     ECOMM-105: Original version
 * Diogo Gonçalves    10/05/2024     ECOMM-105: Error handling and create Process Exceptions
 * Jose Passos        05/07/2024     ECOMM-1639: Fix Missing targetObjectId
 * Miguel Justo       08/01/2025     ECOMM-2437: Force Sender Email to be the No Reply Configured
 **/

public inherited sharing class COMM_SL_SendVouchersEmail {
    private static final String RESERVATION_CONFIRMATION_TEMPLATE = 'COMM_OMS_ReservationConfirmation';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static final String PROCESS_EXCEPTION_MESSAGE = 'Error sending email with vouchers';
    public static final String VOUCHER_NO_TEMPLATE_MESSAGE = 'No email template found';
    private static final FW_ISObjectRep SOBJECT_REPO = new FW_SObjectRep();

    /**
     * @description: method to send an email with the reservation vouchers,
     * @param {list<String>} invoiceIds
     */
    @InvocableMethod(category='OMS' label='Send Reservation Vouchers' description='Send Email with the reservation voucher')
    public static void sendVouchers(List<String> invoiceIds) {
        COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();

        List<Invoice> invoices = invoiceRep.getByIds(invoiceIds);
        List<OrderSummary> orderSummaries = getOrderSummaries(invoices);
        List<Messaging.SingleEmailMessage> emailMessages;
        try {
            emailMessages = getVoucherSingleEmailMessages(orderSummaries);
        } catch (Exception e) {
            createProcessExceptions(e, orderSummaries);
        }

        if (emailMessages != null) {
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(emailMessages, false);
            handleSendEmailResults(emailMessages, emailResults);
        }
    }

    /**
     * @description Get the OrderSummary records of every invoice on the list
     * @param {list<Invoice>} invoices
     * @return {list<OrderSummary>}
     */
    private static List<OrderSummary> getOrderSummaries(List<Invoice> invoices) {
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();

        //The field ReferenceEntityId can be of various SObjectTypes, we only want OrderSummary
        List<String> referencedEntityIds = COMM_GEN_Utility.getTextFieldValues(invoices, 'ReferenceEntityId');
        List<String> orderSummaryIds = COMM_GEN_Utility.getIdsOfGivenSObjectType(referencedEntityIds, Schema.OrderSummary.SObjectType);
        return orderSummaryRep.getByIds(orderSummaryIds);
    }

    /**
     * @description Get the SingleEmailMessage with the PDF attached for each OrderSummary record
     * @param {list<OrderSummary>} orderSummaries
     * @return {list<Messaging.SingleEmailMessage>}
     */
    private static List<Messaging.SingleEmailMessage> getVoucherSingleEmailMessages(List<OrderSummary> orderSummaries) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        COMM_IREP_ReservationEmailBCCMdt bccAddressesRepo = new COMM_REP_ReservationEmailBCCMdt();
        COMM_IREP_OrgWideEmailAddress orgWideAddressRep = new COMM_REP_OrgWideEmailAddress();
        Map<Id, Id> orderSummaryToTemplateMap = getOrderSummaryToTemplateMap(orderSummaries);
        List<String> bccAddresses = bccAddressesRepo.getAllEmails();
        List<ProcessException> exceptions = new List<ProcessException>();

        //Check for Default No-Reply Email Address (to send email)
        List<OrgWideEmailAddress> orgWideAddresses = orgWideAddressRep.getDefaultNoReplyAddress();
        Id orgWideAddressId = !orgWideAddresses.isEmpty() ? orgWideAddresses[0].Id : null;

        for (OrderSummary orderSummary : orderSummaries) {
            Id templateId = orderSummaryToTemplateMap.get(orderSummary.Id);
            try {
                emailMessages.add(getVoucherSingleEmailMessage(orderSummary, templateId, bccAddresses, orgWideAddressId));
            } catch (Exception e) {
                String errorMessage = e.getMessage() + '; COMM_SL_SendVouchersEmail: line: ' + e.getLineNumber();
                exceptions.add(createProcessException(e.getMessage(), orderSummary.Id));
            }
        }

        if (!exceptions.isEmpty()) {
            SOBJECT_REPO.insertSObjects(exceptions);
        }
        return emailMessages;
    }

    /**
     * @description Get the SingleEmailMessage with the PDF attached for the given orderSummary
     * @param {OrderSummary} orderSummary
     * @param {Id} templateId
     * @param orgWideAddressId Id of the Org-Wide Email Address to be set as the sender.
     * @return {Messaging.SingleEmailMessage}
     */
    private static Messaging.SingleEmailMessage getVoucherSingleEmailMessage(
        OrderSummary orderSummary,
        Id templateId,
        List<String> bccAddresses,
        Id orgWideAddressId
    ) {
        if (templateId == null) {
            throw new COMM_SL_SendVoucherEmailException(VOUCHER_NO_TEMPLATE_MESSAGE);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment pdfAttachment = getVoucherPDFAttachment(orderSummary);
        mail.setWhatId(orderSummary.Id);
        mail.setTargetObjectId((!String.isEmpty(orderSummary.BillToContactId) ? orderSummary.BillToContactId : orderSummary.Account.PersonContactId));
        mail.setBccAddresses(bccAddresses);
        mail.setTemplateId(templateId);
        mail.setToAddresses(new List<String>{ orderSummary.OrderDeliveryGroupSummaries[0].EmailAddress });
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ pdfAttachment });
        if (String.isNotBlank(orgWideAddressId)) {
            mail.setOrgWideEmailAddressId(orgWideAddressId);
        }
        return mail;
    }

    /**
     * @description Maps the ordersummaries to the email template to be used with it.
     *              There are multiple versions of the template depending on the language,
     *              this method gets the correct one for the order summary language.
     * @param {list<OrderSummary>}
     * @return {Map<Id, Id>}
     */
    private static Map<Id, Id> getOrderSummaryToTemplateMap(List<OrderSummary> orderSummaries) {
        Map<Id, Id> templateIdsByOrderId = new Map<Id, Id>();
        COMM_IREP_EmailTemplate emailRep = new COMM_REP_EmailTemplate();
        List<EmailTemplate> emailTemplates = emailRep.getEmailTemplateLanguageVersions(RESERVATION_CONFIRMATION_TEMPLATE);
        Map<String, EmailTemplate> templateIdsByLanguage = getTemplatesByLanguage(emailTemplates);

        for (OrderSummary os : orderSummaries) {
            Id templateId = templateIdsByLanguage.get(os.COMM_Language__c)?.Id;
            templateIdsByOrderId.put(os.Id, templateId);
        }

        return templateIdsByOrderId;
    }

    /**
     * @description Gets the email templates mapped by language
     * @param {list<EmailTemplate>} emailTemplates
     * @return {Map<String, EmailTemplate>}
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
     * @description Get the EmailFileAttatchmente for a given OrderSummary Id
     * @param {Id} orderSummaryId
     * @retun {list<Messaging.EmailFileAttachment>}
     */
    public static Messaging.EmailFileAttachment getVoucherPDFAttachment(OrderSummary orderSummary) {
        PageReference pdf = Page.COMM_VFP_VoucherPDF;
        pdf.getParameters().put('id', orderSummary.Id);
        pdf.getParameters().put('lang', orderSummary.COMM_Language__c);
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

    /**
     * @description Creates a ProcessException for every Order Summary with the given exception
     * @param {Exception} e
     * @param {list<String>} orderSummaryIds
     * @return {List<ProcessException>}
     */
    private static void createProcessExceptions(Exception e, List<OrderSummary> orderSummaries) {
        String errorMessage = e.getMessage() + '; COMM_SL_SendVouchersEmail: line: ' + e.getLineNumber();
        List<ProcessException> exceptions = new List<ProcessException>();
        for (OrderSummary orderSummary : orderSummaries) {
            exceptions.add(createProcessException(errorMessage, orderSummary.Id));
        }
        SOBJECT_REPO.insertSObjects(exceptions);
    }

    /**
     * @description Create a process exception for the order summary with the given description
     * @param {string} description
     * @param {Id} orderSummaryId
     * @return {ProcessException}
     */
    private static ProcessException createProcessException(String description, Id orderSummaryId) {
        return COMM_DO_ProcessExceptions.createProcessException(
            orderSummaryId,
            orderSummaryId,
            COMM_DO_ProcessExceptions.VOUCHER_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_HIGH,
            PROCESS_EXCEPTION_MESSAGE,
            description,
            COMM_DO_ProcessExceptions.NEW_S
        );
    }

    /**
     * @description Function that checks the status of email messages sent.
     *  Creates Process Exceptions for the errors and updates the successfull ones.
     * @param {list<Messaging.SingleEmailMessage>} emailMessages Email Messages sent
     * @param {list<Messaging.SendEmailResult>} emailResults Result for each message sent
     */
    private static void handleSendEmailResults(List<Messaging.SingleEmailMessage> emailMessages, List<Messaging.SendEmailResult> emailResults) {
        List<ProcessException> processExceptions = new List<ProcessException>();
        List<String> successOrderSummaries = new List<String>();
        for (Integer i = 0; i < emailResults.size(); i++) {
            Messaging.SendEmailResult emailResult = emailResults[0];
            Messaging.SingleEmailMessage emailMessage = emailMessages[0];
            if (emailResult.isSuccess()) {
                successOrderSummaries.add(emailMessage.getWhatId());
            } else {
                processExceptions.add(createProcessException(emailResult.getErrors()[0].getMessage(), emailMessage.getWhatId()));
            }
        }

        processExceptions.addAll(
            COMM_DO_ProcessExceptions.resolveByOrderSummaries(
                COMM_DO_ProcessExceptions.VOUCHER_CATEGORY,
                successOrderSummaries,
                new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED }
            )
        );

        if (!processExceptions.isEmpty()) {
            SOBJECT_REPO.upsertSObjects(processExceptions);
        }
    }
}