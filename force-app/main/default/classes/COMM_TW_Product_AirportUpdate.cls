/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the picklist COMM_Airport__c
 * was changed. If it was update airport field in all related subscriptions
 * in order to update sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
public with sharing class COMM_TW_Product_AirportUpdate {
    private COMM_IREP_Subscription subscriptionRep;

    /**
     * @description Class constructor to initialize REP
     */
    public COMM_TW_Product_AirportUpdate() {
        this.subscriptionRep = new COMM_REP_Subscription();
    }

    @TestVisible
    private COMM_TW_Product_AirportUpdate(COMM_IREP_Subscription subscriptionRep) {
        this.subscriptionRep = subscriptionRep;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newProductList List with the Product2 Records in after context.
     * @param oldProductMap Map with the Product2 Records in before context.
     */
    public void execute(List<Product2> newProductList, Map<Id, Product2> oldProductMap) {
        Map<Id, String> airportUpdateValueMap = new Map<Id, String>();

        for (Product2 newProduct : newProductList) {
            //Verify Airport Field Changed
            if (
                COMM_GEN_Utility.isChangedField(newProduct, oldProductMap, Product2.COMM_Airport__c) &&
                COMM_DO_Product2.CATEGORY_SUBSCRIPTION.equals(newProduct.Family)
            ) {
                airportUpdateValueMap.put(newProduct.Id, newProduct.COMM_Airport__c);
            }
        }

        if (!airportUpdateValueMap.isEmpty()) {
            List<COMM_Subscription__c> subsUpdateList = new List<COMM_Subscription__c>();
            //Verify Related Subscriptions and set them to update airport field
            for (COMM_Subscription__c subRecord : subscriptionRep.getSubscriptionsByProductIds(airportUpdateValueMap.keySet())) {
                subRecord.COMM_AirportValue__c = airportUpdateValueMap.get(subRecord.COMM_Product__c);
                subsUpdateList.add(subRecord);
            }
            if (!subsUpdateList.isEmpty()) {
                subscriptionRep.updateSObjects(subsUpdateList);
            }
        }
    }
}