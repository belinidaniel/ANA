/**
 * @author Daniel Reto
 * @description COMM_ProductLocationsStock__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      08/05/2024       Original version
 **/
public interface COMM_IREP_ProductLocationStock extends FW_ISObjectRep {

    /**
     * @description Get ProductLocationsStock records to erase.
     *
     * @param productIds Set of Product Id's related with Product Locations Stock
     * @param initialDate Reference Date, to get older records
     * @return List of Product Locations Stock Records
     */
    List<COMM_ProductLocationStock__c> getProductLocationStockToErase(List<String> productIds, Date initialDate);
    /**
     * @description Get ProductLocationStock where Occupancy Rate is higher than the related Product2 Alarmistic %.
     *
     * @param productLocationStockIds Set of Product Location Stock Id's
     * @return List of Product Locations Stock Records
     */
    List<COMM_ProductLocationStock__c> getProductLocationStockToErase();
}