/**
 * @author Daniel Lascas
 * @description COMM_SAPMapping__mdt Custom Metadata Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-194: Original version
 **/
public interface COMM_IDO_SAPMapping {
    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map to send
     * to SAP
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to SAP
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @param additionalProduct Boolean to indicate if mapping is done for additional product (ex: Card in Subscription Invoice)
     * @return Map updated with the values from SObject according to metadata
     **/
    Map<String, Object> mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean additionalProduct);
}