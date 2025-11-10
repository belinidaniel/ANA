/**
 * @author Daniel Lascas
 * @description COMM_ProductSynchronizationFieldConvert__mdt Custom Metadata
 * Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/04/2024       ECOMM-808: Original version
 **/
public inherited sharing class COMM_DO_ProductSyncFieldConvert implements COMM_IDO_ProductSyncFieldConvert {
    private final Map<String, Map<String, String>> conversionMap;

    public COMM_DO_ProductSyncFieldConvert() {
        conversionMap = buildConversionMap();
    }

    /**
     * @description Verify if Map contains values to be converted based on Custom Metadata
     *
     * @param valueMap Map to verify if it contains values to be converted
     * @return Map with converted values
     */
    public Map<String, Object> verifyValueConversion(Map<String, Object> valueMap) {
        for (String mapKey : valueMap.keySet()) {
            Object currentValue = valueMap.get(mapKey);
            //Verify if Conversion exists for Field. If not then no change is made.
            if (conversionMap.containsKey(mapKey)) {
                valueMap.put(mapKey, conversionMap.get(mapKey).get(String.valueOf(currentValue)));
            }
        }
        return valueMap;
    }

    /**
     * @description Build Conversion Map based on Metadata where Key = Integration Field's API Name (OCAPI) and
     * Value = Map where Key is Salesforce Value and Value is the Integration Value
     */
    private Map<String, Map<String, String>> buildConversionMap() {
        Map<String, Map<String, String>> resultMap = new Map<String, Map<String, String>>();
        for (COMM_ProductSynchronizationFieldConvert__mdt mdtValue : COMM_ProductSynchronizationFieldConvert__mdt.getAll().values()) {
            if (!resultMap.containsKey(mdtValue.COMM_IntegrationApiName__c)) {
                resultMap.put(mdtValue.COMM_IntegrationApiName__c, new Map<String, String>());
            }
            resultMap.get(mdtValue.COMM_IntegrationApiName__c).put(mdtValue.COMM_SalesforceValue__c, mdtValue.COMM_CommerceValue__c);
        }
        return resultMap;
    }
}