/**
 * @author Daniel Lascas
 * @description Profile repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    22/02/2024       Original version
 * Miguel Freire    11/04/2024       Refactored getProfilesByName
 **/
public interface COMM_IREP_Profile extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Profiles by a set of Names
     *
     * @param profileNames Set of Profile Names to query
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of Profiles found
     **/
    List<Profile> getProfilesByName(Set<String> profileNames, Boolean securityEnforced);
}