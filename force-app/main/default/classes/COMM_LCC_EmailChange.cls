/**
 * @author Daniel Lascas
 * @description Controller for the comm_emailChange lwc.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/06/2024       ECOMM-1377 - Original version
 *
 **/
public with sharing class COMM_LCC_EmailChange {
    /**
     * @description LWC accessible method to validate the change email request.
     *
     * @param token Token with change request.
     * @return True if change was made successfully, false otherwise.
     */
    @AuraEnabled
    public static Boolean validateEmailChange(String token) {
        try {
            return new COMM_SL_ChangeEmail().validateEmailChange(token);
        } catch (Exception e) {
            //Log Error
            COMM_GEN_Utility.logError(e, 'Validate Email Change', 'COMM_LCC_EmailChange');
            throw e;
        }
    }
}