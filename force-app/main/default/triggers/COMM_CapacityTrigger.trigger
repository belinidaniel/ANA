/**
 * @author			Daniel Lascas
 * @description		Trigger for the COMM_Capacity__c sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024	    Original version
 **/
trigger COMM_CapacityTrigger on COMM_Capacity__c(before insert, before update, before delete) {
    new COMM_TH_Capacity().execute();
}