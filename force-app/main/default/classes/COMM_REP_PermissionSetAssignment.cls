/**
 * @author Daniel Lascas
 * @description PermissionSetAssignment repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-700: Original version
 **/
public inherited sharing class COMM_REP_PermissionSetAssignment extends FW_SobjectRep implements COMM_IREP_PermissionSetAssignment {
    /**
     * @description Retrieve the list of Permission Sets Assigned to User by a set of Ids and Permission Set Ids.
     * Used to verify if a User already has Permission Sets assigned to them.
     *
     * @param userIds Set of User Ids to query Users
     * @param permissionIds Set of Permission Set Ids
     * @return List of Permission Set Assignments found
     */
    public List<PermissionSetAssignment> getAssignmentsByUserIdAndPermissionId(Set<Id> userIds, Set<Id> permissionIds) {
        return [
            SELECT Id, AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds AND PermissionSetId IN :permissionIds AND IsActive = TRUE
            WITH USER_MODE
        ];
    }
}