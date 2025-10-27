/**
 * @author           Diogo Gonçalves
 * @description      Service class to send order cancellation email
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    05/09/2024     Original version
 **/
public inherited sharing class COMM_SL_OrderCancellationEmail {
    private static final String CANCELLATION_EMAIL_TEMPLATE = 'COMM_OMS_OrderCancellation';
    private static final String ORDER_REFERENCE_NUMBER = '###OrderReferenceNumber###';
    private static final String FIRST_NAME = '###FirstName###';
    private static final String CANCEL_AMOUNT = '###CancelAmount###';

    /**
     * @description: method to send an order cancellation email
     * @param {list<String>} creditMemoIds
     */
    @InvocableMethod(category='OMS' label='Send Order Cancellation Email' description='Send Order Cancellation Email')
    public static void sendEmail(List<Id> orderSummaryIds) {
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();

        List<OrderSummary> orderSummaries = orderSummaryRep.getByIds(orderSummaryIds);

        List<Messaging.SingleEmailMessage> emailMessages = getCancellationSingleEmailMessages(orderSummaries);
        Messaging.sendEmail(emailMessages, false);
    }

    /**
     * @description Get the SingleEmailMessage for each OrderSummary record
     * @param {list<OrderSummary>} orderSummaries
     * @return {list<Messaging.SingleEmailMessage>}
     */
    private static List<Messaging.SingleEmailMessage> getCancellationSingleEmailMessages(List<OrderSummary> orderSummaries) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<Id, EmailTemplate> orderSummaryToTemplateMap = getOrderSummaryToLanguageTemplateMap(orderSummaries, CANCELLATION_EMAIL_TEMPLATE);
        for (OrderSummary orderSummary : orderSummaries) {
            EmailTemplate template = orderSummaryToTemplateMap.get(orderSummary.Id);
            if (template == null) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //replace placeholders on the EmailTemplate Html Body
            String htmlBody = template.HtmlValue
                .replace(ORDER_REFERENCE_NUMBER, orderSummary.orderNumber)
                .replace(FIRST_NAME, orderSummary.Account.Name)
                .replace(CANCEL_AMOUNT, String.valueOf(orderSummary.OriginalOrder?.GrandTotalAmount));
            mail.setWhatId(orderSummary.Id);
            mail.setTargetObjectId(
                (!String.isEmpty(orderSummary.BillToContactId) ? orderSummary.BillToContactId : orderSummary.Account.PersonContactId)
            );
            mail.setTemplateId(template.Id);
            mail.setSubject(template.Subject);
            mail.setToAddresses(new List<String>{ orderSummary.OrderDeliveryGroupSummaries[0].EmailAddress });
            mail.setHtmlBody(htmlBody);
            emailMessages.add(mail);
        }
        return emailMessages;
    }

    /**
     * @description Maps the ordersummaries to the email template to be used with it.
     *              There are multiple versions of the template depending on the language,
     *              this method gets the correct one for the order summary language.
     * @param {list<OrderSummary>}
     * @return {Map<Id, Id>}
     */
    private static Map<Id, EmailTemplate> getOrderSummaryToLanguageTemplateMap(List<OrderSummary> orderSummaries, String templateName) {
        Map<Id, EmailTemplate> templateIdsByOrderId = new Map<Id, EmailTemplate>();
        COMM_IREP_EmailTemplate emailRep = new COMM_REP_EmailTemplate();
        List<EmailTemplate> emailTemplates = emailRep.getEmailTemplateLanguageVersions(templateName);
        Map<String, EmailTemplate> templateIdsByLanguage = getTemplatesByLanguage(emailTemplates, CANCELLATION_EMAIL_TEMPLATE);

        for (OrderSummary os : orderSummaries) {
            String language = os.COMM_Language__c;
            EmailTemplate template = templateIdsByLanguage.get(language);
            templateIdsByOrderId.put(os.Id, template);
        }

        return templateIdsByOrderId;
    }

    /**
     * @description Gets the email templates mapped by language
     * @param {list<EmailTemplate>} emailTemplates
     * @return {Map<String, EmailTemplate>}
     */
    private static Map<String, EmailTemplate> getTemplatesByLanguage(List<EmailTemplate> emailTemplates, String templateName) {
        Map<String, EmailTemplate> templatesByLanguage = new Map<String, EmailTemplate>();
        for (EmailTemplate template : emailTemplates) {
            //Get language from template name suffix
            String language = template.DeveloperName.removeStart(templateName).substring(1);
            templatesByLanguage.put(language, template);
        }
        return templatesByLanguage;
    }
}