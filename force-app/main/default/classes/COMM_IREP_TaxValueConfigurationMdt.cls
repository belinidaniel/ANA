/**
 * @author Daniel Reto
 * @description Tax Value Configuration repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      18/10/2024        Original version
 **/
public interface COMM_IREP_TaxValueConfigurationMdt extends FW_ISObjectRep {
    /**
     * @description get value of Tax Value Configuration TaxValue__c
     * @param instanceName instance name
     * @return Value of Instance COMM_TaxValue__c
     */
    Decimal getTaxValueConfig(String instanceName);
}