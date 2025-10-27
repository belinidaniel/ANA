/**
 * @author Daniel Lascas
 * @description COMM_ResellerApiMapping__mdt Custom Metadata Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/05/2024       ECOMM-386: Original version
 **/
public interface COMM_IDO_ResellerApiMapping {
    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map to send
     * to resellers
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to reseller
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @return Map updated with the values from SObject according to metadata
     **/
    Map<String, Object> mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap);
}