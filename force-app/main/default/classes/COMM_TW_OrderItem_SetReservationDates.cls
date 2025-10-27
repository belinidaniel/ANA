/**
 * @author Daniel Reto
 * @description Trigger worker that verifies reservation string dates sent by commerce
 * and updates the reservation dates accordingly.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/08/2024		ECOMM-1945: Timezones
 **/
public with sharing class COMM_TW_OrderItem_SetReservationDates {
    private COMM_IREP_Product2 productRep;

    public COMM_TW_OrderItem_SetReservationDates() {
        this.productRep = new COMM_REP_Product2();
    }

    @TestVisible
    private COMM_TW_OrderItem_SetReservationDates(COMM_IREP_Product2 productRep) {
        this.productRep = productRep;
    }

    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newOrderItemList List with the Order Item Records in after context.
     * @param oldOrderItemMap Map with the Order Item Records in before context.
     */
    public void execute(List<OrderItem> newOrderItemList, Map<Id, OrderItem> oldOrderItemMap) {
        Set<Id> productIdSet = new Set<Id>();
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        if(oldOrderItemMap == null){
            for(OrderItem orderItemRecord : newOrderItemList){
                productIdSet.add(orderItemRecord.Product2Id);
            }
        } else {
            for(OrderItem orderItemRecord : newOrderItemList){
                if(orderItemRecord.COMM_ReservationStartStr__c != oldOrderItemMap.get(orderItemRecord.Id).COMM_ReservationStartStr__c
                || orderItemRecord.COMM_ReservationEndStr__c != oldOrderItemMap.get(orderItemRecord.Id).COMM_ReservationEndStr__c){
                    productIdSet.add(orderItemRecord.Product2Id);
                }
            }
        }

        if(!productIdSet.isEmpty()){
            // Map product records related with Order items to update
            List<Product2> productList = productRep.getProductsByIds(productIdSet);
            Map<Id,Product2> productByIdMap = new Map<Id,Product2>();
            productByIdMap.putAll(productList);
            // get current user offset to add on Reservation dates, with this we will get always datetime with GMT+0
            TimeZone usertz = UserInfo.getTimeZone();
            Integer offSetUser = usertz.getOffSet(DateTime.now())/1000;

            for(OrderItem orderItemRecord : newOrderItemList){
                if(oldOrderItemMap != null
                && orderItemRecord.COMM_ReservationStartStr__c == oldOrderItemMap.get(orderItemRecord.Id).COMM_ReservationStartStr__c
                && orderItemRecord.COMM_ReservationEndStr__c == oldOrderItemMap.get(orderItemRecord.Id).COMM_ReservationEndStr__c){
                    continue;
                }
                if(orderItemRecord.COMM_ReservationStartStr__c == null || orderItemRecord.COMM_ReservationEndStr__c == null){
                    continue;
                }
                TimeZone tz = TimeZone.getTimeZone(productByIdMap.get(orderItemRecord.Product2Id).COMM_TimeZoneByAirport__c);
                Integer offSet = tz.getOffSet(DateTime.now())/1000;
                orderItemRecord.COMM_ReservationStart__c = DateTime.valueOf(orderItemRecord.COMM_ReservationStartStr__c).addSeconds(-offSet).addSeconds(offSetUser);
                orderItemRecord.COMM_ReservationEnd__c = DateTime.valueOf(orderItemRecord.COMM_ReservationEndStr__c).addSeconds(-offSet).addSeconds(offSetUser);
            }
        }
    }
}