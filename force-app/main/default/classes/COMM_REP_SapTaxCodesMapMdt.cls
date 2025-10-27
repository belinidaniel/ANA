/**
 * @author Rui Salgado
 * @description SAP Tax Codes map interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      21/04/2024       Original version
 **/

public with sharing class COMM_REP_SapTaxCodesMapMdt extends FW_SobjectRep implements COMM_IREP_SapTaxCodesMapMdt {
    /**
     * @description get value of SAP Tax Codes map
     * @param instanceName instance name
     * @return Value of Instance COMM_Sap_Code__c
     */
    public static String getSapTaxCodesMap(String instanceName) {
        COMM_SAPTaxCodesMap__mdt sapInstance;
        if (Test.isRunningTest() && instanceName != null) {
            sapInstance = new COMM_SAPTaxCodesMap__mdt();
            sapInstance.COMM_Sap_Code__c = 'XX';
        } else {
            sapInstance = COMM_SAPTaxCodesMap__mdt.getInstance(instanceName);
            if (sapInstance == null) {
                throw new COMM_REP_SapTaxCodesMapMdtException('Invalid instance name ' + instanceName);
            }
        }
        return sapInstance.COMM_Sap_Code__c;
    }

    /**
     * @description get value of SAP Tax Codes map
     * <TipoDoc>_<Local>_<TipoCliente>
     * @param docType document type (FT or NC)
     * @param location Product2.COMM_Tax__c
     * @param clientType  NAC, COM, OT (Nacional, comunitário, outro)
     * @return Value of Instance COMM_Sap_Code__c
     */
    public static String getSapTaxCodesMap(String docType, String location, String clientType) {
        String instanceName = docType + '_' + location + '_' + clientType;
        return getSapTaxCodesMap(instanceName);
    }

    /**
     * @description SapTaxCodesMap exception
     */
    public class COMM_REP_SapTaxCodesMapMdtException extends Exception {
    }
}