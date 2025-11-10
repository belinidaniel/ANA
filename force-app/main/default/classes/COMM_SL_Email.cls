/**
 * @author Daniel Lascas
 * @description Service Layer Class that manages the Email business logic.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 **/
public without sharing class COMM_SL_Email implements COMM_ISL_Email {
    private COMM_IREP_EmailTemplate emailTemplateRep;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_SL_Email() {
        this.emailTemplateRep = new COMM_REP_EmailTemplate();
    }

    @TestVisible
    private COMM_SL_Email(COMM_IREP_EmailTemplate emailTemplateRep) {
        this.emailTemplateRep = emailTemplateRep;
    }

    /**
     * @description Method to obtain several Email Templates to be used. If template for the given language isn't found
     * then returns the default language template (English)
     *
     * @param templateNameList List of Templates to be retrieved
     * @param languageCode Language fo the Templates to be retrieved
     * @param useDeveloperName Indicadte if Template names are DeveloperName or Name
     **/
    public List<EmailTemplate> getEmailTemplates(List<String> templateNameList, String languageCode, Boolean useDeveloperName) {
        Set<String> namesToQuery = new Set<String>();
        for (String templateName : templateNameList) {
            namesToQuery.add(templateName + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE);
            namesToQuery.add(templateName + '_' + languageCode);
        }

        List<EmailTemplate> emailTemplateList = useDeveloperName
            ? emailTemplateRep.getEmailTemplateByUniqueNames(namesToQuery)
            : emailTemplateRep.getEmailTemplateByNames(namesToQuery);

        // If more than one templates is found (default english + user language) then return the user language.
        // If language isn't found then return the english template
        Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
        for (EmailTemplate templateRecord : emailTemplateList) {
            for (String templateName : templateNameList) {
                String recordName = useDeveloperName ? templateRecord.DeveloperName : templateRecord.Name;
                if (recordName.startsWith(templateName) && (recordName.contains(languageCode) || !templateMap.containsKey(recordName))) {
                    templateMap.put(templateName, templateRecord);
                    continue;
                }
            }
        }

        // Check if a template for each requested name was found. If not then throw error
        if (templateMap.size() < templateNameList.size()) {
            return null;
        }

        return templateMap.values();
    }
}