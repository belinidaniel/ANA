/**
 * @author Rui Salgado
 * @description COMM_REP_SapTaxCodesMapMdtTest class. Coverage cannot go above 55
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      16/05/2024    100           Original version
 **/
@isTest
private with sharing class COMM_REP_SapTaxCodesMapMdtTest {
    /**
     * @description Test method of COMM_REP_SapTaxCodesMapMdt getSapTaxCodesMap
     */
    @isTest
    static void shouldGetValueBySplitParameters() {
        String value = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT', 'Nowhere', 'OT');
        System.assert(!String.isBlank(value), 'Settings could not be received');
        System.assertEquals('XX', value, 'Incorrect value returned');
    }

    /**
     * @description Test method of COMM_REP_SapTaxCodesMapMdt overloaded getSapTaxCodesMap
     */
    @isTest
    static void shouldGetValueByKey() {
        String value = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT_Nowhere_OT');
        System.assert(!String.isBlank(value), 'Settings could not be received');
        System.assertEquals('XX', value, 'Incorrect value returned');
    }

    /**
     * @description Test method of COMM_REP_SapTaxCodesMapMdt overloaded getSapTaxCodesMap
     */
    @isTest
    static void shouldThrowException() {
        Test.startTest();
        boolean exceptionThrown = false;
        try {
            String value = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap(null);
        } catch (COMM_REP_SapTaxCodesMapMdt.COMM_REP_SapTaxCodesMapMdtException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown');
    }
}