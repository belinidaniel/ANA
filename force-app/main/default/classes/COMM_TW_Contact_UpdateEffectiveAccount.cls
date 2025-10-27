/**
 * @author Daniel Lascas
 * @description Trigger worker that updates Effective Account Lookup with the Contact's
 * Account when it has no value.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/10/2024		ECOMM-1813: CR-33
 **/
public with sharing class COMM_TW_Contact_UpdateEffectiveAccount {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newContactList List with the Contact Records in after context.
     */
    public void execute(List<Contact> newContactList) {
        for (Contact newContact : newContactList) {
            //For Non-Person Contact verify if Effective Account is Blank. If it is then set it with Contact's Account.
            if (!newContact.IsPersonAccount && String.isBlank(newContact.COMM_EffectiveAccountId__c) && String.isNotBlank(newContact.AccountId)) {
                newContact.COMM_EffectiveAccountId__c = newContact.AccountId;
            }
        }
    }
}