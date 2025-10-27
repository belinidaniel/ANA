/**
 * @author Daniel Reto
 * @description Class to support the Web Service to cancel an Order.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_CancelOrders {
    private static final String ERRORCODE = 'ERROR_FOUND';
    private static final String INVALID_PARAMETER_ERROR = 'Data received doesn\'t match Salesforce Data!';
    private static final String INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR = 'Some Order Item Summary were not cancelled: ';
    private static final String INVALID_IDS_ERROR = 'Some Order Item Summary Ids do not exist: ';

    /**
     * @description Check if any Order record exists for the request order number.
     * @param COMM_WS_CancelOrdersInput inputRequest - Order data to cancel
     * @return COMM_WS_CancelOrdersOutput output with Order data
     */
    public COMM_WS_CancelOrdersOutput cancelOrder(COMM_WS_CancelOrdersInput inputRequest) {
        COMM_WS_CancelOrdersOutput outputRequest = new COMM_WS_CancelOrdersOutput();
        List<OrderSummary> orderSummaryList = new List<OrderSummary>();
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
        Set<String> orderItemSummarySet = new Set<String>();
        List<String> orderItemSummaryToProcessList = new List<String>();
        Set<String> orderItemSummaryToConfirmSet = new Set<String>();

        if (String.isBlank(inputRequest.orderSummaryId)) {
            orderSummaryList = orderSummaryRep.getOrderSummaryByOrderNumber(inputRequest.orderNumber);
        } else {
            orderSummaryList = orderSummaryRep.getByIds(new List<String>{ inputRequest.orderSummaryId });
        }

        if (
            !orderSummaryList.isEmpty() &&
            (orderSummaryList.get(0).AccountId == inputRequest.accountId ||
            orderSummaryList.get(0).BillingEmailAddress == inputRequest.email)
        ) {
            // adjust returnedOrderProductSummaryIds paramer of COMM_OMS_Cancel_Item flow
            String orderProductSummaryIds = '';
            for (OrderItemSummary orderProductSummaryRecord : orderSummaryList[0].OrderItemSummaries) {
                if (inputRequest.orderProductSummaryIds.contains(orderProductSummaryRecord.Id) || !inputRequest.partial) {
                    orderItemSummarySet.add(orderProductSummaryRecord.Id);
                    if (orderProductSummaryRecord.Status != COMM_DO_OrderItemSummary.RETURNED_STATUS) {
                        orderItemSummaryToProcessList.add(orderProductSummaryRecord.Id);
                        orderProductSummaryIds += orderProductSummaryRecord.Id + ',';
                    }
                }
            }
            if (orderItemSummarySet != new Set<String>(inputRequest.orderProductSummaryIds) && inputRequest.partial) {
                outputRequest.errorMsg = INVALID_IDS_ERROR;
                for (String requestId : inputRequest.orderProductSummaryIds) {
                    if (!orderItemSummarySet.contains(requestId)) {
                        outputRequest.errorMsg += requestId + ' ';
                    }
                }
                outputRequest.errorCode = ERRORCODE;
                outputRequest.success = false;
                outputRequest.orderProductSummaryIds = inputRequest.partial
                    ? inputRequest.orderProductSummaryIds
                    : new List<String>(orderItemSummarySet);
                return outputRequest;
            }
            if (String.isNotBlank(orderProductSummaryIds)) {
                // Execute COMM_OMS_Cancel_Item flow
                Map<String, Object> params = new Map<String, Object>();
                params.put('returnedOrderSummaryId', orderSummaryList.get(0).Id);
                params.put('returnedOrderProductSummaryIds', orderProductSummaryIds.removeEnd(','));
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
            outputRequest.success = true;
            outputRequest.orderProductSummaryIds = inputRequest.partial ? inputRequest.orderProductSummaryIds : new List<String>(orderItemSummarySet);
            if (new Set<String>(orderItemSummaryToProcessList) != orderItemSummaryToConfirmSet) {
                outputRequest.errorMsg = INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR;
                for (String requestId : inputRequest.orderProductSummaryIds) {
                    if (!orderItemSummarySet.contains(requestId)) {
                        outputRequest.errorMsg += requestId + ' ';
                    }
                }
                outputRequest.errorCode = ERRORCODE;
                outputRequest.success = false;
                outputRequest.orderProductSummaryIds = inputRequest.partial
                    ? inputRequest.orderProductSummaryIds
                    : new List<String>(orderItemSummarySet);
            }
        } else {
            outputRequest.errorMsg = INVALID_PARAMETER_ERROR;
            outputRequest.errorCode = ERRORCODE;
            outputRequest.success = false;
            outputRequest.orderProductSummaryIds = inputRequest.partial ? inputRequest.orderProductSummaryIds : new List<String>(orderItemSummarySet);
        }
        return outputRequest;
    }
}