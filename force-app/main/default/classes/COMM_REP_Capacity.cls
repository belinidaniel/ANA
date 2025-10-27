/**
 * @author Daniel Lascas
 * @description COMM_Capacity__c repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024       Original version
 * Jose Passos      26/03/2024       Added method getCapacityRecordsToProcessByProductCodes
 * Daniel Reto      11/04/2024       Add List of SObject Fields
 * Jose Passos      10/05/2024       Added methods lockCapacityRecordsToProcessTest
 **/
public inherited sharing class COMM_REP_Capacity extends FW_SobjectRep implements COMM_IREP_Capacity {
    public static final List<SObjectField> CAPACITY_FIELDS = new List<SObjectField>{
        COMM_Capacity__c.Id,
        COMM_Capacity__c.COMM_Product__c,
        COMM_Capacity__c.COMM_ValidTo__c,
        COMM_Capacity__c.COMM_Capacity__c
    };

    /**
     * @description Get non-default Capacity Records that have specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return List of Queried Capacity Records
     */
    public List<COMM_Capacity__c> getNonDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds) {
        return [
            SELECT Id, COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_Product__c IN :productIds AND Id NOT IN :capacityIds AND COMM_IsDefaultCapacity__c = FALSE
            WITH USER_MODE
        ];
    }

    /**
     * @description Get Count of non-default Capacity Records for specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return Aggregated Result List with Count of Active non-default Capacity Records for each Product
     */
    public List<COMM_Capacity__c> getCountNonDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds) {
        return [
            SELECT COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_Product__c IN :productIds AND Id NOT IN :capacityIds AND COMM_IsDefaultCapacity__c = FALSE AND COMM_Active__c = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Get Count of default Capacity Records for specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return Aggregated Result List with Count of Active default Capacity Records for each Product
     */
    public List<COMM_Capacity__c> getCountDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds) {
        return [
            SELECT COMM_Product__c, COMM_ValidFrom__c, COMM_ValidTo__c
            FROM COMM_Capacity__c
            WHERE COMM_Product__c IN :productIds AND Id NOT IN :capacityIds AND COMM_IsDefaultCapacity__c = TRUE AND COMM_Active__c = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Get Capacity records to be processed by Stock Upload for a List of specific Products.
     *
     * @param productCodeList List of ProductCodes
     * @param processStatusList List of Status to consider for processing
     * @return Result List with capacity records to process
     */
    public List<COMM_Capacity__c> getCapacityRecordsToProcessByProductCodes(List<String> productCodeList, List<String> processStatusList) {
        return [
            SELECT
                Id,
                COMM_Product__r.ProductCode,
                COMM_CalculatedCapacity__c,
                COMM_ValidFrom__c,
                COMM_ValidTo__c,
                COMM_ProcessId__c,
                COMM_ProcessStatus__c,
                COMM_StatusMessage__c
            FROM COMM_Capacity__c
            WHERE COMM_ProcessStatus__c IN :processStatusList AND COMM_Product__r.ProductCode IN :productCodeList AND COMM_Active__c = TRUE
            WITH USER_MODE
            ORDER BY COMM_Product__r.ProductCode, COMM_ValidFrom__c, COMM_ValidTo__c, lastModifiedDate, Name
        ];
    }

    /**
     * @description Lock Capacity Records to process.
     *
     * @param capacityIdSet Set of COMM_Capacity__c Ids
     */
    public void lockCapacityRecords(Set<Id> capacityIdSet) {
        List<COMM_Capacity__c> capacityList = [
            SELECT Id
            FROM COMM_Capacity__c
            WHERE id IN :capacityIdSet
            WITH USER_MODE
            FOR UPDATE
        ];
    }

    /**
     * @description Get Capacity records for Product
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @return List of Capacities of a Product
     */
    public List<COMM_Capacity__c> getCapacityByProductIds(Set<String> productIds) {
        return [
            SELECT Id, COMM_Product__c, COMM_Product__r.ProductCode, COMM_ValidTo__c, COMM_Capacity__c
            FROM COMM_Capacity__c
            WHERE COMM_Product__c IN :productIds AND COMM_Active__c = TRUE
            WITH SECURITY_ENFORCED
            ORDER BY COMM_ValidTo__c ASC
        ];
    }
}