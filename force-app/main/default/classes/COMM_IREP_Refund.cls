/**
 * @author Jose Passos
 * @description Refundt repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      06/11/2024       Original version
 **/
public interface COMM_IREP_Refund extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of GiftCard refunds by a set of OrderSummary Ids
     *
     * @param orderSummaryIdSet Set of orderSummary Ids to query
     * @param paymentGatewayNameList List of PaymentGateways to query
     * @return Map of payment Records found
     **/
    List<Refund> getRefundsByOrderSummaryId(Set<Id> orderSummaryIdSet, List<String> paymentGatewayNameList);
}