/**
 * @author Carlos Fusco
 * @description Group repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer           Date             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco     07/04/2024        Original version
 * Miguel freire    19/04/2024        Added method getGroupsByName
 **/
public interface COMM_IREP_Group extends FW_ISObjectRep {
    /**
     * @description Get group queue id by developer name
     *
     * @param developerName Queue developer name
     * @param securityEnforced Flag to mark usage the security enforced clause
     * @return List of queue related on developer name
     */
    List<Group> getQueueIdByDeveloperName(String developerName, Boolean securityEnforced);
    /**
     * @description Get group queue id by developer name
     *
     * @param developerName Queue developer name
     * @param securityEnforced Flag to mark usage the security enforced clause
     * @return List of queue related on developer name
     */
    List<Group> getGroupsByName(Set<String> groupNames, Boolean securityEnforced);
}