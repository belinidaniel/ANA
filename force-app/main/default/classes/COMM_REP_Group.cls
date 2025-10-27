/**
 * @author Carlos Fusco
 * @description Group repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    07/04/2024       Original version
 * Miguel freire   19/04/2024       Added method getGroupsByName
 * Daniel Reto     29/05/2024      PDM warning messages fix
 **/
public with sharing class COMM_REP_Group extends FW_SobjectRep implements COMM_IREP_Group {
    /**
     * @description Get group queue id by developer name
     *
     * @param developerName Queue developer name
     * @param securityEnforced Flag to mark usage the security enforced clause
     * @return List of queue related on developer name
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Group> getQueueIdByDeveloperName(String developerName, Boolean securityEnforced) {
        List<Group> groups = new List<Group>();
        if (securityEnforced) {
            groups = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = :developerName WITH USER_MODE];
        } else {
            groups = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = :developerName];
        }
        return groups;
    }

    /**
     * @description Retrieve a list of Groups by a set of Names
     *
     * @param groupNames Set of Group Names to query
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of Group found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Group> getGroupsByName(Set<String> groupNames, Boolean securityEnforced) {
        List<Group> groups = new List<Group>();
        if (securityEnforced) {
            groups = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :groupNames
                WITH USER_MODE
            ];
        } else {
            groups = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :groupNames
            ];
        }
        return groups;
    }
}