/**
 * @author Rui Salgado
 * @description UnifiedSetting util interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/

public interface COMM_IREP_UnifiedSettingMdt {
    /**
     * @description get value of Unified Setting
     * @param instanceName instance name
     * @param key key
     * @return Value of Instance
     */
    String getUnifiedSetting(String instanceName, String key);

    /**
     * @description get value of Unified Setting
     * @param key key
     * @return Value of Instance
     */
    String getUnifiedSetting(String key);
}