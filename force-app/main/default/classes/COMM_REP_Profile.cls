/**
 * @author Daniel Lascas
 * @description Profile repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    22/02/2024       US usNumber - Original version
 * Miguel Freire    11/04/2024       Refactored getProfilesByName
 * Daniel Reto      29/05/2024       PDM warning messages fix
 **/
public inherited sharing class COMM_REP_Profile extends FW_SobjectRep implements COMM_IREP_Profile {
    /**
     * @description Retrieve a list of Profiles by a set of Names
     *
     * @param profileNames Set of Profile Names to query
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of Profiles found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Profile> getProfilesByName(Set<String> profileNames, Boolean securityEnforced) {
        List<Profile> profiles = new List<Profile>();
        if (securityEnforced) {
            profiles = [
                SELECT Id, Name
                FROM Profile
                WHERE Name IN :profileNames
                WITH USER_MODE
            ];
        } else {
            profiles = [
                SELECT Id, Name
                FROM Profile
                WHERE Name IN :profileNames
            ];
        }
        return profiles;
    }
}