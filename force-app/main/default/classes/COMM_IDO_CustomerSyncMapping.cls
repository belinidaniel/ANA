/**
 * @author Daniel Lascas
 * @description COMM_CustomerSynchronizationMapping__mdt Custom Metadata Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    12/06/2024       Original version
 **/
public interface COMM_IDO_CustomerSyncMapping {
    /**
     * @description Method to obtain list of all Core fields used in synchronization
     *
     * @param sObjectType API Name of the SObject the mapping will apply
     * @param isB2C Boolean indicating that mapping applied if for a B2C client
     * @return Set with the API Name of all Core Fields used in mapping
     */
    Set<String> getCoreFieldList(String sObjectType, Boolean isB2C);
    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map
     * to send to Commerce.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to Commerce
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @param isB2C Boolean indicating that mapping applied if for a B2C client
     **/
    void mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean isB2C);
}