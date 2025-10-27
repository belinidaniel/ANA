/**
 * @author Daniel Lascas
 * @description PermissionSet repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-700: Original version
 **/
public inherited sharing class COMM_REP_PermissionSet extends FW_SobjectRep implements COMM_IREP_PermissionSet {
    /**
     * @description Retrieve a list of Permission Sets by a set of Names
     *
     * @param permissionSetNames Set of Permission Set Names to query
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of Permission Sets found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<PermissionSet> getPermissionSetsByName(Set<String> permissionSetNames, Boolean securityEnforced) {
        if (securityEnforced) {
            return [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames WITH USER_MODE];
        } else {
            return [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames];
        }
    }
}