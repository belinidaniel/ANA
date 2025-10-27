/**
 * @author Daniel Lascas
 * @description Product2 repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/03/2024       Original version
 * Jose Passos      21/03/2024       Add getProductsByProductCodes
 * Daniel Lascas    26/04/2024       ECOMM-891: Add getProductAndCapacitiesByProductCodes
 **/
public inherited sharing class COMM_REP_Product2 extends FW_SobjectRep implements COMM_IREP_Product2 {
    private COMM_REP_Capacity CAPACITY_REP = new COMM_REP_Capacity();
    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{
        Product2.Id,
        Product2.COMM_ParentProduct__c,
        Product2.ProductCode
    };

    /**
     * @description Retrieve a list of Active Products by a set of Product Ids
     *
     * @param productIds Set of Product Id's to query
     * @return List of Product Records found
     **/
    public List<Product2> getActiveProductsByIds(Set<Id> productIds) {
        return [
            SELECT Id
            FROM Product2
            WHERE Id IN :productIds AND IsActive = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Given a list of ProductCodes get Product2 details
     *
     * @param productCodeList List<Product2>
     * @return Map<String, Product2>
     */
    public Map<String, Product2> getProductsByProductCodes(List<String> productCodeList) {
        List<Product2> products = [
            SELECT
                Id,
                Name,
                ProductCode,
                Family,
                COMM_ParentProduct__c,
                COMM_ParentProduct__r.ProductCode,
                COMM_TimeZoneByAirport__c,
                COMM_Tax__c,
                COMM_SAPLocation__c
            FROM Product2
            WHERE ProductCode IN :productCodeList AND isActive = TRUE
            WITH SECURITY_ENFORCED
        ];

        Map<String, Product2> product2Map = new Map<String, Product2>();
        for (Product2 product : products) {
            product2Map.put(product.ProductCode, product);
        }

        return product2Map;
    }

    /**
     * @description Retrieve a list of Products and their processed default capacity by a set of Product Codes
     *
     * @param productCodes Set of Product Codes to query
     * @return List of Products with list of default capacities found
     */
    public List<Product2> getProductAndCapacitiesByProductCodes(Set<String> productCodes) {
        return [
            SELECT
                Id,
                ProductCode,
                COMM_ParentProduct__c,
                COMM_ParentProduct__r.ProductCode,
                Family,
                (
                    SELECT COMM_CalculatedCapacity__c
                    FROM Capacities__r
                    WHERE
                        COMM_IsDefaultCapacity__c = TRUE
                        AND COMM_Active__c = TRUE
                        AND COMM_ProcessStatus__c = :COMM_DO_Capacity.PROCESS_STATUS_COMPLETED
                )
            FROM Product2
            WHERE ProductCode IN :productCodes
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of Products with dynamic Field, set of fields on "productSettingsValues" Set<String>
     *
     * @param productSettingsValues Set of Product fields to query
     * @return List of Products
     */
    public List<Product2> getProductWithDynamicFields(Set<String> productSettingsValues) {
        // Construct the SOQL query to fetch all relevant fields from Product2
        String fieldNames = 'Id, Family';
        for (String fieldName : productSettingsValues) {
            fieldNames += ', ' + fieldName;
        }

        String dynamicQuery = 'SELECT ' + fieldNames + ' FROM Product2 WITH USER_MODE';
        return Database.query(dynamicQuery);
    }

    /**
     * @description Retrieve a list of valid Products and their processed default capacities
     * by a set of Product Ids
     *
     * @param productIdSet Set of Product Ids to query
     * @return List of Products with list of default capacities found
     */
    public List<Product2> getValidProductAndCapacitiesByIds(Set<Id> productIdSet) {
        return [
            SELECT
                Id,
                Family,
                (
                    SELECT Id
                    FROM Capacities__r
                    WHERE
                        COMM_IsDefaultCapacity__c = TRUE
                        AND COMM_Active__c = TRUE
                        AND COMM_ProcessStatus__c IN (:COMM_DO_Capacity.PROCESS_STATUS_COMPLETED, :COMM_DO_Capacity.PROCESS_STATUS_PENDING)
                )
            FROM Product2
            WHERE Id IN :productIdSet AND COMM_ValidFrom__c <= TODAY AND COMM_ValidTo__c >= TODAY
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of Products by a set of Product Ids
     *
     * @param productIds Set of Product Id's to query
     * @return List of Product Records found
     **/
    public List<Product2> getProductsByIds(Set<Id> productIds) {
        return [
            SELECT Id, COMM_Airport__c, COMM_TimeZoneByAirport__c
            FROM Product2
            WHERE Id IN :productIds
            WITH SECURITY_ENFORCED
        ];
    }
}