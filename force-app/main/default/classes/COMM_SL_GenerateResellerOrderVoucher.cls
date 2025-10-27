/**
 * @author Daniel Reto
 * @description Service Layer class to generate a Platform Event "Order Vouchers"
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/10/2024       Original version
 **/
public inherited sharing class COMM_SL_GenerateResellerOrderVoucher {
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    /**
     * @description Wrapper definition with variable set from Flow
     */
    public class InputWrapper {
        @InvocableVariable(label='Order Id' description='Order Id')
        public String orderId;
        @InvocableVariable(label='Order Summary Id' description='Order Summary Id')
        public String orderSummaryId;
        @InvocableVariable(label='Reseller Id' description='Reseller Id')
        public String resellerId;
    }

    /**
     * @description Get product pricing information
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    @InvocableMethod(label='Generate Order Voucher' description='Generate Order Voucher depending on inputs')
    public static List<COMM_OrderVouchers__e> generateOrderVoucherOnFlow(List<InputWrapper> inputWrapper) {
        List<COMM_OrderVouchers__e> orderVoucherList = new List<COMM_OrderVouchers__e>();

        // Set salesforce Order Id
        String salesforceOrderId = inputWrapper[0].resellerId + '-' + inputWrapper[0].orderId;
        
        // Generate Order Vouchers Platform Event
        COMM_OrderVouchers__e orderVoucherEvent = generateOrderVoucher(inputWrapper[0].orderId, inputWrapper[0].orderSummaryId, inputWrapper[0].resellerId, salesforceOrderId);
        orderVoucherList.add(orderVoucherEvent);

        return orderVoucherList;
    }

    /**
     * @description Check if the available products details match options entered in screen flow
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return Boolean flagging if product should be available for User selection in screen flow
     */
    public static COMM_OrderVouchers__e generateOrderVoucher(String orderId, String orderSummaryId, String resellerId, String salesforceOrderId) {

        COMM_OrderVouchers__e orderVoucherEvent = new COMM_OrderVouchers__e();
        orderVoucherEvent.COMM_OrderId__c = orderId;
        orderVoucherEvent.COMM_OrderSummaryId__c = orderSummaryId;
        orderVoucherEvent.COMM_ResellerId__c = resellerId;
        orderVoucherEvent.COMM_SalesforceOrderId__c = salesforceOrderId;

        // Query all Order Item Summary Records using Order Summary Id
        List<OrderItemSummary> orderItemSummaryList = orderItemSummaryRep.getOrderItemSummariesByOrderSummaryId(orderSummaryId);

        // build Order Line JSON string to send on Platform Event
        List<Map<String, Object>> orderLineDataMapList = new List<Map<String, Object>>();
        for(OrderItemSummary orderItemSummaryRecord : orderItemSummaryList){
            Map<String, Object> orderLineDataMap = new Map<String, Object>{
                'orderLineId' => orderItemSummaryRecord.COMM_OrderItemReferenceNumber__c,
                'bundleLineId' => String.isBlank(orderItemSummaryRecord.COMM_BundleLineId__c) ? '' : orderItemSummaryRecord.COMM_BundleLineId__c,
                'codeType' => 'QR',
                'codeString' => orderItemSummaryRecord.Product2.Family == COMM_DO_Product2.CATEGORY_PARKING ? orderItemSummaryRecord.COMM_Barcode__c : orderItemSummaryRecord.COMM_QRCode__c
            };
            orderLineDataMapList.add(orderLineDataMap);
        }
        orderVoucherEvent.COMM_OrderLines__c = JSON.serialize(orderLineDataMapList);

        return orderVoucherEvent;
    }
    
}