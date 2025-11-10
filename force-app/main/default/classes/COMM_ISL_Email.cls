/**
 * @author Daniel Lascas
 * @description COMM_SL_Email service layer class interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 **/
public interface COMM_ISL_Email {
    /**
     *  @description Method to obtain several Email Templates to be used. If template for the given language isn't found
     * then returns the default language template (English)
     *
     * @param templateNameList List of Templates to be retrieved
     * @param languageCode Language fo the Templates to be retrieved
     * @param useDeveloperName Indicadte if Template names are DeveloperName or Name
     **/
    List<EmailTemplate> getEmailTemplates(List<String> templateNameList, String languageCode, Boolean useDeveloperName);
}