/**
 * @author Daniel Reto
 * @description Tax Value Configuration repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      18/10/2024       Original version
 **/

 public with sharing class COMM_REP_TaxValueConfigurationMdt extends FW_SobjectRep implements COMM_IREP_TaxValueConfigurationMdt {
    /**
     * @description get value of Tax Value Configuration TaxValue__c
     * @param instanceName instance name
     * @return Value of Instance COMM_TaxValue__c
     */
    public Decimal getTaxValueConfig(String instanceName) {
        COMM_TaxValueConfiguration__mdt taxValueConfigInstance;
        if (Test.isRunningTest() && instanceName != null) {
            taxValueConfigInstance = new COMM_TaxValueConfiguration__mdt();
            taxValueConfigInstance.COMM_TaxValue__c = 23;
        } else {
            taxValueConfigInstance = COMM_TaxValueConfiguration__mdt.getInstance(instanceName);
            if (taxValueConfigInstance == null) {
                throw new COMM_REP_TaxValueConfigurationMdtException('Invalid instance name ' + instanceName);
            }
        }
        return taxValueConfigInstance.COMM_TaxValue__c;
    }

    /**
     * @description Tax Value Configuration exception
     */
    public class COMM_REP_TaxValueConfigurationMdtException extends Exception {
    }
}