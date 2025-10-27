/**
 * @author Daniel Reto
 * @description Model for search Customer and Guest orders response.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_SearchOrdersOutput {
    global class Order {
        global String orderNumber;
        global Date orderDate;
        global List<String> productTypes;
        global List<String> airports;
        global Decimal price;
        global String currencyCode;
        global Integer status;
        global DateTime maxReservationEndDate;
        global Boolean isLegacyOrder;
    }
    global Integer count;
    global Integer pageSize;
    global Integer page;
    global List<Order> data;

    public static COMM_WS_SearchOrdersOutput parse(String json) {
        return (COMM_WS_SearchOrdersOutput) System.JSON.deserialize(json, COMM_WS_SearchOrdersOutput.class);
    }

    /**
     * @description Build Output request.
     * @param  COMM_WS_SearchOrdersInput inputRequest - Input request received
     * @param  COMM_WS_SearchOrdersOutput outputRequest - Output request to be build
     * @param  List<OrderSummary> orderSummaryList - List of Order Records used to build the Output request
     */
    public static void buildOutputRequest(
        COMM_WS_SearchOrdersInput inputRequest,
        COMM_WS_SearchOrdersOutput outputRequest,
        List<OrderSummary> orderSummaryList
    ) {
        outputRequest.data = new List<COMM_WS_SearchOrdersOutput.Order>();
        Integer startIndex =
            ((inputRequest.page != null) ? inputRequest.page : 0) *
            ((inputRequest.pageSize != null) ? inputRequest.pageSize : orderSummaryList.size());
        Integer endIndex = Math.min(startIndex + inputRequest.pageSize - 1, orderSummaryList.size());
        Integer index = 0;
        for (OrderSummary orderSummaryRecord : orderSummaryList) {
            if (index >= startIndex && index <= endIndex) {
                Set<String> orderFamilyValues = new Set<String>();
                Set<String> orderAirportValues = new Set<String>();
                COMM_WS_SearchOrdersOutput.Order orderRecordOnRequest = new COMM_WS_SearchOrdersOutput.Order();
                //Set Order values on output request
                orderRecordOnRequest.orderNumber = orderSummaryRecord.OrderNumber;
                orderRecordOnRequest.orderDate = orderSummaryRecord.OrderedDate.dateGMT();
                orderRecordOnRequest.currencyCode = 'EUR';
                orderRecordOnRequest.price = orderSummaryRecord.GrandTotalAmount;
                orderRecordOnRequest.status = COMM_DO_OrderSummary.getFilterStatusCodes(orderSummaryRecord.Status); // change value
                orderRecordOnRequest.maxReservationEndDate = orderSummaryRecord.COMM_MaxReservationEnd__c;
                orderRecordOnRequest.isLegacyOrder = orderSummaryRecord.COMM_IsLegacyOrder__c;
                for (OrderItemSummary orderItemSummaryRecord : orderSummaryRecord.OrderItemSummaries) {
                    if (orderItemSummaryRecord.Product2 != null && orderItemSummaryRecord.Product2.Family != null) {
                        orderFamilyValues.add(orderItemSummaryRecord.Product2.Family);
                    }
                    if (orderItemSummaryRecord.Product2 != null && orderItemSummaryRecord.Product2.COMM_Airport__c != null) {
                        orderAirportValues.add(orderItemSummaryRecord.Product2.COMM_Airport__c);
                    }
                }
                orderRecordOnRequest.productTypes = COMM_DO_Product2.getFilterProductFamilyCodes(orderFamilyValues);
                orderRecordOnRequest.airports = new List<String>(orderAirportValues);
                outputRequest.data.add(orderRecordOnRequest);
                if (index == endIndex) {
                    break;
                }
            }
            index++;
        }
        outputRequest.count = orderSummaryList != null ? orderSummaryList.size() : 0;
        outputRequest.pageSize = inputRequest.pageSize;
        outputRequest.page = inputRequest.page;
    }
}