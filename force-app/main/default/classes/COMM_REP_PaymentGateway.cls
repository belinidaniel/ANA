/**
 * @author Diogo Gonçalves
 * @description PaymentGateway repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public inherited sharing class COMM_REP_PaymentGateway extends FW_SobjectRep implements COMM_IREP_PaymentGateway {
    /**
     * @description Retrieve a PaymentGateway record by external reference id
     *
     * @param externalReference - External reference id to query
     * @return List of PaymentGateway Records found
     **/
    public PaymentGateway getByExternalReference(String externalReference) {
        List<PaymentGateway> paymentGateway = [
            SELECT Id
            FROM PaymentGateway
            WHERE ExternalReference = :externalReference
            WITH USER_MODE
        ];
        if (paymentGateway.isEmpty()) {
            return null;
        }
        return paymentGateway[0];
    }
}