/**
 * @author Daniel Lascas
 * @description COMM_ProductVariations__c repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/05/2024       ECOMM-386: Original version
 **/
public inherited sharing class COMM_REP_ProductVariations extends FW_SobjectRep implements COMM_IREP_ProductVariations {
    /**
     * @description Given a set of Product Ids. Retrieve Product Variations
     * for those products.
     *
     * @param productIds Set of Product Ids
     * @return Product Variation Records found
     */
    public List<COMM_ProductVariations__c> getProductVariationsByProductId(Set<Id> productIds) {
        return [
            SELECT
                Id,
                COMM_Quantity__c,
                COMM_NumberOfHours__c,
                COMM_MasterProduct__c,
                COMM_RelatedProduct__c,
                COMM_RelatedProduct__r.ProductCode,
                COMM_RelatedProduct__r.Name,
                COMM_RelatedProduct__r.Family,
            	COMM_RelatedProduct__r.COMM_Airport__c,
                COMM_RelatedProduct__r.COMM_ValidFrom__c,
                COMM_RelatedProduct__r.COMM_ValidTo__c,
                COMM_RelatedProduct__r.COMM_ParentProduct__c,
                COMM_RelatedProduct__r.COMM_ParentProductCode__c
            FROM COMM_ProductVariations__c
            WHERE COMM_MasterProduct__c IN :productIds
            WITH USER_MODE
        ];
    }
        
    /**
     * @description Retrieve a list of COMM_ProductVariations__c by a set of master product codes
     *
     * @param productCodes - Set of master product codes to query
     * @return {List<COMM_ProductVariations__c>}
     **/
    public List<COMM_ProductVariations__c> getProductVariationsByMasterProduct(Set<String> masterProductCodes) {
        return [
            SELECT Id, COMM_MasterProduct__r.ProductCode, COMM_RelatedProduct__r.ProductCode
            FROM COMM_ProductVariations__c
            WHERE COMM_MasterProduct__r.ProductCode IN :masterProductCodes
            WITH USER_MODE
        ];
    }
}