/**
 * @author Daniel Lascas
 * @description Email Template repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 * Diogo Gonçalves  11/04/2024       ECOMM-243: E-mail Reservation Confirmation
 **/
public inherited sharing class COMM_REP_EmailTemplate extends FW_SobjectRep implements COMM_IREP_EmailTemplate {
    /**
     * @description Retrieve a list of active Email Templates that have specific Developer Names
     *
     * @param names Set of Names to query Email Templates
     * @return List of Email Templates found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<EmailTemplate> getEmailTemplateByUniqueNames(Set<String> uniqueNames) {
        return [
            SELECT Id, Name, DeveloperName, Subject, Body
            FROM EmailTemplate
            WHERE DeveloperName IN :uniqueNames AND IsActive = TRUE
            ORDER BY Name ASC
        ];
    }

    /**
     * @description Retrieve a list of active Email Templates that have specific Names
     *
     * @param names Set of Names to query Email Templates
     * @return List of Email Templates found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<EmailTemplate> getEmailTemplateByNames(Set<String> names) {
        return [
            SELECT Id, Name, DeveloperName, Subject, Body
            FROM EmailTemplate
            WHERE Name IN :names AND IsActive = TRUE
            ORDER BY Name ASC
        ];
    }

    /**
     * @description Retrieve a list of active Email Templates that have specific Names
     *
     * @param names Set of Names to query Email Templates
     * @return List of Email Templates found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Network> getEmailTemplateNetworkSite() {
        return [
            SELECT Id
            FROM Network
            LIMIT 1
        ];
    }

    /**
     * @description Retrieve a list of Networks by a set of Names
     *
     * @param networkName Name of the Network being queried
     * @return List of Email Templates found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Network> getNetworkSiteByName(Set<String> networkName) {
        return [
            SELECT Id
            FROM Network
            WHERE Name IN :networkName
        ];
    }

    /**
     * @description Retrieve language versions for an email template name.
     * @param templateNameWithoutLang Template name without language
     * @return  List of email templates for every language that
     *          is available for the given template name.
     */
    public List<EmailTemplate> getEmailTemplateLanguageVersions(String nameWithoutLang) {
        String nameToQuery = nameWithoutLang + '%';
        return [
            SELECT Id, Name, DeveloperName, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName LIKE :nameToQuery AND IsActive = TRUE
            WITH USER_MODE
            ORDER BY Name ASC
        ];
    }
}