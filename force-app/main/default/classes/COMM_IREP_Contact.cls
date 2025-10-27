/**
 * @author Daniel Lascas
 * @description Contact repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/02/2024       Original version
 **/
public interface COMM_IREP_Contact extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Contacts with fields required for
     * OCAPI requests by a set of Contact Ids
     *
     * @param contactIds Set of Contact Ids to query
     * @return List of Contacts Records found
     **/
    List<Contact> getContactWithRequestFieldsByIds(Set<Id> contactIds);
}