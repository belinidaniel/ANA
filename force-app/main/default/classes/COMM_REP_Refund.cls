/**
 * @author Jose Passos
 * @description Refundt repository class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      06/11/2024       Original version
 **/
public inherited sharing class COMM_REP_Refund extends FW_SobjectRep implements COMM_IREP_Refund {
    /**
     * @description Retrieve a list of GiftCard refunds by a set of OrderSummary Ids
     *
     * @param orderSummaryIdSet Set of orderSummary Ids to query
     * @param paymentGatewayNameList List of PaymentGateways to query
     * @return Map of Refund Records found
     **/
    public List<Refund> getRefundsByOrderSummaryId(Set<Id> orderSummaryIdSet, List<String> paymentGatewayNameList) {
        return [
            SELECT Id, OrderPaymentSummary.OrderSummaryId, Amount, ClientContext
            FROM Refund
            WHERE OrderPaymentSummary.OrderSummaryId IN :orderSummaryIdSet AND PaymentGateway.PaymentGatewayName IN :paymentGatewayNameList
            WITH USER_MODE
        ];
    }
}