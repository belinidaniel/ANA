/**
 * @author Daniel Lascas
 * @description Trigger for the Case sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024      Original version
 **/
trigger COMM_CaseTrigger on Case(before insert, before update, after update) {
    new COMM_TH_Case().execute();
}