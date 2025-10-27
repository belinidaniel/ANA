/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if User is expected to be a Partner Admin.
 * Adds required permission sets if he doesn't have them.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024		ECOMM-700: Original version
 **/
public class COMM_TW_User_VerifyPartnerPermission {
    private COMM_IREP_PermissionSetAssignment permissionSetAssignmentRep;
    private COMM_IDO_ProfilePermissionSetAssignment profilePermSetAssigDo;

    private List<PermissionSetAssignment> assignmentList;

    /**
     * @description Initialize REP Classes
     */
    public COMM_TW_User_VerifyPartnerPermission() {
        this.permissionSetAssignmentRep = new COMM_REP_PermissionSetAssignment();
        this.profilePermSetAssigDo = new COMM_DO_ProfilePermissionSetAssignment();
    }

    @TestVisible
    private COMM_TW_User_VerifyPartnerPermission(
        COMM_IREP_PermissionSetAssignment permissionSetAssignmentRep,
        COMM_IDO_ProfilePermissionSetAssignment profilePermSetAssigDo
    ) {
        this.permissionSetAssignmentRep = permissionSetAssignmentRep;
        this.profilePermSetAssigDo = profilePermSetAssigDo;
    }

    /**
     * @description Execute Trigger Worker Logic
     *
     * @param newUserList List with the User Records in New Context
     * @param isUpdate Boolean to indicate if trigger is running in Update Context
     */
    public void execute(List<User> newUserList, Boolean isUpdate) {
        Map<Id, Set<Id>> assignmentIdMap = profilePermSetAssigDo.getAssignmentMap();

        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id, Set<Id>> userAssignmentMap = new Map<Id, Set<Id>>();
        Set<Id> permissionSetIdSet = new Set<Id>();
        assignmentList = new List<PermissionSetAssignment>();
        for (User userRecord : newUserList) {
            if (assignmentIdMap.containsKey(userRecord.ProfileId) && isUpdate && userRecord.IsActive) {
                //Verify if User is being updated, is Active and if he has a Profile with
                //Permission Set assigned according to metadata. Add User to Map
                //to verify if he already has Permission Set Assignment.
                userMap.put(userRecord.Id, userRecord);
                userAssignmentMap.put(userRecord.Id, assignmentIdMap.get(userRecord.ProfileId));
                permissionSetIdSet.addAll(assignmentIdMap.get(userRecord.ProfileId));
            } else if (userRecord.IsActive && assignmentIdMap.containsKey(userRecord.ProfileId) && userRecord.IsActive) {
                //If User is being inserted as Active with a Profile with Permission Set assigned
                //according to metadata then create assignment records
                assignPermissionSet(assignmentIdMap, userRecord, true);
            }
        }

        //If Trigger is in Update Context and User Profile were changed.
        // Verify if Users that have Profiles with assigned Permission Sets already have those Permission Set assigned.
        if (!userMap.isEmpty() && isUpdate) {
            verifyAssignmentExists(userMap, userAssignmentMap, permissionSetIdSet);
        }

        //Assign Permission Set to Users if any were created
        if (!assignmentList.isEmpty()) {
            permissionSetAssignmentRep.insertSObjects(assignmentList);
        }
    }

    /**
     * @description For Update Logic. Verifies if a Permission Set Assignment is already created for the User.
     * If it wasn't then create a new assignment. If it exists skip creation of new assignment.
     *
     * @param userMap Map with the user Records being verified (Key is User's Id)
     * @param userAssignmentMap Map with the Ids of the Permission Sets that the User must be assinged to (Key is User's Id)
     * @param permissionSetIdSet Set of Ids of Permission Sets required for assignment to user
     */
    private void verifyAssignmentExists(Map<Id, User> userMap, Map<Id, Set<Id>> userAssignmentMap, Set<Id> permissionSetIdSet) {
        for (
            PermissionSetAssignment assignment : permissionSetAssignmentRep.getAssignmentsByUserIdAndPermissionId(
                userMap.keySet(),
                permissionSetIdSet
            )
        ) {
            userAssignmentMap.get(assignment.AssigneeId).remove(assignment.PermissionSetId);
        }
        //For Remaining User's add Permission Set Assignment.
        for (Id userId : userAssignmentMap.keySet()) {
            if (!userAssignmentMap.get(userId).isEmpty()) {
                assignPermissionSet(userAssignmentMap, userMap.get(userId), false);
            }
        }
    }

    /**
     * @description Verifies if User requires assignment to Permission Set according to
     * Assignment Map. If he does then create instance of a Permission Set Assignment
     * and add to assignment list.
     *
     * @param assignmentIdMap Map with the required assignments (Key is User Id or Profile Id)
     * @param userRecord Record of the User the assignment is being verified
     * @param useProfileId Boolean to indicate if assignment map key is User's Profile Id or Record Id
     */
    private void assignPermissionSet(Map<Id, Set<Id>> assignmentIdMap, User userRecord, Boolean useProfileId) {
        if (assignmentIdMap.containsKey(useProfileId ? userRecord.ProfileId : userRecord.Id)) {
            //If User is being updated has Partner Admin's Profile, assign Permission Set.
            for (Id permissionId : assignmentIdMap.get(useProfileId ? userRecord.ProfileId : userRecord.Id)) {
                assignmentList.add(new PermissionSetAssignment(AssigneeId = userRecord.Id, PermissionSetId = permissionId));
            }
        }
    }
}