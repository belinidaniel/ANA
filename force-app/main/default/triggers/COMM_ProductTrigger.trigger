/**
 * @author Carlos Fusco
 * @description Trigger for the Product2 sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer          Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/03/2024	    Original version
 **/
trigger COMM_ProductTrigger on Product2(before insert, before update, after update) {
    new COMM_TH_Product().execute();
}