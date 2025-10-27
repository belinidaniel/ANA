/**
 * @author Daniel Lascas
 * @description Trigger for the User sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024	    ECOMM-700: Original version
 **/
trigger COMM_UserTrigger on User(after insert, after update) {
    new COMM_TH_User().execute();
}