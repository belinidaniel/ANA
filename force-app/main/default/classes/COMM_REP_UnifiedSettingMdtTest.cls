/**
 * @author Rui Salgado
 * @description COMM_REP_UnifiedSettingMdt class. Coverage cannot go above 55
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    55            Original version
 **/
@isTest
private with sharing class COMM_REP_UnifiedSettingMdtTest {
    /**
     * @description Test method of COMM_REP_UnifiedSettingMdt getUnifiedSetting
     */
    @isTest
    static void shouldGetValueByKeyAndInstanceName() {
        String value = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('HttpLogEnabled', 'HttpLogEnabled');
        System.assert(!String.isBlank(value), 'Settings could not be received');
    }

    /**
     * @description Test method of COMM_REP_UnifiedSettingMdt overloaded getUnifiedSetting
     */
    @isTest
    static void shouldGetValueByKey() {
        String value = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('HttpLogEnabled');
        System.assert(!String.isBlank(value), 'Settings could not be received');
    }
}