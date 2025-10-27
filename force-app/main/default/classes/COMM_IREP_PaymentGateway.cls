/**
 * @author Diogo Gonçalves
 * @description PaymentGateway repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    20/05/2024       Original version
 **/
public interface COMM_IREP_PaymentGateway extends FW_ISObjectRep {
    /**
     * @description Retrieve a PaymentGateway record by external reference id
     *
     * @param externalReference - External reference id to query
     * @return List of PaymentGateway Records found
     **/
    PaymentGateway getByExternalReference(String externalReference);
}