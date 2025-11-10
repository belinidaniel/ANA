/**
 * @author Daniel Lascas
 * @description COMM_SAPMapping__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/03/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_DO_SAPMapping implements COMM_IDO_SAPMapping {
    private final Map<String, List<COMM_SAPMapping__mdt>> sapMap;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_SAPMapping() {
        sapMap = buildBySObjectMap();
    }

    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map to send
     * to SAP
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to SAP
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @param additionalProduct Boolean to indicate if mapping is done for additional product (ex: Card in Subscription Invoice)
     * @return Map updated with the values from SObject according to metadata
     **/
    public Map<String, Object> mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean additionalProduct) {
        String sobjectName = String.valueOf(sobjRecord.getSObjectType());
        for (COMM_SAPMapping__mdt mtdValue : sapMap.get(sobjectName)) {
            if (additionalProduct == mtdValue.COMM_AdditionalProduct__c) {
                String fieldName = mtdValue.COMM_FieldApiName__c;
                //Verify if mapped field is a Parent Field (ex: Account.Name)
                if (fieldName.contains('.')) {
                    String[] fieldWithParent = fieldName.split('\\.');
                    SObject parentSObj = sobjRecord.getSObject(fieldWithParent[0]);
                    if (parentSObj != null) {
                        jsonMap.put(mtdValue.COMM_Field__c, parentSObj.get(fieldWithParent[1]));
                    }
                } else if (String.isNotBlank(String.valueOf(sobjRecord.get(mtdValue.COMM_FieldApiName__c)))) {
                    jsonMap.put(mtdValue.COMM_Field__c, sobjRecord.get(mtdValue.COMM_FieldApiName__c));
                }
            }
        }
        return jsonMap;
    }

    /**
     * @description Method to create a Map where Key= SObject API Name
     * Value= COMM_SAPMapping__mdt metadata record
     *
     * @return Map of Metadata where Key is the API Name of the SObject the mapping is set to
     **/
    private Map<String, List<COMM_SAPMapping__mdt>> buildBySObjectMap() {
        Map<String, List<COMM_SAPMapping__mdt>> mappingMap = new Map<String, List<COMM_SAPMapping__mdt>>();
        for (COMM_SAPMapping__mdt mdtValue : COMM_SAPMapping__mdt.getAll().values()) {
            String sobjectName = String.valueOf(mdtValue.COMM_SObjectApiName__c);
            if (!mappingMap.containsKey(sobjectName)) {
                mappingMap.put(sobjectName, new List<COMM_SAPMapping__mdt>());
            }
            mappingMap.get(sobjectName).add(mdtValue);
        }
        return mappingMap;
    }
}