/**
 * @author Daniel Lascas
 * @description OrderItemAdjustmentLineSummary repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/08/2024       ECOMM-2078 - Original version
 **/
public interface COMM_IREP_OrderItemAdjustmentLineSummary extends FW_ISObjectRep {
    /**
     * @description Obtain OrderItemAdjustmentLineSummary records based on the Id Set of related Order Item Summaries
     * @param orderItemSummaryIds Set of Order Item Summary Record Ids to query
     * @return List of OrderItemAdjustmentLineSummary records found
     */
    List<OrderItemAdjustmentLineSummary> getOrderItemAdjustLineSumByOrderItemSummaryIds(Set<Id> orderItemSummaryIds);
}