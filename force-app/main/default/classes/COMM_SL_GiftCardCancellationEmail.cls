/**
 * @author           Diogo Gonçalves
 * @description      Service class to send Gift Card order Cancellation
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    30/04/2024     Original version
 **/
public inherited sharing class COMM_SL_GiftCardCancellationEmail {
    private static final String GIFT_CARD_CANCELLATION_TEMPLATE = 'COMM_OMS_GiftCardCancellation';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static final String ORDER_REFERENCE_NUMBER = '###OrderReferenceNumber###';
    private static final String FIRST_NAME = '###FirstName###';

    /**
     * @description: method to send an email with Gift Card order cancellation
     * @param {list<String>} creditMemoIds
     */
    @InvocableMethod(category='OMS' label='Send Gift Card Cancellation Email' description='Send Gift Card Cancellation Email')
    public static void sendEmail(List<String> creditMemoIds) {
        COMM_IREP_CreditMemo creditMemoRep = new COMM_REP_CreditMemo();

        List<CreditMemo> creditMemos = creditMemoRep.getByIds(creditMemoIds);
        List<OrderSummary> orderSummaries = getOrderSummaries(creditMemos);

        List<Messaging.SingleEmailMessage> emailMessages = getCancellationSingleEmailMessages(orderSummaries);
        Messaging.sendEmail(emailMessages, false);
    }

    /**
     * @description Get the OrderSummary records of every creditMemo on the list
     * @param {list<CreditMemo>} creditMemos
     * @return {list<OrderSummary>}
     */
    private static List<OrderSummary> getOrderSummaries(List<CreditMemo> creditMemos) {
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();

        //The field ReferenceEntityId can be of various SObjectTypes, we only want OrderSummary
        List<String> referencedEntityIds = COMM_GEN_Utility.getTextFieldValues(creditMemos, 'ReferenceEntityId');
        List<String> orderSummaryIds = COMM_GEN_Utility.getIdsOfGivenSObjectType(referencedEntityIds, Schema.OrderSummary.SObjectType);
        return orderSummaryRep.getByIds(orderSummaryIds);
    }

    /**
     * @description Get the SingleEmailMessage for each OrderSummary record
     * @param {list<OrderSummary>} orderSummaries
     * @return {list<Messaging.SingleEmailMessage>}
     */
    private static List<Messaging.SingleEmailMessage> getCancellationSingleEmailMessages(List<OrderSummary> orderSummaries) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<Id, EmailTemplate> orderSummaryToTemplateMap = getOrderSummaryToTemplateMap(orderSummaries, GIFT_CARD_CANCELLATION_TEMPLATE);
        for (OrderSummary orderSummary : orderSummaries) {
            EmailTemplate template = orderSummaryToTemplateMap.get(orderSummary.Id);
            if (template == null) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //replace placeholders on the EmailTemplate Html Body
            String htmlBody = template.HtmlValue
                .replace(ORDER_REFERENCE_NUMBER, orderSummary.orderNumber)
                .replace(FIRST_NAME, orderSummary.Account.PersonContact.Name);
            mail.setWhatId(orderSummary.Id);
            mail.setTargetObjectId(
                (!String.isEmpty(orderSummary.BillToContactId) ? orderSummary.BillToContactId : orderSummary.Account.PersonContactId)
            );
            mail.setTemplateId(template.Id);
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
    private static Map<Id, EmailTemplate> getOrderSummaryToTemplateMap(List<OrderSummary> orderSummaries, String templateName) {
        Map<Id, EmailTemplate> templateIdsByOrderId = new Map<Id, EmailTemplate>();
        COMM_IREP_EmailTemplate emailRep = new COMM_REP_EmailTemplate();
        List<EmailTemplate> emailTemplates = emailRep.getEmailTemplateLanguageVersions(templateName);
        Map<String, EmailTemplate> templateIdsByLanguage = getTemplatesByLanguage(emailTemplates, GIFT_CARD_CANCELLATION_TEMPLATE);

        for (OrderSummary os : orderSummaries) {
            String language = String.isNotBlank(os.COMM_Language__c) ? os.COMM_Language__c : DEFAULT_LANGUAGE;
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