/**
 * @author Diogo Gonçalves
 * @description Payment repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public interface COMM_IREP_Payment extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of payments by a set of Payment Ids
     *
     * @param paymentIds Set of paymentIds Ids to query
     * @return List of payment Records found
     **/
    List<Payment> getPaymentsById(Set<Id> paymentIds);

    /**
     * @description Retrieve a list of paygate payments by a set of Payment Ids
     *
     * @param paymentIds Set of paymentIds Ids to query
     * @return List of payment Records found
     **/
    List<Payment> getForPaygateRefund(Set<Id> paymentIds);

    /**
     * @description Retrieve a list of GiftCard payments by a set of OrderSummary Ids
     *
     * @param orderSummaryIdSet Set of orderSummary Ids to query
     * @param paymentGatewayNameList List of PaymentGateways to query
     * @return Map of payment Records found
     **/
    List<Payment> getPaymentsByOrderSummaryId(Set<Id> orderSummaryIdSet, List<String> paymentGatewayNameList);
}