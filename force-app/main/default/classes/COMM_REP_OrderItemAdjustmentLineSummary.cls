/**
 * @author Daniel Lascas
 * @description OrderItemAdjustmentLineSummary repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/08/2024       ECOMM-2078 - Original version
 **/
public inherited sharing class COMM_REP_OrderItemAdjustmentLineSummary extends FW_SobjectRep implements COMM_IREP_OrderItemAdjustmentLineSummary {
    /**
     * @description Obtain OrderItemAdjustmentLineSummary records based on the Id Set of related Order Item Summaries
     * @param orderItemSummaryIds Set of Order Item Summary Record Ids to query
     * @return List of OrderItemAdjustmentLineSummary records found
     */
    public List<OrderItemAdjustmentLineSummary> getOrderItemAdjustLineSumByOrderItemSummaryIds(Set<Id> orderItemSummaryIds) {
        return [
            SELECT
                Id,
                Amount,
                OriginalOrderItemAdjustmentLineItemId,
                OriginalOrderItemAdjustmentLineItem.Amount,
                OrderItemSummaryId,
                TYPEOF AdjustmentCause
                    WHEN Promotion THEN Name
                END
            FROM OrderItemAdjustmentLineSummary
            WHERE OrderItemSummaryId IN :orderItemSummaryIds
            WITH SECURITY_ENFORCED
        ];
    }
}