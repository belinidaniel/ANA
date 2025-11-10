/**
 * @author Daniel Lascas
 * @description COMM_AccountManagementMapping__mdt Custom Metadata Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/03/2024       ECOMM-142 - Original version
 **/
public interface COMM_IDO_AccountManagementMapping {
    /**
     * @description Method to map the values from a Salesforce SObject into a JSON structured Map to send
     * to the front-end of the Account Management.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to the front-end
     * @param jsonMap The JSON Map where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    void mapJsonFromSObject(SObject sobjRecord, Map<String, Object> jsonMap, Boolean isB2C);

    /**
     * @description Method to map the values from the Account Management JSON obtained from front-end
     * into a Salesforce SObject.
     *
     * @param jsonMap JSON converted into a Map to be converted into a Salesforce SObject
     * @param sobjRecord The Salesforce SObject where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    void mapSObjectFromJson(Map<String, Object> jsonMap, SObject sobjRecord, Boolean isB2C);
}