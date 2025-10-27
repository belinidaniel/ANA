/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the multi-picklist COMM_Airport__c
 * was changed. If it was copy value to COMM_AirportTextList__c to update sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
public with sharing class COMM_TW_Subscription_AirportUpdate {
    private COMM_IREP_Product2 productRep;

    public COMM_TW_Subscription_AirportUpdate() {
        this.productRep = new COMM_REP_Product2();
    }

    @TestVisible
    private COMM_TW_Subscription_AirportUpdate(COMM_IREP_Product2 productRep) {
        this.productRep = productRep;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newSubsList List with the COMM_Subscription__c Records in after context.
     * @param oldSubsMap Map with the COMM_Subscription__c Records in before context.
     */
    public void execute(List<COMM_Subscription__c> newSubsList, Map<Id, COMM_Subscription__c> oldSubsMap) {
        Map<Id, List<COMM_Subscription__c>> subscriptionWithProductIdMap = new Map<Id, List<COMM_Subscription__c>>();
        for (COMM_Subscription__c newSubscription : newSubsList) {
            //Verify if Product was changed or Airport field is empty while Subscription has Product
            if (
                (newSubscription.COMM_Airport__c == null && newSubscription.COMM_Product__c != null) ||
                COMM_GEN_Utility.isChangedField(newSubscription, oldSubsMap, COMM_Subscription__c.COMM_Product__c)
            ) {
                if (!subscriptionWithProductIdMap.containsKey(newSubscription.COMM_Product__c)) {
                    subscriptionWithProductIdMap.put(newSubscription.COMM_Product__c, new List<COMM_Subscription__c>());
                }
                subscriptionWithProductIdMap.get(newSubscription.COMM_Product__c).add(newSubscription);
            }
        }
        if (!subscriptionWithProductIdMap.isEmpty()) {
            for (Product2 productRecord : productRep.getProductsByIds(subscriptionWithProductIdMap.keySet())) {
                //Copy Product Airport Field to Subscription
                for (COMM_Subscription__c subRecord : subscriptionWithProductIdMap.get(productRecord.Id)) {
                    subRecord.COMM_AirportValue__c = productRecord.COMM_Airport__c;
                }
            }
        }
    }
}