/**
 * @author Daniel Lascas
 * @description Email Template repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 * Diogo Gonçalves  11/04/2024       ECOMM-243: E-mail Reservation Confirmation
 **/
public interface COMM_IREP_EmailTemplate extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of active Email Templates that have specific Developer Names
     * @example SELECT Id, Name, DeveloperName, Subject, Body FROM EmailTemplate WHERE
     * DeveloperName IN :names AND IsActive = TRUE ORDER BY Name ASC
     *
     * @param names Set of Names to query Email Templates
     * @return List of Email Templates found
     **/
    List<EmailTemplate> getEmailTemplateByUniqueNames(Set<String> uniqueNames);
    /**
     * @description Retrieve a list of active Email Templates that have specific Names
     * @example SELECT Id, Name, DeveloperName, Subject, Body FROM EmailTemplate WHERE
     * Name IN :names AND IsActive = TRUE ORDER BY Name ASC
     *
     * @param names Set of Names to query Email Templates
     * @return List of Email Templates found
     **/
    List<EmailTemplate> getEmailTemplateByNames(Set<String> names);
    /**
     * @description Retrieve a list with a unique Community Id to use on Email Templates
     * @example SELECT Id FROM Network
     *
     * @return List of Network found
     **/
    List<Network> getEmailTemplateNetworkSite();
    /**
     * @description Retrieve a list of Networks by a set of Names
     *
     * @param networkName Name of the Network being queried
     * @return List of Email Templates found
     **/
    List<Network> getNetworkSiteByName(Set<String> networkName);
    /**
     * @description Retrieve language versions for an email template name.
     * @param nameWithoutLang Template name without language
     * @return List of email templates for every language that is available for the template name.
     */
    List<EmailTemplate> getEmailTemplateLanguageVersions(String nameWithoutLang);
}