/**
 * @author Daniel Reto
 * @description COMM_ProductLocationsStock__c repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto    08/05/2024       Original version
 **/
public inherited sharing class COMM_REP_ProductLocationStock extends FW_SobjectRep implements COMM_IREP_ProductLocationStock {
    
    /**
     * @description Get ProductLocationStock records to erase.
     *
     * @param productIds Set of Product Id's related with Product Locations Stock
     * @param initialDate Reference Date, to get older records
     * @return List of Product Locations Stock Records
     */
    public List<COMM_ProductLocationStock__c> getProductLocationStockToErase(List<String> productIds, Date initialDate) {
        return [
            SELECT Id
            FROM COMM_ProductLocationStock__c
            WHERE COMM_Product__c IN :productIds AND COMM_StockDate__c <: initialDate
            WITH USER_MODE
        ];
    }

    /**
     * @description Get ProductLocationStock where Occupancy Rate is higher than the related Product2 Alarmistic %.
     *
     * @param productLocationStockIds Set of Product Location Stock Id's
     * @return List of Product Locations Stock Records
     */
    public List<COMM_ProductLocationStock__c> getProductLocationStockToErase() {
        return [
            SELECT Id, COMM_Product__c, COMM_Product__r.Name, COMM_Product__r.COMM_Alarmistic__c, toLabel(COMM_Product__r.Family)
            FROM COMM_ProductLocationStock__c
            WHERE COMM_AlarmisticPercExceeded__c = TRUE
            WITH USER_MODE
        ];
    }
}