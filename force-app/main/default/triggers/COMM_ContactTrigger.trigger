/**
 * @author Daniel Lascas
 * @description Trigger for the Contact sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024	    ECOMM-194: Original version
 **/
trigger COMM_ContactTrigger on Contact(before update, before insert) {
    new COMM_TH_Contact().execute();
}