/**
 * @author Daniel Lascas
 * @description Trigger handler for the Case sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024	    Original version
 * Daniel Lascas    25/03/2024	    ECOMM-194: Added after update worker
 * Daniel Lascas    11/07/2024		ECOMM-1602: Added airport update worker
 * Daniel Reto	    23/07/2024	    ECOMM-1818: COMM_TW_Case_FillContactFromSuppliedName added
 **/
public class COMM_TH_Case extends FW_TriggerHandler {
    private List<Case> newList;
    private Map<Id, Case> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_Case() {
        this.newList = (List<Case>) Trigger.New;
        this.oldMap = (Map<Id, Case>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to ensure that the language is a value used by the picklist
        new COMM_TW_Case_VerifyLanguage().execute(newList);
        //Execute Logic to fill Contact Id on Affiliate Request
        new COMM_TW_Case_FillContactFromSuppliedName().execute(newList);
        //Execute Logic to update Airport Field
        new COMM_TW_Case_AirportUpdate().execute(newList, null);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to update Airport Field
        new COMM_TW_Case_AirportUpdate().execute(newList, null);
    }

    protected override void executeAfterUpdate() {
        //Execute Logic to generate a Subscription Invoice when a Subscription Case is Concluded
        new COMM_TW_Case_GenerateInvoice().execute(newList, oldMap);
    }
}