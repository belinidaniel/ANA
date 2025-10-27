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
 * Daniel Lascas    28/03/2024		ECOMM-370: Original version
 **/
public class COMM_TW_Account_CustomerSyncWithCommerce {
    private COMM_IDO_CustomerSyncMapping mappingSync;

    /**
     * @description Class Constructor to initialize Mapping
     */
    public COMM_TW_Account_CustomerSyncWithCommerce() {
        this.mappingSync = new COMM_DO_CustomerSyncMapping();
    }

    @TestVisible
    private COMM_TW_Account_CustomerSyncWithCommerce(COMM_IDO_CustomerSyncMapping mappingSync) {
        this.mappingSync = mappingSync;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newAccountList List with the Account Records in after context.
     * @param oldAccountMap Map with the Account Records in before context.
     */
    public void execute(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        List<COMM_CustomerUpdateRequest__e> customerUpdateRequestList = new List<COMM_CustomerUpdateRequest__e>();
        for (Account newAcc : newAccountList) {
            verifyAccountSync(newAcc, oldAccountMap, customerUpdateRequestList);
        }
        if (!customerUpdateRequestList.isEmpty()) {
            EventBus.publish(customerUpdateRequestList);
        }
    }

    /**
     * @description Verify if Account required synching with Commerce. If it does generate request JSON
     * and platform event to send update callouts.
     *
     * @param newAcc Account Record with new data.
     * @param oldAccountMap Map with Account Data before current update.
     * @param customerUpdateRequestList List were Update Events are to be stored.
     */
    private void verifyAccountSync(Account newAcc, Map<Id, Account> oldAccountMap, List<COMM_CustomerUpdateRequest__e> customerUpdateRequestList) {
        if (newAcc.IsPersonAccount || newAcc.COMM_IsAffiliate__c) {
            Set<String> fieldSet = mappingSync.getCoreFieldList(String.valueOf(Account.sObjectType), newAcc.IsPersonAccount);
            //Verify for each updated Account if field used in Sync was changed
            for (String fieldName : fieldSet) {
                //If Synched Field changed update JSON map and jump to next record.
                if (COMM_GEN_Utility.isChangedField(newAcc, oldAccountMap.get(newAcc.Id), fieldName)) {
                    Map<String, Object> jsonMap = new Map<String, Object>();
                    mappingSync.mapJsonFromSObject(newAcc, jsonMap, newAcc.IsPersonAccount);
                    newAcc.COMM_IntegrationRequestBody__c = JSON.serialize(jsonMap);

                    //Generate Event to send Update Call to Commerce
                    COMM_CustomerUpdateRequest__e event = new COMM_CustomerUpdateRequest__e();
                    event.COMM_AccountId__c = newAcc.Id;
                    customerUpdateRequestList.add(event);
                    break;
                }
            }
        }
    }
}