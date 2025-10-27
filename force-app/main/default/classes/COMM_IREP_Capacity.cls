/**
 * @author Daniel Lascas
 * @description COMM_Capacity__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024       Original version
 * Jose Passos      10/04/2024       Added methods getCapacityRecordsToProcessByProductCodes
 * Jose Passos      10/05/2024       Added methods lockCapacityRecordsToProcessTest
 **/
public interface COMM_IREP_Capacity extends FW_ISObjectRep {
    /**
     * @description Get non-default Capacity Records that have specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return List of Queried Capacity Records
     */
    List<COMM_Capacity__c> getNonDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds);
    /**
     * @description Get Count of non-default Capacity Records for specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return Aggregated Result List with Count of Active non-default Capacity Records for each Product
     */
    List<COMM_Capacity__c> getCountNonDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds);
    /**
     * @description Get Count of default Capacity Records for specific Products.
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @param capacityIds Set of Capacity Id's to remove from query
     * @return Aggregated Result List with Count of Active default Capacity Records for each Product
     */
    List<COMM_Capacity__c> getCountDefaultCapacityByProductIds(Set<Id> productIds, Set<Id> capacityIds);
    /**
     * @description Get Capacity records to be processed by Stock Upload for a List of specific Products.
     *
     * @param productCodeList List of ProductCodes
     * @param processStatusList List of Status to consider for processing
     * @return Result List with capacity records to process
     */
    List<COMM_Capacity__c> getCapacityRecordsToProcessByProductCodes(List<String> productCodeList, List<String> processStatusList);
    /**
     * @description Lock Capacity Records to process.
     *
     * @param capacityIdSet Set of COMM_Capacity__c Ids
     */
    void lockCapacityRecords(Set<Id> capacityIdSet);
    /**
     * @description Get Capacity records for Product
     *
     * @param productIds Set of Product Id's to find Capacities for
     * @return Result List with capacity records to process
     */
    List<COMM_Capacity__c> getCapacityByProductIds(Set<String> productIds);
}