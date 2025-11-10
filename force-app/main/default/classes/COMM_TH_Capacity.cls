/**
 * @author Daniel Lascas
 * @description Trigger handler for the COMM_Capacity__c sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024	    Original version
 **/
public class COMM_TH_Capacity extends FW_TriggerHandler {
    private List<COMM_Capacity__c> newList;
    private Map<Id, COMM_Capacity__c> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_Capacity() {
        this.newList = (List<COMM_Capacity__c>) Trigger.New;
        this.oldMap = (Map<Id, COMM_Capacity__c>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to ensure that an active Default Capacity exists for the Products associated with the inserted Capacities
        new COMM_TW_Capacity_VerifyDefaultCapacities().execute(newList, null, false);
        //Execute Logic to ensure inserted non-Default Capacities don't have valid dates that intercect with another non-default Capacity
        new COMM_TW_Capacity_VerifyExistingCapacity().execute(newList, oldMap);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to ensure that an active Default Capacity exists for the Products associated with the updated Capacities
        new COMM_TW_Capacity_VerifyDefaultCapacities().execute(newList, oldMap, false);
        //Execute Logic to ensure updated non-Default Capacities don't have valid dates that intercect with another non-default Capacity
        new COMM_TW_Capacity_VerifyExistingCapacity().execute(newList, oldMap);
    }

    protected override void executeBeforeDelete() {
        //Execute Logic to ensure that a Default Capacity isn't deleted if there are at least one
        //active non-Default Capacity for the Products associated with the deleted Capacities
        new COMM_TW_Capacity_VerifyDefaultCapacities().execute(oldMap.values(), null, true);
    }
}