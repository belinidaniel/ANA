/**
 * @author Diogo Gonçalves
 * @description ResellerAssortment repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    22/05/2024       Original version
 **/
public inherited sharing class COMM_REP_ResellerAssortment extends FW_SobjectRep implements COMM_IREP_ResellerAssortment {
    /**
     * @description Retrieve a list of ResellerAssortment by product code and reseller account Id
     *              For update of the Daily Count field
     *
     * @param productCodes Set of productCodes to query
     * @param resellerAccountId Id of the reseller account
     * @return List of ResellerAssortment Records found
     **/
    public List<COMM_ResellerAssortment__c> getForStockReserve(Set<String> productCodes, Id resellerAccountId) {
        return [
            SELECT Id, COMM_Product__r.ProductCode, COMM_DailyLimit__c, COMM_CurrentDailyQuantity__c, COMM_AvailableDailyQuantity__c, COMM_PriceBook__c
            FROM COMM_ResellerAssortment__c
            WHERE COMM_Product__r.ProductCode IN :productCodes AND COMM_Account__c = :resellerAccountId
            WITH SECURITY_ENFORCED
            FOR UPDATE
        ];
    }
}