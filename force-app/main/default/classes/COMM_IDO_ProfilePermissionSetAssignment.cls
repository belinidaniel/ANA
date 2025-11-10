/**
 * @author Daniel Lascas
 * @description COMM_ProfilePermissionSetAssignment__mdt Custom Metadata
 * Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024       ECOMM-700: Original version
 **/
public interface COMM_IDO_ProfilePermissionSetAssignment {
    /**
     * @description Method to obtain the Map for the Assignments between
     * Profile and Permission Set's.
     *
     * @return Map with Profile Id as Key and Set of Permission Set Ids
     * assigned to it
     **/
    Map<Id, Set<Id>> getAssignmentMap();
}