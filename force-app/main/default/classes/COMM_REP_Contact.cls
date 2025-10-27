/**
 * @author Daniel Lascas
 * @description Contact repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/02/2024       Original version
 * Daniel Lascas    09/07/2024       ECOMM-370: Original version
 **/
public inherited sharing class COMM_REP_Contact extends FW_SobjectRep implements COMM_IREP_Contact {
    /**
     * @description Retrieve a list of Contacts with fields required for
     * OCAPI requests by a set of Contact Ids
     *
     * @param contactIds Set of Contact Ids to query
     * @return List of Contacts Records found
     **/
    public List<Contact> getContactWithRequestFieldsByIds(Set<Id> contactIds) {
        return [
            SELECT Id, Email, COMM_IntegrationRequestBody__c, COMM_CustomerNumber__c
            FROM Contact
            WHERE Id IN :contactIds
            WITH SECURITY_ENFORCED
        ];
    }
}