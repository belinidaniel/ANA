/**
 * @author Daniel Reto
 * @description Trigger handler for the OrderItem sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/08/2024		ECOMM-1945: Timezones
 **/
public class COMM_TH_OrderItem extends FW_TriggerHandler {
    private List<OrderItem> newList;
    private Map<Id, OrderItem> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_OrderItem() {
        this.newList = (List<OrderItem>) Trigger.new;
        this.oldMap = (Map<Id, OrderItem>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to update Airport Field
        new COMM_TW_OrderItem_SetReservationDates().execute(newList, null);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to update Airport Field
        new COMM_TW_OrderItem_SetReservationDates().execute(newList, oldMap);
    }
}