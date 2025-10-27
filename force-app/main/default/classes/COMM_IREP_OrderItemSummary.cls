/**
 * @author Rui Salgado
 * @description OrderItemSummary selector interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Diogo Gonçalves  01/04/2024       ECOMM-105: Added getOrderItemSummariesById and getWithQRCode
 * Diogo Gonçalves  19/06/2024       ECOMM-1420 Change the name of the method getWithQRCode
 * Daniel Reto      12/08/2024       ECOMM-327
 **/

@suppressWarnings('PMD.ExcessiveParameterList')
public interface COMM_IREP_OrderItemSummary extends FW_ISObjectRep {
    /**
     * @description Selects OrderItemSummary records for CPMS communication based on the Id list
     * @param OrderItemSummary List of the Ids
     * @return List of OrderItemSummary
     */
    List<OrderItemSummary> getForCPMS(List<Id> orderItemSummaryIds);

    /**
     * @description Retrieve a list of Order Item Summaries that have a specific Id
     * @param {List<String>}
     * @return {List<OrderItemSummary>}
     */
    List<OrderItemSummary> getOrderItemSummariesById(List<String> ids);

    /**
     * @description Retrieve Order Item Summaries with a QRCode
     * @param {List<String>} orderSummaryIds
     * @return {List<OrderItemSummary>}
     */
    List<OrderItemSummary> getForVoucherPDF(List<String> orderSummaryIds, List<String> orderItemSummaryIds);

    /**
     * @description Retrieves the order item summaries to create a gift card
     * @param {List<String>} orderSummaryIds
     * @return {List<OrderItemSummary>}
     */
    List<OrderItemSummary> getForGiftCard(List<String> ids);
    
    /**
     * @description Retrieve a list of Order Item Summaries that have a specific Order Summary Id
     * @param orderSummaryId Order Summary Id
     * @return List<OrderItemSummary>
     */
    List<OrderItemSummary> getOrderItemSummariesByOrderSummaryId(String orderSummaryId);
}