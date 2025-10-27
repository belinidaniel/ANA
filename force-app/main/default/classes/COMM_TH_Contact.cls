/**
 * @author Daniel Lascas
 * @description Trigger handler for the Contact sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/07/2024	    ECOMM-1637: Original version
 **/
public class COMM_TH_Contact extends FW_TriggerHandler {
    private List<Contact> newList;
    private Map<Id, Contact> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_Contact() {
        this.newList = (List<Contact>) Trigger.New;
        this.oldMap = (Map<Id, Contact>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to update Airport Field
        new COMM_TW_Contact_AirportUpdate().execute(newList, null);
        //Execute Logic to fill Effective Account
        new COMM_TW_Contact_UpdateEffectiveAccount().execute(newList);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to update Airport Field
        new COMM_TW_Contact_AirportUpdate().execute(newList, oldMap);
        //Execute Logic to fill Effective Account if it's empty
        new COMM_TW_Contact_UpdateEffectiveAccount().execute(newList);
        //Execute Logic to sync data with Commerce
        new COMM_TW_Contact_CustomerSyncWithCommerce().execute(newList, oldMap);
    }
}