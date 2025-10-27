/**
 * @author Daniel Lascas
 * @description COMM_SubscriptionManagementMapping__mdt Custom Metadata Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/06/2024       Original version
 **/
public interface COMM_IDO_SubscriptionManagementMapping {
    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @return Map updated with the values from SObject according to metadata
     **/
    Map<String, Object> mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap);
}