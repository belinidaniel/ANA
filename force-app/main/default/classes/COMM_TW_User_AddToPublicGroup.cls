/**
 * @author Miguel Freire
 * @description Trigger worker that adds a new Partner Admin User to a public group.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    17/04/2024		Original version
 **/
public class COMM_TW_User_AddToPublicGroup {
    private COMM_IREP_Profile profileRep;
    private COMM_IREP_Group groupRep;
    private COMM_IREP_GroupMember groupMemberRep;

    /**
     * @description Initialize REP Classes
     */
    public COMM_TW_User_AddToPublicGroup() {
        this.profileRep = new COMM_REP_Profile();
        this.groupRep = new COMM_REP_Group();
        this.groupMemberRep = new COMM_REP_GroupMember();
    }

    @TestVisible
    private COMM_TW_User_AddToPublicGroup(COMM_IREP_Profile profileRep, COMM_IREP_Group groupRep, COMM_IREP_GroupMember groupMemberRep) {
        this.profileRep = profileRep;
        this.groupRep = groupRep;
        this.groupMemberRep = groupMemberRep;
    }

    /**
     * @description Execute Trigger Worker Logic
     *
     * @param newUserList List with the User Records in New Context
     */
    public void execute(List<User> newUserList) {
        List<Profile> profilesList = profileRep.getProfilesByName(
            new Set<String>{ COMM_DO_Profile.PROFILE_NAME_SUPER_PARTNER_ADMIN, COMM_DO_Profile.PROFILE_NAME_PARTNER_ADMIN },
            false
        );
        // List of users to add to the public group
        List<GroupMember> groupMembers = new List<GroupMember>();
        // Get the public group id
        Id publicGroupId = (groupRep.getGroupsByName(new Set<String>{ COMM_DO_Group.GROUP_NAME_PARTNER_ADMIN }, false)[0]).Id;
        // Check if user is Partner Admin
        for (User userRecord : newUserList) {
            if (userRecord.profileId == profilesList[0].Id || userRecord.profileId == profilesList[1].Id) {
                // Add the users to the public group
                groupMembers.add(new GroupMember(UserOrGroupId = userRecord.Id, GroupId = publicGroupId));
            }
        }
        // Insert the group members
        if (!groupMembers.isEmpty()) {
            groupMemberRep.insertSObjects(groupMembers);
        }
    }
}