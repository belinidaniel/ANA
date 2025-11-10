/**
 * @author Daniel Lascas
 * @description Trigger for the COMM_SubscriptionInvoiceGenerator__e platform event
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024	    ECOMM-194: Original version
 **/
trigger COMM_SubscriptionInvoiceGeneratorTrigger on COMM_SubscriptionInvoiceGenerator__e(after insert) {
    new COMM_TH_SubscriptionInvoiceGenerator().execute();
}