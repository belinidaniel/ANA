/**
 * @author Diogo Gonçalves
 * @description OrderSummary selector interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      08/04/2024       Original version
 * Diogo Gonçalves      01/07/2024       ECOMM-1557: Added getForVoucherPDFService
 * Daniel Reto          03/07/2024       New Method: getOrderSummaryById
 * Daniel Reto          06/11/2024       ECOMM-327: New Method
 * Sofia Silva          29/07/2025       New Methods
 **/
public interface COMM_IREP_OrderSummary extends FW_ISObjectRep {
    /**
     * @description Selects OrderSummary records based on the Id list
     * @param ordersummaryIds List of the Ids
     * @return List of OrderSummary
     */
    List<OrderSummary> getByIds(List<String> ordersummaryIds);

    /**
     * @description Selects OrderSummary records based on the an Order Number list, to be used in COMM_WS_VoucherPDF
     * @param orderNumbers List of the OrderNumbers
     * @return List of OrderSummary
     */
    List<OrderSummary> getForVoucherPDFService(List<String> orderNumbers);

    /**
     * @description Retrieves the order item summaries to to send for Commerce side while doing a Search Order
     * @param COMM_WS_SearchOrdersInput inputRequest
     * @param String orderSummaryExtraFilter : request key matched with Salesforce Field to add on Order Summary query filter
     * @return {List<OrderSummary>}
     */
    List<OrderSummary> getForSearchOrder(COMM_WS_SearchOrdersInput inputRequest, String orderSummaryExtraFilter);

    /**
     * @description Retrieves the order item summaries to to send for Commerce side while doing a Search Order
     * @param String orderNumberValue : Order Summary Order Number to search
     * @return {List<OrderSummary>}
     */
    List<OrderSummary> getOrderSummaryByOrderNumber(String orderNumberValue);

    /**
     * @description Retrieves the order summaries while doing a Cancel Reseller Order
     * @param resellerId : reseller Id on related Account to search
     * @param salesforceOrderId : merge field between Salesforce and Order sent from Mulesoft, to search
     * @return {List<OrderSummary>}
     */
    List<OrderSummary> getOrderSummaryByCOMMSalesforceOrderId(String resellerId, String salesforceOrderId);

     /**
     * @description Selects OrderSummary records based on possible errors on the reservation journey filtered on Order Product Summary fields
     * @return List of OrderSummary
     */
    //List<OrderSummary> getForJourneyMonitoringOrderProdSumFilter();

    /**
     * @description Selects OrderSummary records based on possible errors on the reservation journey filtered by no related Invoices
     * @return List of OrderSummary
     */
    //List<OrderSummary> getForJourneyMonitoringInvoiceFilter();
}