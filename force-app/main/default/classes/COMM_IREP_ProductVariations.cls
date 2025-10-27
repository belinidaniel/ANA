/**
 * @author Daniel Lascas
 * @description COMM_ProductVariations__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/05/2024       ECOMM-386: Original version
 **/
public interface COMM_IREP_ProductVariations extends FW_ISObjectRep {
    /**
     * @description Given a set of Product Ids. Retrieve Product Variations
     * for those products.
     *
     * @param productIds Set of Product Ids
     * @return Product Variation Records found
     */
    List<COMM_ProductVariations__c> getProductVariationsByProductId(Set<Id> productIds);
    /**
     * @description Retrieve a list of COMM_ProductVariations__c by a set of product codes
     *
     * @param productCodes - Set of product codes to query
     * @return {List<COMM_ProductVariations__c>}
     **/
    List<COMM_ProductVariations__c> getProductVariationsByMasterProduct(Set<String> masterProductCodes);
}