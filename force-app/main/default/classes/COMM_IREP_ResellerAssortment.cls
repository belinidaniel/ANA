/**
 * @author Diogo Gonçalves
 * @description ResellerAssortment repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public interface COMM_IREP_ResellerAssortment extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of ResellerAssortment by product code and reseller account Id
     *              For update of the Daily Count field
     *
     * @param productCodes Set of productCodes to query
     * @param resellerAccountId Id of the reseller account
     * @return List of ResellerAssortment Records found
     **/
    List<COMM_ResellerAssortment__c> getForStockReserve(Set<String> productCodes, Id resellerAccountId);
}