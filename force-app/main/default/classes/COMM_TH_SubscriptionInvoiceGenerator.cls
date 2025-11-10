/**
 * @author Daniel Lascas
 * @description Trigger handler for the COMM_SubscriptionInvoiceGenerator__e
 * platform event
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    28/03/2024	    ECOMM-194: Original version
 **/
public class COMM_TH_SubscriptionInvoiceGenerator extends FW_TriggerHandler {
    private List<COMM_SubscriptionInvoiceGenerator__e> newList;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_SubscriptionInvoiceGenerator() {
        this.newList = (List<COMM_SubscriptionInvoiceGenerator__e>) Trigger.New;
    }

    protected override void executeAfterInsert() {
        //Execute Logic to generate a Subscription Invoice Record
        new COMM_TW_SubInvGen_GenerateInvoice().execute(newList);
    }
}