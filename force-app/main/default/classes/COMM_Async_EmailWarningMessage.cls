/**
 * @author Daniel Reto
 * @description Batch class to send one email for each Client when a Subscription is going to expire in X Days
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      23/04/2024      ECOMM-247: Original version
 **/
public with sharing class COMM_Async_EmailWarningMessage extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_DAYS_BEFORE_END_OF_MONTH = 'DaysBeforeEndOfMonth'; // 15
    @TestVisible
    private final static string PARAMETER_EMAIL_TEMPLATE_EN = 'EnglishEmailTemplate'; //COMM_EndUser_SubscriptionRenewalWarning_en_US
    @TestVisible
    private final static string PARAMETER_RECORD_TYPE = 'RecordType'; // COMM_Partner

    private final static string defaultLanguage = 'en_US';

    private COMM_IREP_EmailTemplate emailTemplateRep;
    private COMM_IREP_User userRep;
    private COMM_IREP_OrgWideEmailAddress orgWideAddressNoReply;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_EmailWarningMessage() {
        this.emailTemplateRep = new COMM_REP_EmailTemplate();
        this.userRep = new COMM_REP_User();
        this.orgWideAddressNoReply = new COMM_REP_OrgWideEmailAddress();
    }

    @testVisible
    private COMM_Async_EmailWarningMessage(
        COMM_IREP_EmailTemplate emailTemplateRep,
        COMM_IREP_User userRep,
        COMM_IREP_OrgWideEmailAddress orgWideAddressNoReply,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.emailTemplateRep = emailTemplateRep;
        this.userRep = userRep;
        this.orgWideAddressNoReply = orgWideAddressNoReply;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field is set in the past.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        Date dateToExecute = Date.today().addDays(Integer.valueOf(getParameterValue(PARAMETER_DAYS_BEFORE_END_OF_MONTH)));

        FW_QueryBuilder query = new FW_QueryBuilder(Contact.SObjectType)
            .selectFields(new List<String>{ 'Id' })
            .selectSubquery('Subscriptions__r', COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .getParent()
            .setWhere(
                'Id IN (SELECT COMM_Contact__c from COMM_Subscription__c WHERE COMM_Active__c = true AND COMM_Status__c = \'' +
                    COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED +
                    '\' AND COMM_EndDate__c <= ' +
                    String.valueOf(dateToExecute).left(10) +
                    ' AND COMM_EndDate__c >= ' +
                    String.valueOf(Date.today()).left(10) +
                    ' AND RecordType.DeveloperName = \'' +
                    getParameterValue(PARAMETER_RECORD_TYPE) +
                    '\')'
            );

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the records active field to false that were obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param contactWithRelatedSubscriptionList List of Partner Contacts with Related Subscriptions which will be renewed
     */
    public void execute(Database.BatchableContext bc, List<Contact> contactWithRelatedSubscriptionList) {
        List<COMM_Subscription__c> subscriptionList = new List<COMM_Subscription__c>();
        Set<Id> ownerIds = new Set<Id>();
        Date dateToExecute = Date.today().addDays(Integer.valueOf(getParameterValue(PARAMETER_DAYS_BEFORE_END_OF_MONTH)));

        for (Contact contactRecord : contactWithRelatedSubscriptionList) {
            for (COMM_Subscription__c subscriptionRecord : contactRecord.Subscriptions__r) {
                if (
                    subscriptionRecord.COMM_Active__c &&
                    subscriptionRecord.COMM_Status__c == COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED &&
                    subscriptionRecord.COMM_EndDate__c <= dateToExecute &&
                    subscriptionRecord.COMM_EndDate__c >= Date.today()
                ) {
                    subscriptionList.add(subscriptionRecord);
                    ownerIds.add(subscriptionRecord.OwnerId);
                }
            }
        }

        Map<Id, User> userByOwnerIdMap = new Map<Id, User>(userRep.getUsersById(ownerIds));

        Map<String, List<COMM_Subscription__c>> subscriptionListClientEmailMap = new Map<String, List<COMM_Subscription__c>>();
        Map<String, String> languageByClientEmailMap = new Map<String, String>();
        List<Messaging.SingleEmailMessage> emailsToSendList = new List<Messaging.SingleEmailMessage>();

        for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
            if (userByOwnerIdMap.get(subscriptionRecord.OwnerId).Email != null) {
                languageByClientEmailMap.put(userByOwnerIdMap.get(subscriptionRecord.OwnerId).Email, userByOwnerIdMap.get(subscriptionRecord.OwnerId).LanguageLocaleKey);
                if (subscriptionListClientEmailMap.containsKey(userByOwnerIdMap.get(subscriptionRecord.OwnerId).Email)) {
                    subscriptionListClientEmailMap.get(userByOwnerIdMap.get(subscriptionRecord.OwnerId).Email).add(subscriptionRecord);
                } else {
                    subscriptionListClientEmailMap.put(userByOwnerIdMap.get(subscriptionRecord.OwnerId).Email, new List<COMM_Subscription__c>{ subscriptionRecord });
                }
            }
        }

        String experiencrSiteUrl = COMM_GEN_Utility.getSubscriptionPortalUrl();

        if (!subscriptionListClientEmailMap.isEmpty()) {
            Map<String, String> emailTemplateLabelByLanguageMap = new Map<String, String>();
            Map<String, EmailTemplate> emailTemplateByEmailTemplateLabelMap = new Map<String, EmailTemplate>();
            Id orgWideAddressNoReplyId = orgWideAddressNoReply.getDefaultNoReplyAddress()?.get(0)?.Id;

            String emailTemplateLabel = getParameterValue(PARAMETER_EMAIL_TEMPLATE_EN).removeEnd('_' + defaultLanguage);
            emailTemplateLabelByLanguageMap.put(defaultLanguage, getParameterValue(PARAMETER_EMAIL_TEMPLATE_EN));
            for (String languageValue : languageByClientEmailMap.values()) {
                emailTemplateLabelByLanguageMap.put(languageValue, emailTemplateLabel + '_' + languageValue);
            }

            List<EmailTemplate> emailTemplateAllLanguagesList = emailTemplateRep.getEmailTemplateByNames(
                new Set<String>(emailTemplateLabelByLanguageMap.values())
            );
            for (EmailTemplate emailTemplateRecord : emailTemplateAllLanguagesList) {
                emailTemplateByEmailTemplateLabelMap.put(emailTemplateRecord.Name, emailTemplateRecord);
            }

            for (String clientEmail : subscriptionListClientEmailMap.keySet()) {
                //Generate Email from Template
                Id emailTemplateId = emailTemplateLabelByLanguageMap.containsKey(languageByClientEmailMap.get(clientEmail))
                    ? emailTemplateByEmailTemplateLabelMap.get(emailTemplateLabelByLanguageMap.get(languageByClientEmailMap.get(clientEmail))).Id
                    : emailTemplateByEmailTemplateLabelMap.get(emailTemplateLabelByLanguageMap.get(defaultLanguage)).Id;
                Messaging.SingleEmailMessage emailFromTemplate = Messaging.renderStoredEmailTemplate(
                    emailTemplateId,
                    null,
                    subscriptionListClientEmailMap.get(clientEmail).get(0).Id
                );

                //Generate Email Message
                Messaging.SingleEmailMessage newEmailMessage = COMM_SL_SendEmail.createEmail(
                    emailFromTemplate,
                    emailTemplateId,
                    null,
                    subscriptionListClientEmailMap.get(clientEmail)?.get(0)?.Id,
                    orgWideAddressNoReplyId,
                    clientEmail,
                    true
                );

                emailFromTemplate.setSubject(emailFromTemplate.getSubject());
                //Send Email to Address. If empty, sent to User Record.
                emailFromTemplate.setToAddresses(new List<String>{ clientEmail });
                if (String.isNotBlank(orgWideAddressNoReplyId)) {
                    //Send Email with Default No-Reply Org Wide Address if it was provided
                    emailFromTemplate.setOrgWideEmailAddressId(orgWideAddressNoReplyId);
                }
                if (String.isNotBlank(subscriptionListClientEmailMap.get(clientEmail)?.get(0)?.Id)) {
                    emailFromTemplate.setWhatId(subscriptionListClientEmailMap.get(clientEmail)?.get(0)?.Id);
                }
                emailFromTemplate.setSaveAsActivity(true);
                emailFromTemplate.setUseSignature(false);

                //Renewal Warning Message Exception: Edit Email Message Body | Start
                String manualRenewalSubscriptionHTML = '';
                String automaticRenewalSubscriptionHTML = '';

                for (COMM_Subscription__c subscriptionRecord : subscriptionListClientEmailMap.get(clientEmail)) {
                    if (subscriptionRecord.COMM_AutomaticRenewal__c) {
                        automaticRenewalSubscriptionHTML += COMM_GEN_Utility.generateHrefSiteEmailTemplate(
                            subscriptionRecord.Id,
                            subscriptionRecord.Name,
                            experiencrSiteUrl
                        );
                    } else {
                        manualRenewalSubscriptionHTML += COMM_GEN_Utility.generateHrefSiteEmailTemplate(
                            subscriptionRecord.Id,
                            subscriptionRecord.Name,
                            experiencrSiteUrl
                        );
                    }
                }
                String htmlBody = emailFromTemplate.getHtmlBody();
                if (String.isNotBlank(manualRenewalSubscriptionHTML)) {
                    htmlBody =
                        '<ul>' +
                        htmlBody.replace(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_MANUAL_RENEWAL_LIST, manualRenewalSubscriptionHTML) +
                        '</ul>';
                    htmlBody = htmlBody.remove(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_MANUAL_RENEWAL_LIST_BLOCK);
                } else {
                    List<String> htmlBodySplit = htmlBody.split(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_MANUAL_RENEWAL_LIST_BLOCK);
                    htmlBody = htmlBodySplit[0] + htmlBodySplit[2];
                }
                if (String.isNotBlank(automaticRenewalSubscriptionHTML)) {
                    htmlBody =
                        '<ul>' +
                        htmlBody.replace(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_AUTOMATIC_RENEWAL_LIST, automaticRenewalSubscriptionHTML) +
                        '</ul>';
                    htmlBody = htmlBody.remove(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_AUTOMATIC_RENEWAL_LIST_BLOCK);
                } else {
                    List<String> htmlBodySplit = htmlBody.split(COMM_DO_Email.EMAIL_TEMPLATE_REPLACE_AUTOMATIC_RENEWAL_LIST_BLOCK);
                    htmlBody = htmlBodySplit[0] + htmlBodySplit[2];
                }
                emailFromTemplate.setHtmlBody(htmlBody);
                //Renewal Warning Message Exception: Edit Email Message Body | End

                emailsToSendList.add(emailFromTemplate);
            }
        }

        if (!emailsToSendList.isEmpty()) {
            Messaging.sendEmail(emailsToSendList, true);
        }
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}