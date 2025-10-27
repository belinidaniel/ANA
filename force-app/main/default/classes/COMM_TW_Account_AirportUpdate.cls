/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the multi-picklist COMM_Airport__c
 * was changed. If it was copy value to COMM_AirportTextList__c to update sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
public with sharing class COMM_TW_Account_AirportUpdate {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newAccountList List with the Account Records in after context.
     * @param oldAccountMap Map with the Account Records in before context.
     */
    public void execute(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        for (Account newAccount : newAccountList) {
            //Verify Airport Field Changed
            if (COMM_GEN_Utility.isChangedField(newAccount, oldAccountMap, Account.COMM_Airport__c)) {
                newAccount.COMM_AirportTextList__c = newAccount.COMM_Airport__c;
            }
        }
    }
}