/**
 * @author Daniel Reto
 * @description OrderItemTaxLineItemSummary selector class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto          08/08/2024       Original version
 **/
public inherited sharing class COMM_REP_OrderItemTaxLineItemSummary extends FW_SobjectRep implements COMM_IREP_OrderItemTaxLineItemSummary {

    /**
     * @description Selects OrderItemTaxLineItemSummary records based on the Id Set
     * @param OrderItemTaxLineItemSummary Set of the Ids
     * @return List of OrderItemTaxLineItemSummary
     */
    public List<OrderItemTaxLineItemSummary> getOrderItemTaxLineItemSummaryByOrderSummaryNumber(String orderItemTaxLineItemSummaryNumbers) {
        return [
            SELECT
                Id,
                Amount,
                OrderSummaryId,
                OrderItemSummaryId,
                Rate,
                TaxEffectiveDate,
                Type
            FROM OrderItemTaxLineItemSummary
            WHERE OrderSummary.OrderNumber =: orderItemTaxLineItemSummaryNumbers
            WITH SECURITY_ENFORCED
            ORDER BY Rate ASC
        ];
    }
}