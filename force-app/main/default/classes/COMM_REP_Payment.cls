/**
 * @author Diogo Gonçalves
 * @description Payment repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 * Diogo Gonçalves    16/08/2024       ECOMM-1758: Added the method getForPaygateRefund
 * Diogo Gonçalves    17/09/2024       ECOMM-481: Added the field OrderPaymentSummary.OrderSummaryId
 **/
public inherited sharing class COMM_REP_Payment extends FW_SobjectRep implements COMM_IREP_Payment {
    /**
     * @description Retrieve a list of payments by a set of Payment  Ids
     *
     * @param paymentIds - Set of paymentIds Ids to query
     * @return List of payments Records found
     **/
    public List<Payment> getPaymentsById(Set<Id> paymentIds) {
        return [
            SELECT
                Id,
                Amount,
                OrderPaymentSummary.OrderSummary.OrderNumber,
                GatewayRefDetails,
                OrderPaymentSummary.OrderSummaryId,
                PaymentMethodId,
                GatewayRefNumber
            FROM Payment
            WHERE Id IN :paymentIds
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of paygate payments by a set of Payment Ids
     *
     * @param paymentIds Set of paymentIds Ids to query
     * @return List of payment Records found
     **/
    public List<Payment> getForPaygateRefund(Set<Id> paymentIds) {
        return [
            SELECT Id, Amount, OrderPaymentSummary.OrderSummary.OrderNumber, GatewayRefDetails, PaymentMethodId, GatewayRefNumber
            FROM Payment
            WHERE Id IN :paymentIds AND PaymentGateway.PaymentGatewayName = :COMM_OMS_Constants.PAYGATE_GATEWAY_NAME
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of GiftCard payments by a set of OrderSummary Ids
     *
     * @param orderSummaryIdSet Set of orderSummary Ids to query
     * @param paymentGatewayNameList List of PaymentGateways to query
     * @return Map of payment Records found
     **/
    public List<Payment> getPaymentsByOrderSummaryId(Set<Id> orderSummaryIdSet, List<String> paymentGatewayNameList) {
        return [
            SELECT Id, OrderPaymentSummary.OrderSummaryId, Amount
            FROM Payment
            WHERE OrderPaymentSummary.OrderSummaryId IN :orderSummaryIdSet AND PaymentGateway.PaymentGatewayName IN :paymentGatewayNameList
            WITH USER_MODE
        ];
    }
}