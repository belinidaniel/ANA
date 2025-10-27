/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the B2B Account's VAT Number
 * is valid for the Provided Country in Billing Address.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024		ECOMM-194: Original version
 **/
public with sharing class COMM_TW_Account_ValidateVAT {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newAccountList List with the Account Records in after context.
     * @param oldAccountMap Map with the Account Records in before context.
     */
    public void execute(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        for (Account newAccount : newAccountList) {
            //Verify Account VAT Number is valid
            if (COMM_DO_Account.verifyInvalidVAT(newAccount, oldAccountMap?.get(newAccount.Id), true)) {
                //Add Error Message if VAT Number is Invalid.
                newAccount.addError(Account.COMM_VATNumber__c, System.Label.COMM_ACCOUNT_INVALID_VAT_ERROR);
            }
            //Verify Company VAT Number is valid (only if Account is B2C)
            if (newAccount.IsPersonAccount && COMM_DO_Account.verifyInvalidVAT(newAccount, oldAccountMap?.get(newAccount.Id), false)) {
                //Add Error Message if VAT Number is Invalid.
                newAccount.addError(Account.COMM_CompanyVATNumber__c, System.Label.COMM_ACCOUNT_INVALID_VAT_ERROR);
            }
        }
    }
}