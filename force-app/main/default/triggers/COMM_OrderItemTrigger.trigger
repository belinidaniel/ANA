/**
 * @author Daniel Reto
 * @description Trigger for the OrderItem sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/08/2024		ECOMM-1945: Timezones
 **/
trigger COMM_OrderItemTrigger on OrderItem (before insert, before update) {
    new COMM_TH_OrderItem().execute();
}