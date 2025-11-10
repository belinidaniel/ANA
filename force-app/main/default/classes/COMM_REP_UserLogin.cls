/**
 * @author Miguel Freire
 * @description UserLogin repository class to query data.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    15/04/2024       Miguel Freire
 **/
public inherited sharing class COMM_REP_UserLogin extends FW_SobjectRep implements COMM_IREP_UserLogin {
    /**
     * @description Retrieve the list of UserLogin Records by a Set of User Ids
     *
     * @param userIds Set of User Ids to query UserLogins
     * @return List of UserLogin Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<UserLogin> getUserLoginsByUserId(Set<Id> userIds) {
        return [
            SELECT Id, UserId
            FROM UserLogin
            WHERE UserId IN :userIds
        ];
    }
}