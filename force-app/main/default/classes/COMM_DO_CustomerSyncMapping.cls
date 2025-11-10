/**
 * @author Daniel Lascas
 * @description COMM_CustomerSynchronizationMapping__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    12/06/2024       Original version
 **/
public inherited sharing class COMM_DO_CustomerSyncMapping implements COMM_IDO_CustomerSyncMapping {
    private final Map<String, Map<String, COMM_CustomerSynchronizationMapping__mdt>> customerSyncMap;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_CustomerSyncMapping() {
        customerSyncMap = buildBySObjectMap();
    }

    /**
     * @description Method to obtain list of all Core fields used in synchronization
     *
     * @param sObjectType API Name of the SObject the mapping will apply
     * @param isB2C Boolean indicating that mapping applied if for a B2C client
     * @return Set with the API Name of all Core Fields used in mapping
     */
    public Set<String> getCoreFieldList(String sObjectType, Boolean isB2C) {
        return customerSyncMap.containsKey(sObjectType + isB2C) ? customerSyncMap.get(sObjectType + isB2C).keySet() : new Set<String>();
    }

    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map
     * to send to Commerce.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to Commerce
     * @param isB2C Boolean indicating that mapping applied if for a B2C client
     * @param jsonMap The JSON Map where the mapped values will be stored
     **/
    public void mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean isB2C) {
        String sobjectName = String.valueOf(sobjRecord.getSObjectType()) + isB2C;
        Map<String, COMM_CustomerSynchronizationMapping__mdt> fieldSyncMap = customerSyncMap.get(sobjectName);
        for (String salesforceField : fieldSyncMap.keySet()) {
            String commerceField = fieldSyncMap.get(salesforceField).COMM_CommerceApiFieldName__c;
            String addressField = fieldSyncMap.get(salesforceField).COMM_AddressMapping__c;
            if (String.isBlank(addressField)) {
                jsonMap.put(commerceField, sobjRecord.get(salesforceField));
            } else {
                if (!jsonMap.containsKey(addressField)) {
                    jsonMap.put(addressField, new Map<String, Object>());
                }
                ((Map<String, Object>) jsonMap.get(addressField)).put(commerceField, sobjRecord.get(salesforceField));
            }
        }
    }

    /**
     * @description Method to create a Map where Key= Core Field API Name
     * Value= (Commerce) OCAPI Field API Name
     *
     * @return Map of Metadata where Key is the API Name of the Field the mapping is set to
     **/
    private Map<String, Map<String, COMM_CustomerSynchronizationMapping__mdt>> buildBySObjectMap() {
        Map<String, Map<String, COMM_CustomerSynchronizationMapping__mdt>> mappingMap = new Map<String, Map<String, COMM_CustomerSynchronizationMapping__mdt>>();
        for (COMM_CustomerSynchronizationMapping__mdt mdtValue : COMM_CustomerSynchronizationMapping__mdt.getAll().values()) {
            String sobjectName = mdtValue.COMM_CoreApiObjectName__c + mdtValue.COMM_MappingForB2C__c;
            if (!mappingMap.containsKey(sobjectName)) {
                mappingMap.put(sobjectName, new Map<String, COMM_CustomerSynchronizationMapping__mdt>());
            }
            mappingMap.get(sobjectName).put(mdtValue.COMM_CoreApiFieldName__c, mdtValue);
        }
        return mappingMap;
    }
}