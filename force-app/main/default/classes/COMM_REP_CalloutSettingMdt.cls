/**
 * @author Rui Salgado
 * @description COMM_OMS_CalloutSettings__mdt util class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/

public with sharing class COMM_REP_CalloutSettingMdt extends FW_SobjectRep implements COMM_IREP_CalloutSettingMdt {
    /**
     * Get COMM_OMS_CalloutSettings__mdt records by instanceName
     * @param instanceName
     * @return COMM_OMS_CalloutSettings__mdt
     */
    public COMM_OMS_CalloutSettings__mdt getCalloutSetting(String instanceName) {
        if (Test.isRunningTest()) {
            COMM_OMS_CalloutSettings__mdt configuration = new COMM_OMS_CalloutSettings__mdt();
            configuration.Endpoint_Server__c = 'Endpoint_Server';
            configuration.Endpoint_URI__c = 'Endpoint_URI';
            configuration.HTTP_Headers__c = 'HTTP_Headers=>123123';
            configuration.HTTP_Method__c = 'POST';
            configuration.QueryString__c = '';
            configuration.Timeout__c = 12000;
            return configuration;
        }

        COMM_OMS_CalloutSettings__mdt configuration = COMM_OMS_CalloutSettings__mdt.getInstance(instanceName);
        if (configuration == null) {
            throw new COMM_REP_CalloutSettingMdtException('Configuration not found for instance = ' + instanceName);
        }
        return configuration;
    }

    /**
     * @description Unified Settings exception
     */
    public class COMM_REP_CalloutSettingMdtException extends Exception {
    }
}