/**
 * @author Daniel Lascas
 * @description Trigger worker that generates a SubscriptionInvoice__c record for
 * each Case that generated the Event.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024		ECOMM-194: Original version
 * Daniel Reto      03/05/2024		ECOMM-1027
 **/
public class COMM_TW_SubInvGen_GenerateInvoice {
    private COMM_IREP_Case caseRep;
    private COMM_IREP_Subscription subscriptionRep;
    private COMM_IREP_SubscriptionInvoice subInvoiceRep;

    /**
     * @description Class Constructor to initiate REP Classes.
     */
    public COMM_TW_SubInvGen_GenerateInvoice() {
        this.caseRep = new COMM_REP_Case();
        this.subscriptionRep = new COMM_REP_Subscription();
        this.subInvoiceRep = new COMM_REP_SubscriptionInvoice();
    }

    @TestVisible
    private COMM_TW_SubInvGen_GenerateInvoice(
        COMM_IREP_Case caseRep,
        COMM_IREP_Subscription subscriptionRep,
        COMM_IREP_SubscriptionInvoice subInvoiceRep
    ) {
        this.caseRep = caseRep;
        this.subscriptionRep = subscriptionRep;
        this.subInvoiceRep = subInvoiceRep;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param eventList List with the Platform Event Records that were published.
     */
    public void execute(List<COMM_SubscriptionInvoiceGenerator__e> pEventList) {
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> subscriptionIdSet = new Set<Id>();
        for (COMM_SubscriptionInvoiceGenerator__e pEvent : pEventList) {
            if (!String.isBlank(pEvent.COMM_CaseId__c)) {
                caseIdSet.add(pEvent.COMM_CaseId__c);
            }
            if (!String.isBlank(pEvent.COMM_SubscriptionId__c)) {
                subscriptionIdSet.add(pEvent.COMM_SubscriptionId__c);
            }
        }
        List<COMM_SubscriptionInvoice__c> generatedInvoiceList = new List<COMM_SubscriptionInvoice__c>();
        Map<Id, List<COMM_SubscriptionInvoice__c>> invoiceWithNewCardMap = new Map<Id, List<COMM_SubscriptionInvoice__c>>();
        if (!caseIdSet.isEmpty()) {
            for (Case caseRecord : caseRep.getSubscriptionCaseByIds(caseIdSet, false)) {
                COMM_SubscriptionInvoice__c invoice = new COMM_SubscriptionInvoice__c();
                invoice.COMM_Status__c = COMM_DO_SubscriptionInvoice.PENDING_STATUS;
                invoice.COMM_SubscriptonRequest__c = caseRecord.Id;
                invoice.COMM_Account__c = caseRecord.AccountId;
                invoice.COMM_CardProduct__c = caseRecord.COMM_Card__c;
                invoice.COMM_Subscripton__c = caseRecord.COMM_Subscription__c;
                // Do not fill in subscription price when just making new card/changing owner
                if (
                    !caseRecord.RecordType.DeveloperName.equals(COMM_DO_Case.CHANGE_OWNERSHIP_RT) &&
                    !caseRecord.RecordType.DeveloperName.equals(COMM_DO_Case.NEW_CARD_RT)
                ) {
                    invoice.COMM_SubscriptonProduct__c = caseRecord.ProductId;
                    invoice.COMM_SubscriptionAmount__c = caseRecord.COMM_SubscriptionPrice__c;
                }
                invoice.COMM_CardAmount__c = caseRecord.COMM_CardPrice__c;
                generatedInvoiceList.add(invoice);
            }
        }
        if (!subscriptionIdSet.isEmpty()) {
            for (COMM_Subscription__c subscriptionRecord : subscriptionRep.getSubscriptionsByIds(subscriptionIdSet)) {
                COMM_SubscriptionInvoice__c invoice = new COMM_SubscriptionInvoice__c();
                invoice.COMM_Status__c = COMM_DO_SubscriptionInvoice.PENDING_STATUS;
                invoice.COMM_Account__c = subscriptionRecord.COMM_Account__c;
                invoice.COMM_Subscripton__c = subscriptionRecord.Id;
                invoice.COMM_SubscriptonProduct__c = subscriptionRecord.COMM_Product__c;
                invoice.COMM_SubscriptionAmount__c = subscriptionRecord.COMM_Price__c;
                generatedInvoiceList.add(invoice);
            }
        }

        if (!generatedInvoiceList.isEmpty()) {
            subInvoiceRep.insertSObjects(generatedInvoiceList);
        }
    }
}