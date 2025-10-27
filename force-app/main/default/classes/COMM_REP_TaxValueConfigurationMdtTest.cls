/**
 * @author Daniel Reto
 * @description COMM_REP_TaxValueConfigurationMdtTest class.
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      18/10/2024    100           Original version
 **/
@isTest
private with sharing class COMM_REP_TaxValueConfigurationMdtTest {
    /**
     * @description Test method of COMM_REP_SapTaxCodesMapMdt overloaded getSapTaxCodesMap
     */
    @isTest
    static void getTaxValueConfig() {
        COMM_IREP_TaxValueConfigurationMdt taxValueConfigurationMdtRep = new COMM_REP_TaxValueConfigurationMdt();
        Decimal value = taxValueConfigurationMdtRep.getTaxValueConfig('Azores');
        System.assertEquals(23, value, 'Incorrect value returned');
    }

    /**
     * @description Test method of COMM_REP_SapTaxCodesMapMdt overloaded getSapTaxCodesMap
     */
    @isTest
    static void getTaxValueConfigThrowException() {
        Test.startTest();
        boolean exceptionThrown = false;
        COMM_IREP_TaxValueConfigurationMdt taxValueConfigurationMdtRep = new COMM_REP_TaxValueConfigurationMdt();
        try {
            Decimal value = taxValueConfigurationMdtRep.getTaxValueConfig(null);
        } catch (COMM_REP_TaxValueConfigurationMdt.COMM_REP_TaxValueConfigurationMdtException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown');
    }
}