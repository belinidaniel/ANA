/**
 * @author           Daniel Lascas
 * @description      COMM_PortalValidationSetting__mdt Custom Metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/03/2024       Original version
 * Miguel Freire    23/03/2024       Added getPortalSettingByEnvironmentId
 **/
public inherited sharing class COMM_DO_PortalValidationSetting implements COMM_IDO_PortalValidationSetting {
    /**
     * @description Retrieve Portal Validation Setting based on Community and Process.
     *
     * @param communityName API Name of the Salesforce Community associated with the Setting.
     * @param processName Name of the Process the setting applies to.
     */
    public static COMM_PortalValidationSetting__mdt getPortalSetting(String communityName, String processName) {
        for (COMM_PortalValidationSetting__mdt mdtValue : COMM_PortalValidationSetting__mdt.getAll().values()) {
            String community = String.valueOf(mdtValue.COMM_Community__c);
            String process = String.valueOf(mdtValue.COMM_Process__c);
            if (community != null && process != null && community.equals(communityName) && process.equals(processName)) {
                return mdtValue;
            }
        }
        return null;
    }

    /**
     * @description Retrieve Portal Validation Setting based on EnvironmentId.
     *
     * @param environmentId ID of the Salesforce Org associated with the Setting.
     */
    public static COMM_PortalValidationSetting__mdt getPortalSettingByEnvironmentId(String environmentId) {
        List<COMM_PortalValidationSetting__mdt> mdtValue = COMM_PortalValidationSetting__mdt.getAll().values();
        for (COMM_PortalValidationSetting__mdt metadataRecord : mdtValue) {
            if (metadataRecord.COMM_EnvironmentId__c == environmentId) {
                return metadataRecord;
            }
        }
        return null;
    }
}