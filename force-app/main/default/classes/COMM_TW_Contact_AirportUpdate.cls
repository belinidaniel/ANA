/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the multi-picklist COMM_Airport__c
 * was changed. If it was copy value to COMM_AirportTextList__c to update sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/07/2024		ECOMM-1602: CR-33
 **/
public with sharing class COMM_TW_Contact_AirportUpdate {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newContactList List with the Contact Records in after context.
     * @param oldContactMap Map with the Contact Records in before context.
     */
    public void execute(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        Map<Id, List<Contact>> contactWithAccountIdMap = new Map<Id, List<Contact>>();
        for (Contact newContact : newContactList) {
            //Verify Airport Field Changed
            if (COMM_GEN_Utility.isChangedField(newContact, oldContactMap, Contact.COMM_Airport__c)) {
                newContact.COMM_AirportTextList__c = newContact.COMM_Airport__c;
            }
        }
    }
}