/**
 * @author Carlos Fusco
 * @description Service for Public Subscription Creation on Invoice paid.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer          Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco     10/06/2024       Original version
 **/
public with sharing class COMM_SL_PublicSubscriptionCreation {
    private static final Map<String, String> AIRPORT_DEFINITION = COMM_GEN_Utility.getPicklistMap(Schema.Product2.COMM_Airport__c, false);
    private static final List<String> PRODUCT_FAMILIES = new List<String>{ COMM_DO_Product2.CATEGORY_CARD, COMM_DO_Product2.CATEGORY_SUBSCRIPTION };
    private static final String ENTITY_ITEM_TYPE = 'Order Product';
    private static COMM_IREP_Group groupRep = new COMM_REP_Group();
    private static COMM_IREP_Subscription subsriptionRep = new COMM_REP_Subscription();
    private static COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();
    private static COMM_IREP_InvoiceLine invoiceLineRep = new COMM_REP_InvoiceLine();
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    private static COMM_IREP_Capacity capacityRep = new COMM_REP_Capacity();
    private static Boolean isRecurring = false;

    /**
     * @description invocable method to handle Public Subscription and related Case creation for paid processed invoices.
     * @param invoiceIdsList List of invoice identifiers to process.
     */
    @InvocableMethod(label='Create Public Subscription' description='Create Public Subscription and related Case on Invoice paid.')
    public static void createPublicSubscription(List<Id> invoiceIdsList) {
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap = new Map<String, OrderItemSummary>();
        Map<String, OrderItemSummary> cardByAirportMap = new Map<String, OrderItemSummary>();
        Map<Id, OrderSummary> orderSummaryByIdMap = new Map<Id, OrderSummary>();
        Map<String, List<COMM_Subscription__c>> subscriptionsByAirportMap = new Map<String, List<COMM_Subscription__c>>();
        Map<Id, OrderItemSummary> orderItemSummaryByIdMap = new Map<Id, OrderItemSummary>(getOrderItemSummary(invoiceIdsList));
        Map<String, Set<String>> productSetByParentProductIdMap = new Map<String, Set<String>>();

        if (orderItemSummaryByIdMap.isEmpty()) {
            return;
        }

        for (OrderItemSummary orderItemSummary : orderItemSummaryByIdMap.values()) {
            if (orderItemSummary.Product2.Family == COMM_DO_Product2.CATEGORY_SUBSCRIPTION) {
                if (String.isBlank(orderItemSummary.COMM_SubscriptionNumber__c)) {
                    COMM_Subscription__c subscriptionToCreate = COMM_DO_Subscription.setSubscriptionToCreate(orderItemSummary);
                    if (!subscriptionsByAirportMap.containsKey(AIRPORT_DEFINITION.get(orderItemSummary.Product2.COMM_Airport__c))) {
                        subscriptionsByAirportMap.put(
                            AIRPORT_DEFINITION.get(orderItemSummary.Product2.COMM_Airport__c),
                            new List<COMM_Subscription__c>()
                        );
                    }
                    subscriptionsByAirportMap.get(AIRPORT_DEFINITION.get(orderItemSummary.Product2.COMM_Airport__c)).add(subscriptionToCreate);
                    if(!productSetByParentProductIdMap.containsKey(orderItemSummary.Product2.COMM_ParentProduct__c)){
                        productSetByParentProductIdMap.put(orderItemSummary.Product2.COMM_ParentProduct__c, new Set<String>());
                    }
                    productSetByParentProductIdMap.get(orderItemSummary.Product2.COMM_ParentProduct__c).add(orderItemSummary.Product2Id);
                } else {
                    isRecurring = true;
                    oItemSummaryBySubscriptionNbrMap.put(orderItemSummary.COMM_SubscriptionNumber__c, orderItemSummary);
                }
                orderSummaryByIdMap.put(orderItemSummary.OrderSummaryId, orderItemSummary.OrderSummary);
            } else if (orderItemSummary.Product2.Family == COMM_DO_Product2.CATEGORY_CARD) {
                cardByAirportMap.put(AIRPORT_DEFINITION.get(orderItemSummary.Product2.COMM_Airport__c), orderItemSummary);
            }
        }

        handleSubscriptionAndCaseCreationUpdate(subscriptionsByAirportMap, cardByAirportMap, oItemSummaryBySubscriptionNbrMap, orderSummaryByIdMap, productSetByParentProductIdMap);
    }

    /**
     * @description Get list of Order Item Summary related on a paid Invoice.
     * @param invoiceIdsList List of invoice identifiers to process.
     * @return List of Order Item Summary to process.
     */
    private static List<OrderItemSummary> getOrderItemSummary(List<Id> invoiceIdsList) {
        Map<Id, Invoice> invoiceByIdMap = new Map<Id, Invoice>();
        List<InvoiceLine> invoiceLineList = new List<InvoiceLine>();
        Set<String> orderItemSummaryIdSet = new Set<String>();
        List<OrderItemSummary> orderItemSummaryList = new List<OrderItemSummary>();

        if (invoiceIdsList.isEmpty() || invoiceIdsList == null) {
            return new List<OrderItemSummary>();
        }

        invoiceByIdMap = new Map<Id, Invoice>(invoiceRep.getByIds(invoiceIdsList));

        if (invoiceByIdMap.isEmpty()) {
            return new List<OrderItemSummary>();
        }

        invoiceLineList = invoiceLineRep.getInvoiceLinesByFamilyAndType(invoiceIdsList, PRODUCT_FAMILIES, ENTITY_ITEM_TYPE);

        if (invoiceLineList.isEmpty()) {
            return new List<OrderItemSummary>();
        }

        for (InvoiceLine invoiceLine : invoiceLineList) {
            orderItemSummaryIdSet.add(invoiceLine.ReferenceEntityItemId);
        }

        if (orderItemSummaryIdSet == null) {
            return new List<OrderItemSummary>();
        }

        orderItemSummaryList = orderItemSummaryRep.getOrderItemSummariesById(new List<String>(orderItemSummaryIdSet));

        return orderItemSummaryList;
    }

    /**
     * @description Define List of Subscription records to be created.
     * @param subscriptionsByAirportMap Subscription records by airport definition.
     * @param cardByAirportMap Card product record by airport definition.
     * @return List of Subscription records to be created.
     */
    private static List<COMM_Subscription__c> setSubscriptionsToCreate(
        Map<String, List<COMM_Subscription__c>> subscriptionsByAirportMap,
        Map<String, OrderItemSummary> cardByAirportMap
    ) {
        List<COMM_Subscription__c> subscriptionsToCreateList = new List<COMM_Subscription__c>();

        for (String subscriptionAirport : subscriptionsByAirportMap.keySet()) {
            List<COMM_Subscription__c> subscriptionList = new List<COMM_Subscription__c>();
            if (cardByAirportMap.containsKey(subscriptionAirport)) {
                subscriptionList = subscriptionsByAirportMap.get(subscriptionAirport);
                for (COMM_Subscription__c subscription : subscriptionList) {
                    subscription.COMM_Card__c = cardByAirportMap.get(subscriptionAirport).Product2.Id;
                    subscriptionsToCreateList.add(subscription);
                }
            } else {
                subscriptionsToCreateList.addAll(subscriptionsByAirportMap.get(subscriptionAirport));
            }
        }

        return subscriptionsToCreateList;
    }

    /**
     * @description Define List of Case records to be created.
     * @param subscriptionsToCreateList Subscription records to be created.
     * @param subscriptionsByAirportMap Subscription records by airport definition.
     * @param cardByAirportMap Card product record by airport definition.
     * @param orderSummaryByIdMap Order Summary record by identifier.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<Case> setCasesToCreate(
        List<COMM_Subscription__c> subscriptionsToCreateList,
        Map<String, OrderItemSummary> cardByAirportMap,
        Map<Id, OrderSummary> orderSummaryByIdMap,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap
    ) {
        List<Case> casesToCreateList = new List<Case>();
        Group sabaQueue = groupRep.getQueueIdByDeveloperName(COMM_DO_Group.QUEUE_NAME_SUBSCRIPTION_SABA, true).get(0);

        for (COMM_Subscription__c subscription : subscriptionsToCreateList) {
            Case caseToCreate = COMM_DO_Case.setCaseToCreate(
                subscription,
                cardByAirportMap,
                orderSummaryByIdMap,
                oItemSummaryBySubscriptionNbrMap,
                isRecurring,
                sabaQueue
            );
            casesToCreateList.add(caseToCreate);
        }

        return casesToCreateList;
    }

    /**
     * @description Handle Subscription and related Case records creation and updates.
     * @param subscriptionsByAirportMap Subscription records by airport definition.
     * @param cardByAirportMap Card product record by airport definition.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary record by subscription number.
     * @param orderSummaryByIdMap Order Summary record by identifier.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void handleSubscriptionAndCaseCreationUpdate(
        Map<String, List<COMM_Subscription__c>> subscriptionsByAirportMap,
        Map<String, OrderItemSummary> cardByAirportMap,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Map<Id, OrderSummary> orderSummaryByIdMap,
        Map<String, Set<String>> productSetByParentProductIdMap
    ) {
        FW_ISObjectRep sObjectRep = new FW_SObjectRep();
        Set<Id> createdCaseIdsSet = new Set<Id>();

        List<COMM_Subscription__c> subscriptionsToCreateList = setSubscriptionsToCreate(subscriptionsByAirportMap, cardByAirportMap);

        setSubscriptionOCIEndateRequest(subscriptionsToCreateList, productSetByParentProductIdMap);

        try {
            sObjectRep.insertSObjects(subscriptionsToCreateList);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(
                e,
                'Public Subscription creation handleSubscriptionAndCaseCreationUpdate error',
                'COMM_SL_PublicSubscriptionCreation'
            );
        }

        List<Case> casesToCreate = setCasesToCreate(
            subscriptionsToCreateList,
            cardByAirportMap,
            orderSummaryByIdMap,
            new Map<String, OrderItemSummary>()
        );

        List<COMM_Subscription__c> existingSubscriptionList = subsriptionRep.getSubscriptionsById(oItemSummaryBySubscriptionNbrMap.keySet());

        if (!existingSubscriptionList.isEmpty()) {
            casesToCreate.addAll(setCasesToCreate(existingSubscriptionList, cardByAirportMap, orderSummaryByIdMap, oItemSummaryBySubscriptionNbrMap));
        }

        try {
            sObjectRep.insertSObjects(casesToCreate);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(
                e,
                'Public Subscription Case creation handleSubscriptionAndCaseCreationUpdate error',
                'COMM_SL_PublicSubscriptionCreation'
            );
        }

        for (Case currentCase : casesToCreate) {
            createdCaseIdsSet.add(currentCase.Id);
        }

        Map<Id, COMM_Subscription__c> subscriptionByIdMap = new Map<Id, COMM_Subscription__c>(subscriptionsToCreateList);

        if (!existingSubscriptionList.isEmpty()) {
            Map<Id, COMM_Subscription__c> existingSubscriptionByIdMap = new Map<Id, COMM_Subscription__c>(existingSubscriptionList);
            subscriptionByIdMap.putAll(existingSubscriptionByIdMap);
        }

        List<COMM_Subscription__c> subscriptionsToUpdateList = setSubscriptionActiveRequest(casesToCreate, subscriptionByIdMap);
        try {
            sObjectRep.updateSObjects(subscriptionsToUpdateList);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(
                e,
                'Public Subscription update handleSubscriptionAndCaseCreationUpdate error',
                'COMM_SL_PublicSubscriptionCreation'
            );
        }
    }

    /**
     * @description Update Subscription with last active Public Subscription request represented by a Case.
     * @param casesToCreateList List of Case records.
     * @param subscriptionByIdMap Subscription records to update.
     */
    private static List<COMM_Subscription__c> setSubscriptionActiveRequest(
        List<Case> casesToCreateList,
        Map<Id, COMM_Subscription__c> subscriptionByIdMap
    ) {
        List<COMM_Subscription__c> subscriptionsToUpdateList = new List<COMM_Subscription__c>();

        for (Case currentCase : casesToCreateList) {
            if (subscriptionByIdMap.containsKey(currentCase.COMM_Subscription__c)) {
                subscriptionByIdMap.get(currentCase.COMM_Subscription__c).COMM_ActiveSubscriptionRequest__c = currentCase.Id;
                if (
                    currentCase.RecordTypeId ==
                    Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(COMM_DO_Case.RECURRING_PUBLIC_SUBSCRIPTION_REQUEST_RT)
                        .RecordTypeId
                ) {
                    subscriptionByIdMap.get(currentCase.COMM_Subscription__c).COMM_EndDate__c = currentCase.COMM_EndDate__c;
                }
                subscriptionsToUpdateList.add(subscriptionByIdMap.get(currentCase.COMM_Subscription__c));
            }
        }

        return subscriptionsToUpdateList;
    }

    /**
     * @description Update Subscription OCI End Date and generate stock for the remaining Capacity Valid To Date.
     * @param subscriptionsToCreateList List of Subscription records.
     * @param productSetByParentProductIdMap Map of Child ProductId by Parent Product Id.
     */
    private static void setSubscriptionOCIEndateRequest(
        List<COMM_Subscription__c> subscriptionsToCreateList,
        Map<String, Set<String>> productSetByParentProductIdMap
    ) {
        Map<String, String> parentProductCodeByProductId = new Map<String, String>();
        List<COMM_Capacity__c> capacityList = capacityRep.getCapacityByProductIds(productSetByParentProductIdMap.keySet());
        for(COMM_Subscription__c subscriptionRecord : subscriptionsToCreateList){
            for(COMM_Capacity__c capacityRecord : capacityList){
                if(productSetByParentProductIdMap.get(capacityRecord.COMM_Product__c).contains(subscriptionRecord.COMM_Product__c)){
                    subscriptionRecord.COMM_OCIEndDate__c = capacityRecord.COMM_ValidTo__c.date();
                    parentProductCodeByProductId.put(subscriptionRecord.COMM_Product__c, capacityRecord.COMM_Product__r.ProductCode);
                }
            }
        }
        if(!parentProductCodeByProductId.isEmpty()){
            COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
            input.expirationSeconds = 0;
            input.product = new List<COMM_WS_ReservationInput.Product>();
            for (COMM_Subscription__c subscriptionRecord : subscriptionsToCreateList) {
                COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
                product.productId = parentProductCodeByProductId.get(subscriptionRecord.COMM_Product__c);
                product.startDate = COMM_GEN_Utility.generateDateTimeDataType(subscriptionRecord.COMM_EndDate__c).addDays(1);
                product.endDate = COMM_GEN_Utility.generateDateTimeDataType(subscriptionRecord.COMM_OCIEndDate__c);
                input.product.add(product);
            }
            COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
            ociReservation.reserve(input, false);
        }
    }
}