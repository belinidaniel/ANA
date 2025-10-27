/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if one of the fields that is synched
 * with Commerce was changed. If it was then build an update request body and calls
 * Queueable Class to send update callout.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/07/2024		ECOMM-1637: Original version
 **/
public class COMM_TW_Contact_CustomerSyncWithCommerce {
    private COMM_IDO_CustomerSyncMapping mappingSync;

    /**
     * @description Class Constructor to initialize Mapping
     */
    public COMM_TW_Contact_CustomerSyncWithCommerce() {
        this.mappingSync = new COMM_DO_CustomerSyncMapping();
    }

    @TestVisible
    private COMM_TW_Contact_CustomerSyncWithCommerce(COMM_IDO_CustomerSyncMapping mappingSync) {
        this.mappingSync = mappingSync;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newContactList List with the Contact Records in after context.
     * @param oldContactMap Map with the Contact Records in before context.
     */
    public void execute(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        Set<String> fieldSet = mappingSync.getCoreFieldList(String.valueOf(Contact.sObjectType), false);
        List<COMM_CustomerUpdateRequest__e> customerUpdateRequestList = new List<COMM_CustomerUpdateRequest__e>();
        for (Contact newContact : newContactList) {
            if (newContact.COMM_SetForCommerceIntegration__c) {
                //Verify for each updated Contact if field used in Sync was changed
                for (String fieldName : fieldSet) {
                    //If Synched Field changed update JSON map and jump to next record.
                    if (COMM_GEN_Utility.isChangedField(newContact, oldContactMap.get(newContact.Id), fieldName)) {
                        Map<String, Object> jsonMap = new Map<String, Object>();
                        mappingSync.mapJsonFromSObject(newContact, jsonMap, false);
                        newContact.COMM_IntegrationRequestBody__c = JSON.serialize(jsonMap);
                        //Generate Event to send Update Call to Commerce
                        COMM_CustomerUpdateRequest__e event = new COMM_CustomerUpdateRequest__e();
                        event.COMM_ContactId__c = newContact.Id;
                        customerUpdateRequestList.add(event);
                        break;
                    }
                }
            }
        }
        if (!customerUpdateRequestList.isEmpty()) {
            EventBus.publish(customerUpdateRequestList);
        }
    }
}