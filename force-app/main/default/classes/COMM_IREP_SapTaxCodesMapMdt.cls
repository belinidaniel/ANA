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

public interface COMM_IREP_SapTaxCodesMapMdt {
    /**
     * @description get value of SAP Tax Codes map
     * @param instanceName instance name
     * @return Value of Instance COMM_Sap_Code__c
     */
    String getSapTaxCodesMap(String instanceName);

    /**
     * @description get value of SAP Tax Codes map
     * <TipoDoc>_<Local>_<TipoCliente>
     * @param docType document type (FT or NC)
     * @param location Product2.COMM_Tax__c
     * @param clientType  NAC, COM, OT (Nacional, comunitário, outro)
     * @return Value of Instance COMM_Sap_Code__c
     */
    String getSapTaxCodesMap(String docType, String location, String clientType);
}