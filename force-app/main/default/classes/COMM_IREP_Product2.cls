/**
 * @author Daniel Lascas
 * @description Product2 repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/03/2024       Original version
 * Jose Passos      21/03/2024       Add getProductsByProductCodes
 * Daniel Lascas    26/04/2024       ECOMM-891: Add getProductAndCapacitiesByProductCodes
 **/
public interface COMM_IREP_Product2 extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Active Products by a set of Product Ids
     *
     * @param productIds Set of Product Id's to query
     * @return List of Product Records found
     **/
    List<Product2> getActiveProductsByIds(Set<Id> productIds);
    /**
     * @description Given a list of ProductCodes get Product2 details, including Category (Family)-
     *
     * @param productCodeList List<Product2>
     * @return Map<String, Product2>
     */
    Map<String, Product2> getProductsByProductCodes(List<String> productCodeList);
    /**
     * @description Retrieve a list of Products and their processed default capacity by a set of Product Codes
     *
     * @param productCodes Set of Product Codes to query
     * @return List of Products with list of default capacities found
     */
    List<Product2> getProductAndCapacitiesByProductCodes(Set<String> productCodes);
    /**
     * @description Retrieve a list of Products with dynamic Field, set of fields on "productSettingsValues" Set<String>
     *
     * @param productSettingsValues Set of Product fields to query
     * @return List of Products
     */
    List<Product2> getProductWithDynamicFields(Set<String> productSettingsValues);
    /**
     * @description Retrieve a list of valid Products and their processed default capacities
     * by a set of Product Ids
     *
     * @param productCodes Set of Product Ids to query
     * @return List of Products with list of default capacities found
     */
    List<Product2> getValidProductAndCapacitiesByIds(Set<Id> productIds);
    /**
     * @description Retrieve a list of Products by a set of Product Ids
     *
     * @param productIds Set of Product Id's to query
     * @return List of Product Records found
     **/
    List<Product2> getProductsByIds(Set<Id> productIds);
}