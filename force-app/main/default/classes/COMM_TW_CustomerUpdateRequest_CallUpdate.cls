/**
 * @author Daniel Lascas
 * @description Trigger worker that calls the Queueable Class to send update callout.
 * Used to ensure User that makes calls has required permissions.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/09/2024		Original version
 **/
public class COMM_TW_CustomerUpdateRequest_CallUpdate {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param eventList List with the Account Records in after context.
     */
    public void execute(List<COMM_CustomerUpdateRequest__e> eventList) {
        List<Id> accountToSyncList = new List<Id>();
        List<Id> contactToSyncList = new List<Id>();
        for (COMM_CustomerUpdateRequest__e eventRecord : eventList) {
            //Check if Event has Account Id. Store it in List for Processing.
            if (String.isNotBlank(eventRecord.COMM_AccountId__c)) {
                accountToSyncList.add(eventRecord.COMM_AccountId__c);
            }
            //Check if Event has Contact Id. Store it in List for Processing.
            if (String.isNotBlank(eventRecord.COMM_ContactId__c)) {
                contactToSyncList.add(eventRecord.COMM_ContactId__c);
            }
        }
        //Calls Queuable with Account to Process
        if (!accountToSyncList.isEmpty()) {
            COMM_Async_UpdateCustomerInCommQueuable syncAccountQueuable = new COMM_Async_UpdateCustomerInCommQueuable(
                accountToSyncList,
                String.valueOf(Account.sObjectType)
            );
            System.enqueueJob(syncAccountQueuable);
        }
        //Calls Queuable with Contact to Process
        if (!contactToSyncList.isEmpty()) {
            COMM_Async_UpdateCustomerInCommQueuable syncContactQueuable = new COMM_Async_UpdateCustomerInCommQueuable(
                contactToSyncList,
                String.valueOf(Contact.sObjectType)
            );
            System.enqueueJob(syncContactQueuable);
        }
    }
}