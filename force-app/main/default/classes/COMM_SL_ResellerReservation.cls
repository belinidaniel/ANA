/**
 * @author Diogo Gonçalves
 * @description Service to reserve the availability of reseller product.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  21/05/2024       Original version
 **/
public with sharing class COMM_SL_ResellerReservation {
    private static final BOOLEAN DO_RESERVE = true;
    private static final BOOLEAN DO_RELEASE = false;

    /**
     * @description Reserve stock for the products of a given reseller
     * @param productQuantities - map containing the quantity to reserve by product code
     * @param resellerAccountId - account id of the reseller
     * @param isReserve - if true subtracts quantities to daily count, adds if false
     */
    public static void reserve(Map<String, Integer> productQuantities, Id resellerAccountId) {
        updateDailyCount(productQuantities, resellerAccountId, DO_RESERVE);
    }

    /**
     * @description Release stock for the products of a given reseller
     * @param productQuantities - map containing the quantity to reserve by product code
     * @param resellerAccountId - account id of the reseller
     * @param isReserve - if true subtracts quantities to daily count, adds if false
     */
    public static void release(Map<String, Integer> productQuantities, Id resellerAccountId) {
        updateDailyCount(productQuantities, resellerAccountId, DO_RELEASE);
    }

    /**
     * @description Update the DailyCount with the given quantities for a reseller
     * @param productQuantities - map containing the quantity to reserve by product code
     * @param resellerAccountId - account id of the reseller
     * @param isReserve - if true subtracts quantities to daily count, adds if false
     */
    private static void updateDailyCount(Map<String, Integer> productQuantities, Id resellerAccountId, Boolean isReserve) {
        COMM_IREP_ResellerAssortment assortmentRepo = new COMM_REP_ResellerAssortment();
        Map<String, SObject> assortmentsByProductCode = getAssortmentsByProductCode(
            assortmentRepo.getForStockReserve(productQuantities.keySet(), resellerAccountId)
        );
        Integer totalProducts = productQuantities.size();

        Integer totalAssortments = assortmentsByProductCode.size();
        if (totalProducts > totalAssortments) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.UNAUTHORIZED_PRODUCTS,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.UNAUTHORIZED_PRODUCTS)
            );
        }

        List<COMM_ResellerAssortment__c> assortmentsToUpdate = new List<COMM_ResellerAssortment__c>();

        for (String productCode : assortmentsByProductCode.keySet()) {
            COMM_ResellerAssortment__c assortment = (COMM_ResellerAssortment__c) assortmentsByProductCode.get(productCode);
            Integer quantity = productQuantities.get(productCode) * (isReserve ? 1 : -1);
            Decimal newDailyCount = assortment.COMM_CurrentDailyQuantity__c + quantity;
            if (isReserve && newDailyCount > assortment.COMM_DailyLimit__c) {
                throw new COMM_SL_ResellerOrderException(
                    COMM_CommerceAPI_Constants.QUANTITY_EXCEEDS_LIMIT,
                    COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.QUANTITY_EXCEEDS_LIMIT)
                );
            } else if (newDailyCount < 0) {
                newDailyCount = 0;
            }
            assortment.COMM_CurrentDailyQuantity__c = newDailyCount;
            assortmentsToUpdate.add(assortment);
        }

        if (!assortmentsToUpdate.isEmpty()) {
            assortmentRepo.updateSObjects(assortmentsToUpdate);
        }
    }

    /**
     * @description Convert assortment list to map by product code
     * @param arrortmentList List<COMM_ResellerAssortment__c>
     * @return Map<String, COMM_ResellerAssortment__c>
     */
    private static Map<String, COMM_ResellerAssortment__c> getAssortmentsByProductCode(List<COMM_ResellerAssortment__c> arrortmentList) {
        Map<String, COMM_ResellerAssortment__c> arrortmentByProductCodeMap = new Map<String, COMM_ResellerAssortment__c>();
        for (COMM_ResellerAssortment__c assortment : arrortmentList) {
            String productCode = assortment.COMM_Product__r.ProductCode;
            arrortmentByProductCodeMap.put(productCode, assortment);
        }
        return arrortmentByProductCodeMap;
    }
}