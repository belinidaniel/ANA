/**
 * @author Daniel Reto
 * @description Class to support the Web Service to cancel an Order from Reseller side.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      05/11/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_CancelResellerOrder {
    private static final String RESELLER_ID = 'resellerId';
    private static final String ORDER_ID = 'orderId';
    private static final String ORDER_ITEMS_ID = 'orderItems';
    private static final String FLOW_PARAM_RETURNED_ORDER_SUMMARY_IDS = 'returnedOrderSummaryId';
    private static final String FLOW_PARAM_RETURNED_ORDER_PRODUCT_SUMMARY_IDS = 'returnedOrderProductSummaryIds';
    /**
     * @description Cancell all Order Item Summaries on input request.
     * @param Map<String,Object> inputRequest - Order data to cancel
     * @return Map<String,Object> output with Order data
     */
    public Map<String, Object> cancelOrder(Map<String, Object> inputRequest) {
        Map<String, Object> outputRequestMap = new Map<String, Object>();
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
        Set<String> orderItemSummarySet = new Set<String>();
        List<String> orderItemSummaryToProcessList = new List<String>();
        Set<String> orderItemSummaryToConfirmSet = new Set<String>();
        Set<String> orderItemReferenceNumberSet = new Set<String>();

        for(Object orderItemReferenceNumber : (List<Object>) inputRequest.get(ORDER_ITEMS_ID)){
            orderItemReferenceNumberSet.add((String) orderItemReferenceNumber);
        }

        // Exceptions
        if (String.isBlank((String) inputRequest.get(RESELLER_ID))) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.BLANK_RESSELER,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BLANK_RESSELER)
            );
        }
        if (String.isBlank((String) inputRequest.get(ORDER_ID))) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.BLANK_ORDER_ID,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BLANK_ORDER_ID)
            );
        }
        if (orderItemReferenceNumberSet.isEmpty()) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.NO_ORDER_ITEMS,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.NO_ORDER_ITEMS)
            );
        }

        List<OrderSummary> orderSummaryList = orderSummaryRep.getOrderSummaryByCOMMSalesforceOrderId((String) inputRequest.get(RESELLER_ID), (String) inputRequest.get(ORDER_ID));

        if (!orderSummaryList.isEmpty()) {
            // adjust returnedOrderProductSummaryIds paramer of COMM_OMS_Cancel_Item flow
            String orderProductSummaryIds = '';
            for (OrderItemSummary orderProductSummaryRecord : orderSummaryList.get(0)?.OrderItemSummaries) {
                if (orderItemReferenceNumberSet.contains(orderProductSummaryRecord.COMM_OrderItemReferenceNumber__c)) {
                    orderItemSummarySet.add(orderProductSummaryRecord.COMM_OrderItemReferenceNumber__c);
                    if (orderProductSummaryRecord.Status != COMM_DO_OrderItemSummary.RETURNED_STATUS) {
                        orderItemSummaryToProcessList.add(orderProductSummaryRecord.Id);
                        orderProductSummaryIds += orderProductSummaryRecord.Id + ',';
                    }
                }
            }
            if (orderItemSummarySet != orderItemReferenceNumberSet) {
                String missingOrderItemSummaryIds = '';
                for (String requestId : orderItemReferenceNumberSet) {
                    if (!orderItemSummarySet.contains(requestId)) {
                        missingOrderItemSummaryIds += requestId + ' ';
                    }
                }
                throw new COMM_SL_ResellerOrderException(
                    COMM_CommerceAPI_Constants.INVALID_ORDER_ITEMS,
                    COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.INVALID_ORDER_ITEMS) + missingOrderItemSummaryIds
                );
            }
            if (String.isNotBlank(orderProductSummaryIds)) {
                // Execute COMM_OMS_Cancel_Item flow
                Map<String, Object> params = new Map<String, Object>();
                params.put(FLOW_PARAM_RETURNED_ORDER_SUMMARY_IDS, orderSummaryList.get(0).Id);
                params.put(FLOW_PARAM_RETURNED_ORDER_PRODUCT_SUMMARY_IDS, orderProductSummaryIds.removeEnd(','));
                Flow.Interview.COMM_OMS_Cancel_Item cancelItemFlow = new Flow.Interview.COMM_OMS_Cancel_Item(params);
                cancelItemFlow.start();
            }
            // check if orderItemSummary records from inputRequest were cancelled correctly
            List<OrderItemSummary> orderItemSummaryConfirmartionList = orderItemSummaryRep.getOrderItemSummariesById(orderItemSummaryToProcessList);
            for (OrderItemSummary orderItemSummaryConfirmationRecord : orderItemSummaryConfirmartionList) {
                if (orderItemSummaryConfirmationRecord.Status == COMM_DO_OrderItemSummary.RETURNED_STATUS) {
                    orderItemSummaryToConfirmSet.add(orderItemSummaryConfirmationRecord.Id);
                }
            }
            if (new Set<String>(orderItemSummaryToProcessList) != orderItemSummaryToConfirmSet) {
                String missingOrderItemSummaryIds = '';
                for (String requestId : orderItemSummaryToConfirmSet) {
                    if (!(new Set<String>(orderItemSummaryToProcessList)).contains(requestId)) {
                        missingOrderItemSummaryIds += requestId + ' ';
                    }
                }
                throw new COMM_SL_ResellerOrderException(
                    COMM_CommerceAPI_Constants.INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR,
                    COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR) + missingOrderItemSummaryIds
                );
            }
            outputRequestMap.put('Status', 'Success');
        } else {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.BAD_ORDER_SUMMARY_ID,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BAD_ORDER_SUMMARY_ID)
            );
        }
        return outputRequestMap;
    }
}