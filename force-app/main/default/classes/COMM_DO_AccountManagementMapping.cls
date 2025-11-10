/**
 * @author Daniel Lascas
 * @description COMM_AccountManagementMapping__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/03/2024       ECOMM-142 - Original version
 **/
public inherited sharing class COMM_DO_AccountManagementMapping implements COMM_IDO_AccountManagementMapping {
    private final Map<String, List<COMM_AccountManagementMapping__mdt>> accountManagementMap;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_AccountManagementMapping() {
        accountManagementMap = buildBySObjectMap();
    }

    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map to send
     * to the front-end of the Account Management.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to the front-end
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    public void mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean isB2C) {
        String sobjectName = String.valueOf(sobjRecord.getSObjectType());
        for (COMM_AccountManagementMapping__mdt mtdValue : accountManagementMap.get(sobjectName)) {
            if (Boolean.valueOf(mtdValue.COMM_IsB2CMapping__c) == isB2C) {
                jsonMap.put(mtdValue.COMM_Field__c, sobjRecord.get(mtdValue.COMM_FieldApiName__c));
            }
        }
    }

    /**
     * @description Method to map the values from the Account Management JSON obtained from front-end
     * into a Salesforce SObject.
     *
     * @param jsonMap JSON converted into a Map to be converted into a Salesforce SObject
     * @param sobjRecord The Salesforce SObject where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    public void mapSObjectFromJson(Map<String, Object> jsonMap, SObject sobjRecord, Boolean isB2C) {
        String sobjectName = String.valueOf(sobjRecord.getSObjectType());
        for (COMM_AccountManagementMapping__mdt mtdValue : accountManagementMap.get(sobjectName)) {
            if (Boolean.valueOf(mtdValue.COMM_IsB2CMapping__c) == isB2C && jsonMap.containsKey(mtdValue.COMM_Field__c)) {
                sobjRecord.put(mtdValue.COMM_FieldApiName__c, jsonMap.get(mtdValue.COMM_Field__c));
            }
        }
    }

    /**
     * @description Method to create a Map where Key= SObject API Name
     * Value= COMM_AccountManagementMapping__mdt metadata record
     *
     * @return Map of Metadata where Key is the API Name of the SObject the mapping is set to
     **/
    private Map<String, List<COMM_AccountManagementMapping__mdt>> buildBySObjectMap() {
        Map<String, List<COMM_AccountManagementMapping__mdt>> mappingMap = new Map<String, List<COMM_AccountManagementMapping__mdt>>();
        for (COMM_AccountManagementMapping__mdt mdtValue : COMM_AccountManagementMapping__mdt.getAll().values()) {
            String sobjectName = String.valueOf(mdtValue.COMM_SObjectApiName__c);
            if (!mappingMap.containsKey(sobjectName)) {
                mappingMap.put(sobjectName, new List<COMM_AccountManagementMapping__mdt>());
            }
            mappingMap.get(sobjectName).add(mdtValue);
        }
        return mappingMap;
    }
}