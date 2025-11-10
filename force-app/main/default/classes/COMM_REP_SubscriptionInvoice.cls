/**
 * @author Daniel Lascas
 * @description COMM_SubscriptionInvoice__c repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_REP_SubscriptionInvoice extends FW_SobjectRep implements COMM_IREP_SubscriptionInvoice {
    /**
     * @description Retrieve the list of Subscription Invoice Records by a Set of Ids
     *
     * @param invoiceIds Set of Subscription Invoice Ids to query invoices
     * @return List of Subscription Invoice Records found
     **/
    public List<COMM_SubscriptionInvoice__c> getSubInvoiceByIds(Set<Id> invoiceIds) {
        return [
            SELECT Id, COMM_Status__c, COMM_SAPNumber__c, COMM_IssuanceDate__c
            FROM COMM_SubscriptionInvoice__c
            WHERE Id IN :invoiceIds
            WITH USER_MODE
        ];
    }
}