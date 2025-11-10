/**
 * @author Miguel Justo
 * @description Service Layer class that handles the User methods
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo   06/03/2024       Original version
 **/
public with sharing class COMM_SL_User {
    /**
     * @description Get User  EffectiveAccountId .
     *
     * @param userId the user id.
     * @return User whith effective account id .
     */
    public static String getEffectiveAccountId(id userId) {
        // Repositories classes
        COMM_REP_User userRep = new COMM_REP_User();

        return userRep.getUser(new Set<Id>{ userId })[0].COMM_EffectiveAccountId__c;
    }
}