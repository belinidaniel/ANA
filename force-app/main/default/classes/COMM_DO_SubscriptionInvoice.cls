/**
 * @author Daniel Lascas
 * @description SubscriptionInvoice__c SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_DO_SubscriptionInvoice implements COMM_IDO_SubscriptionInvoice {
    public final static String PENDING_STATUS = 'Pending';
    public final static String GENERATED_STATUS = 'Generated';
}