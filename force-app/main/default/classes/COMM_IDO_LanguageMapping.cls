/**
 * @author Daniel Lascas
 * @description COMM_LanguageMapping__mdt Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024       Original version
 **/
public interface COMM_IDO_LanguageMapping {
    /**
     * @description Method to retrieve the mapped language.
     *
     * @param commerceLanguage The Language Code from Commerce
     * @returns The language code used in Salesforce. If it doesn't exist then return commerce.
     **/
    String getSalesforceLanguage(String commerceLanguage);
}