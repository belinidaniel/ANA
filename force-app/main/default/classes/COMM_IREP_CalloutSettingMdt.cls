/**
 * @author Rui Salgado
 * @description COMM_OMS_CalloutSettings__mdt util interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/

public interface COMM_IREP_CalloutSettingMdt {
    /**
     * Get COMM_OMS_CalloutSettings__mdt records by instanceName
     * @param instanceName
     * @return COMM_OMS_CalloutSettings__mdt
     */
    COMM_OMS_CalloutSettings__mdt getCalloutSetting(String instanceName);
}