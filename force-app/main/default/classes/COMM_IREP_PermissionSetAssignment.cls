/**
 * @author Daniel Lascas
 * @description PermissionSetAssignment repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-700: Original version
 **/
public interface COMM_IREP_PermissionSetAssignment extends FW_ISObjectRep {
    /**
     * @description Retrieve the list of Permission Sets Assigned to User by a set of Ids and Permission Set Ids.
     * Used to verify if a User already has Permission Sets assigned to them.
     *
     * @param userIds Set of User Ids to query Users
     * @param permissionIds Set of Permission Set Ids
     * @return List of Permission Set Assignments found
     */
    List<PermissionSetAssignment> getAssignmentsByUserIdAndPermissionId(Set<Id> userIds, Set<Id> permissionIds);
}