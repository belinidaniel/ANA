/**
 * @author Diogo Gonçalves
 * @description Payment Authorization repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public interface COMM_IREP_PaymentAuthorization extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of payment Authorization by a set of Payment Authorization Ids
     *
     * @param paymentAuthorizationIds Set of paymentAuthorizationIds Ids to query
     * @return List of payment authorization Records found
     **/
    List<PaymentAuthorization> getPaymentAuthorizationsById(Set<Id> paymentAuthorizationIds);
}