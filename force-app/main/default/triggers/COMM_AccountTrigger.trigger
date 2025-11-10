/**
 * @author Daniel Lascas
 * @description Trigger for the Account sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024	    ECOMM-194: Original version
 **/
trigger COMM_AccountTrigger on Account(before insert, before update) {
    new COMM_TH_Account().execute();
}