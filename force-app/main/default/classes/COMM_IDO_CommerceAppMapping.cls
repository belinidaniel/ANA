/**
 * @author Daniel Lascas
 * @description COMM_CommerceAppMapping__mdt Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024       ECOMM-178: Original version
 **/
public interface COMM_IDO_CommerceAppMapping {
    /**
     * @description Method to map the values from a Salesforce SObject into the attributes Map to send
     * from the Commerce Connected App.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to Commerce
     * @param attributesMap The attributes Map where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    Map<String, String> mapAttributesFromSObject(SObject sobjRecord, Map<String, String> attributesMap, Boolean isB2C);
    /**
     * @description Method to obtain user's account data in a Map structured as a JSON
     *
     * @param userId Id of the User to obtain account data.
     * @param attributesMap Map where the mapped values are stored
     * @return Map structured as a JSON with the mapped values
     */
    Map<String, String> getAccountDataMapWithUserId(Id userId, Map<String, String> attributesMap);
}