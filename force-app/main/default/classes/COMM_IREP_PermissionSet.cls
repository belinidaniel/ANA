/**
 * @author Daniel Lascas
 * @description PermissionSet repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-700: Original version
 **/
public interface COMM_IREP_PermissionSet extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Permission Sets by a set of Names
     *
     * @param permissionSetNames Set of Permission Set Names to query
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of Permission Sets found
     **/
    List<PermissionSet> getPermissionSetsByName(Set<String> permissionSetNames, Boolean securityEnforced);
}