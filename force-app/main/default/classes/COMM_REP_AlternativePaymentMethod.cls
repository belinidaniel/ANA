/**
 * @author Diogo Gonçalves
 * @description AlternativePaymentMethod repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    30/04/2024       Original version
 **/
public inherited sharing class COMM_REP_AlternativePaymentMethod extends FW_SobjectRep implements COMM_IREP_AlternativePaymentMethod {
    /**
     * @description Retrieve a list of AlternativePaymentMethod by a set of <SObjectName>  Ids
     *
     * @param ids - Set of Ids to query
     * @return List of AlternativePaymentMethod Records found
     **/
    public List<AlternativePaymentMethod> getById(Set<Id> ids) {
        return [
            SELECT Id, GatewayToken
            FROM AlternativePaymentMethod
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }
}