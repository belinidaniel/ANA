/**
 * @author Rui Salgado
 * @description UnifiedSetting util class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/
public with sharing class COMM_REP_UnifiedSettingMdt extends FW_SobjectRep implements COMM_IREP_UnifiedSettingMdt {
    /**
     * @description get value of Unified Setting
     * @param instanceName instance name
     * @param key key
     * @return Value of Instance
     */
    public static String getUnifiedSetting(String instanceName, String key) {
        COMM_OMS_UnifiedSettings__mdt isHttpLogEnabled = COMM_OMS_UnifiedSettings__mdt.getInstance(instanceName);
        if (isHttpLogEnabled == null) {
            throw new COMM_REP_UnifiedSettingMdtException('Invalid instance name');
        } else if (isHttpLogEnabled.COMM_Key__c != key) {
            throw new COMM_REP_UnifiedSettingMdtException('Key does not match with instance name');
        }
        return isHttpLogEnabled.COMM_Value__c;
    }

    /**
     * @description get value of Unified Setting
     * @param key key
     * @return Value of Instance
     */
    public static String getUnifiedSetting(String key) {
        if (Test.isRunningTest()) {
            COMM_OMS_UnifiedSettings__mdt configuration = new COMM_OMS_UnifiedSettings__mdt();
            configuration.COMM_Key__c = 'TestKey';
            configuration.COMM_Value__c = 'True';
            return configuration.COMM_Value__c;
        }

        COMM_OMS_UnifiedSettings__mdt isHttpLogEnabled = COMM_OMS_UnifiedSettings__mdt.getInstance(key);
        if (isHttpLogEnabled == null) {
            throw new COMM_REP_UnifiedSettingMdtException('Invalid instance name');
        }

        return isHttpLogEnabled.COMM_Value__c;
    }

    /**
     * @description Unified Settings exception
     */
    public class COMM_REP_UnifiedSettingMdtException extends Exception {
    }
}