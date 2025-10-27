/**
 * @author Daniel Lascas
 * @description COMM_SubscriptionManagementMapping__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/06/2024       Original version
 **/
public inherited sharing class COMM_DO_SubscriptionManagementMapping implements COMM_IDO_SubscriptionManagementMapping {
    private final Map<String, String> subManagementMap;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_SubscriptionManagementMapping() {
        subManagementMap = buildByFieldMap();
    }

    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @return Map updated with the values from SObject according to metadata
     **/
    public Map<String, Object> mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap) {
        for (String fieldName : subManagementMap.keySet()) {
            String jsonFieldName = subManagementMap.get(fieldName);
            //Verify if mapped field is a Parent Field (ex: Account.Name)
            if (fieldName.contains('.')) {
                String[] fieldWithParent = fieldName.split('\\.');
                SObject parentSObj = sobjRecord?.getSObject(fieldWithParent[0]);
                jsonMap.put(jsonFieldName, parentSObj?.get(fieldWithParent[1]));
            } else {
                jsonMap.put(jsonFieldName, sobjRecord?.get(fieldName));
            }
        }
        return jsonMap;
    }

    /**
     * @description Method to create a Map where Key= Field API Name
     * Value= Field Name in JSON
     *
     * @return Map of Metadata where Key is the API Name of the Salesforce Field the mapping is set to
     **/
    private Map<String, String> buildByFieldMap() {
        Map<String, String> mappingMap = new Map<String, String>();
        for (COMM_SubscriptionManagementMapping__mdt mdtValue : COMM_SubscriptionManagementMapping__mdt.getAll().values()) {
            mappingMap.put(String.valueOf(mdtValue.COMM_FieldApiName__c), String.valueOf(mdtValue.COMM_JsonFieldName__c));
        }
        return mappingMap;
    }
}