/**
 * @author Daniel Lascas
 * @description COMM_ProfilePermissionSetAssignment__mdt Custom Metadata
 * Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024       ECOMM-700: Original version
 **/
public inherited sharing class COMM_DO_ProfilePermissionSetAssignment implements COMM_IDO_ProfilePermissionSetAssignment {
    private final Map<Id, Set<Id>> profilePSetAssignmentIdsMap;
    private COMM_IREP_Profile profileRep;
    private COMM_IREP_PermissionSet permissionSetRep;

    /**
     * @description Class Constructor to initialize Map
     */
    public COMM_DO_ProfilePermissionSetAssignment() {
        profileRep = new COMM_REP_Profile();
        permissionSetRep = new COMM_REP_PermissionSet();
        profilePSetAssignmentIdsMap = buildMap();
    }

    /**
     * @description Method to obtain the Map for the Assignments between
     * Profile and Permission Set's.
     *
     * @return Map with Profile Id as Key and list of Permission Set Ids
     * assigned to it
     **/
    public Map<Id, Set<Id>> getAssignmentMap() {
        return profilePSetAssignmentIdsMap;
    }

    /**
     * @description Method to create a Map where Key = Profile Id
     * Value = Set of Permission Set Ids
     *
     * @return Map of Metadata where Key is the Id of the Profile the mapping is set to
     **/
    private Map<Id, Set<Id>> buildMap() {
        Map<String, Id> profileNameMap = new Map<String, Id>();
        Map<String, Id> permissionNameMap = new Map<String, Id>();

        //Obtain the Name of all Profiles and Permission Sets that are being Mapped
        for (COMM_ProfilePermissionSetAssignment__mdt mdtValue : COMM_ProfilePermissionSetAssignment__mdt.getAll().values()) {
            String profileName = String.valueOf(mdtValue.COMM_ProfileName__c);
            List<String> permissionSetList = String.valueOf(mdtValue.COMM_PermissionSetList__c).split(',');
            profileNameMap.put(profileName, null);
            for (String permissionSetName : permissionSetList) {
                permissionNameMap.put(permissionSetName, null);
            }
        }

        //Query Profile and Permission Sets to obtain their Ids
        for (Profile profileRecord : profileRep.getProfilesByName(profileNameMap.keySet(), false)) {
            profileNameMap.put(profileRecord.Name, profileRecord.Id);
        }
        for (PermissionSet pSetRecord : permissionSetRep.getPermissionSetsByName(permissionNameMap.keySet(), false)) {
            permissionNameMap.put(pSetRecord.Name, pSetRecord.Id);
        }

        //Create Map with Profile and Permission Set Ids
        Map<Id, Set<Id>> mappingMap = new Map<Id, Set<Id>>();
        for (COMM_ProfilePermissionSetAssignment__mdt mdtValue : COMM_ProfilePermissionSetAssignment__mdt.getAll().values()) {
            String profileName = String.valueOf(mdtValue.COMM_ProfileName__c);
            List<String> permissionSetList = String.valueOf(mdtValue.COMM_PermissionSetList__c).split(',');
            Set<Id> permissionIdSet = new Set<Id>();
            for (String permissionSetName : permissionSetList) {
                permissionIdSet.add(permissionNameMap.get(permissionSetName));
            }
            mappingMap.put(profileNameMap.get(profileName), permissionIdSet);
        }
        return mappingMap;
    }
}