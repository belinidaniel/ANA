/**
 * @author Rui Salgado
 * @description COMM_REP_CalloutSettingMdtTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    71            Original version
 **/
@isTest
private with sharing class COMM_REP_CalloutSettingMdtTest {
    /**
     * @description Test method of COMM_REP_CalloutSettingMdt getCalloutSetting
     */
    private static COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();

    @isTest
    static void shouldGetValueByInstanceName() {
        Test.startTest();
        COMM_OMS_CalloutSettings__mdt setting = calloutSettingsRep.getCalloutSetting('Test');
        Test.stopTest();
        System.assert(!String.isBlank(setting.Endpoint_Server__c), 'Endpoint_Server__c could not be received');
    }
}