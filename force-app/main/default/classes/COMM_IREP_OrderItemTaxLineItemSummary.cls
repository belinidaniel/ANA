/**
 * @author Daniel Reto
 * @description OrderItemTaxLineItemSummary selector interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto          08/08/2024       Original version
 **/
public interface COMM_IREP_OrderItemTaxLineItemSummary {
    /**
     * @description Selects OrderItemTaxLineItemSummary records based on the Id Set
     * @param OrderItemTaxLineItemSummary Set of the Ids
     * @return List of OrderItemTaxLineItemSummary
     */
    List<OrderItemTaxLineItemSummary> getOrderItemTaxLineItemSummaryByOrderSummaryNumber(String orderItemTaxLineItemSummaryNumbers);
}