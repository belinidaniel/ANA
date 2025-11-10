/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the updated case is a Subscription
 * related case and if it was concluded. Publishes a Platform Event to generate a
 * Subscription Invoice.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024		ECOMM-194: Original version
 **/
public class COMM_TW_Case_GenerateInvoice {
    /**
     * @description Execute Trigger Worker Logic
     *
     * @param caseList List with the Case Records that are being created
     */
    public void execute(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Id subscriptionCaseRtId = COMM_GEN_Utility.getRecordTypeIdByDevName(Case.sObjectType, COMM_DO_Case.SUBSCRIPTION_REQUEST_RT);
        List<COMM_SubscriptionInvoiceGenerator__e> pEventList = new List<COMM_SubscriptionInvoiceGenerator__e>();
        for (Case newCase : newCaseList) {
            //Verify that Case Status changed to Process Concluded and Case Record Type is Subscription
            if (
                COMM_GEN_Utility.isChangedField(newCase, oldCaseMap, Case.Status) &&
                COMM_DO_Case.PROCESS_CONCLUDED_STATUS.equals(newCase.Status) &&
                newCase.RecordTypeId == subscriptionCaseRtId
            ) {
                COMM_SubscriptionInvoiceGenerator__e pEvent = new COMM_SubscriptionInvoiceGenerator__e();
                pEvent.COMM_CaseId__c = newCase.Id;
                pEventList.add(pEvent);
            }
        }
        if (!pEventList.isEmpty()) {
            EventBus.publish(pEventList);
        }
    }
}