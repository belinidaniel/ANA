/**
 * @author Carlos Fusco
 * @description Trigger handler for the Product2 sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/02/2024	    Original version
 **/
public with sharing class COMM_TH_Product extends FW_TriggerHandler {
    private List<Product2> newList;
    private Map<Id, Product2> oldMap;

    /**
     * @description Runs before the trigger handler is executed
     */
    public COMM_TH_Product() {
        this.newList = (List<Product2>) Trigger.New;
        this.oldMap = (Map<Id, Product2>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        new COMM_TW_Product_SetProductForIntegration().execute(newList, oldMap);
    }

    protected override void executeBeforeUpdate() {
        new COMM_TW_Product_SetProductForIntegration().execute(newList, oldMap);
    }

    protected override void executeAfterUpdate() {
        new COMM_TW_Product_AirportUpdate().execute(newList, oldMap);
    }
}