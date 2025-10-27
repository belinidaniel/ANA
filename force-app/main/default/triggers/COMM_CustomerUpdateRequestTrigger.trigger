/**
 * @author Daniel Lascas
 * @description Trigger for the COMM_CustomerUpdateRequest__e platform event
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/09/2024	    Original version
 **/
trigger COMM_CustomerUpdateRequestTrigger on COMM_CustomerUpdateRequest__e(after insert) {
    new COMM_TH_CustomerUpdateRequest().execute();
}