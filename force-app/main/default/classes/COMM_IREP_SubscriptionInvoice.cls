/**
 * @author Daniel Lascas
 * @description COMM_SubscriptionInvoice__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024       ECOMM-194: Original version
 **/
public interface COMM_IREP_SubscriptionInvoice extends FW_ISObjectRep {
    /**
     * @description Retrieve the list of Subscription Invoice Records by a Set of Ids
     *
     * @param invoiceIds Set of Subscription Invoice Ids to query invoices
     * @return List of Subscription Invoice Records found
     **/
    List<COMM_SubscriptionInvoice__c> getSubInvoiceByIds(Set<Id> invoiceIds);
}