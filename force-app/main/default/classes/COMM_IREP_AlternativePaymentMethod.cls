/**
 * @author Diogo Gonçalves
 * @description AlternativePaymentMethod repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    30/04/2024       Original version
 **/
public interface COMM_IREP_AlternativePaymentMethod extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of AlternativePaymentMethod by a set of Ids
     *
     * @param ids Set of Ids to query
     * @return List of AlternativePaymentMethod Records found
     **/
    List<AlternativePaymentMethod> getById(Set<Id> ids);
}