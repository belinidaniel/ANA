/**
 * @author Diogo Gonçalves
 * @description Payment Authorization repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public inherited sharing class COMM_REP_PaymentAuthorization extends FW_SobjectRep implements COMM_IREP_PaymentAuthorization {
    /**
     * @description Retrieve a list of Payment Authorization by a set of Payment Authorization Ids
     *
     * @param paymentAuthorizationIds Set of paymentAuthorizationIds Ids to query
     * @return List of payment authorization Records found
     **/
    public List<PaymentAuthorization> getPaymentAuthorizationsById(Set<Id> paymentAuthorizationIds) {
        return [
            SELECT Id, GatewayRefNumber, PaymentMethodId
            FROM PaymentAuthorization
            WHERE Id IN :paymentAuthorizationIds
            WITH USER_MODE
        ];
    }
}