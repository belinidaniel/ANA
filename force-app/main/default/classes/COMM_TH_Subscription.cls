/**
 * @author Daniel Lascas
 * @description Trigger handler for the COMM_Subscription__c sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
public class COMM_TH_Subscription extends FW_TriggerHandler {
    private List<COMM_Subscription__c> newList;
    private Map<Id, COMM_Subscription__c> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_Subscription() {
        this.newList = (List<COMM_Subscription__c>) Trigger.New;
        this.oldMap = (Map<Id, COMM_Subscription__c>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to update Airport Field
        new COMM_TW_Subscription_AirportUpdate().execute(newList, null);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to update Airport Field
        new COMM_TW_Subscription_AirportUpdate().execute(newList, oldMap);
    }
}