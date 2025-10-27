/**
 * @author Daniel Lascas
 * @description Trigger for the COMM_Subscription__c sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
trigger COMM_SubscriptionTrigger on COMM_Subscription__c(before insert, before update) {
    new COMM_TH_Subscription().execute();
}