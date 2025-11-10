/**
 * @author Daniel Lascas
 * @description COMM_LanguageMapping__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024       Original version
 **/
public inherited sharing class COMM_DO_LanguageMapping implements COMM_IDO_LanguageMapping {
    private final Map<String, String> commerceToSalesforceLanguageMap;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_LanguageMapping() {
        commerceToSalesforceLanguageMap = buildLanguageMap();
    }

    /**
     * @description Method to retrieve the mapped language.
     *
     * @param commerceLanguage The Language Code from Commerce
     * @returns The language code used in Salesforce. If it doesn't exist then return commerce.
     **/
    public String getSalesforceLanguage(String commerceLanguage) {
        return commerceToSalesforceLanguageMap.containsKey(commerceLanguage)
            ? commerceToSalesforceLanguageMap.get(commerceLanguage)
            : commerceLanguage;
    }

    /**
     * @description Method to create a Map where Key = Language Code in Commerce
     * Value = Language Code in Salesforce
     *
     * @return Map with mapping of language in Commerce/Salesforce
     **/
    private Map<String, String> buildLanguageMap() {
        Map<String, String> languageMap = new Map<String, String>();
        for (COMM_LanguageMapping__mdt mdtValue : COMM_LanguageMapping__mdt.getAll().values()) {
            languageMap.put(mdtValue.COMM_ValueInCommerce__c, mdtValue.COMM_ValueInSalesforce__c);
        }
        return languageMap;
    }
}