/**
 * @author Miguel Freire
 * @description UserLogin repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    15/04/2024       Original version
 **/
public interface COMM_IREP_UserLogin extends FW_ISObjectRep {
    /**
     * @description Retrieve the list of UserLogin Records by a Set of User Ids
     *
     * @param userIds Set of User Ids to query UserLogins
     * @return List of UserLogin Records found
     **/
    List<UserLogin> getUserLoginsByUserId(Set<Id> userIds);
}