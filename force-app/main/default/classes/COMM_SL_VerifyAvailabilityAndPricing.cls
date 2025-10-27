/**
 * @author Daniel Lascas
 * @description Service Layer class to verify if a Product is available and
 * pricing exists for it
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/04/2024       Original version
 **/
public inherited sharing class COMM_SL_VerifyAvailabilityAndPricing {
    private COMM_IREP_Product2 productRep;
    private COMM_IREP_PricebookEntry priceBookEntryRep;

    /**
     * @description Initialize REP
     */
    public COMM_SL_VerifyAvailabilityAndPricing() {
        this.productRep = new COMM_REP_Product2();
        this.priceBookEntryRep = new COMM_REP_PricebookEntry();
    }

    @TestVisible
    private COMM_SL_VerifyAvailabilityAndPricing(COMM_IREP_Product2 productRep, COMM_IREP_PricebookEntry priceBookEntryRep) {
        this.productRep = productRep;
        this.priceBookEntryRep = priceBookEntryRep;
    }

    /**
     * @description Verify if Products are available and have pricing
     *
     * @param productCodeSet Set with Product Codes to verify
     * @param hasAvailabilitySet Set with Product Code of Products with Availability
     * @param hasPricingSet Set with Product Code of Products with Pricing
     * @return Set of Product Codes that are available and have pricing
     */
    public Set<String> verifyProductHasPricingAndAvailableByCode(
        Set<String> productCodeSet,
        Set<String> hasAvailabilitySet,
        Set<String> hasPricingSet
    ) {
        Map<String, Decimal> availabilityMap = verifyProductAvailabilityByCode(productCodeSet);
        Map<String, Decimal> pricingMap = verifyProductPricingByCode(productCodeSet);

        hasAvailabilitySet.addAll(availabilityMap.keySet());
        hasPricingSet.addAll(pricingMap.keySet());

        Set<String> productsAvailableWithPricing = new Set<String>();

        for (String availableCode : availabilityMap.keySet()) {
            if (pricingMap.containsKey(availableCode)) {
                productsAvailableWithPricing.add(availableCode);
            }
        }
        return productsAvailableWithPricing;
    }

    /**
     * @description Verify if Products are available
     *
     * @param productCodeSet Set with Product Codes to verify
     * @return Map of available codes. Value is the capacity available.
     */
    private Map<String, Decimal> verifyProductAvailabilityByCode(Set<String> productCodeSet) {
        Map<String, Decimal> availabilityMap = new Map<String, Decimal>();

        Map<String, List<String>> productsToVerifyParentMap = new Map<String, List<String>>();
        verifyAvailability(productCodeSet, availabilityMap, productsToVerifyParentMap);

        //Check Product's Parent Capacity if required (for Child Lounge/Subscription Products)
        if (!productsToVerifyParentMap.isEmpty()) {
            for (Product2 productRecord : productRep.getProductAndCapacitiesByProductCodes(productsToVerifyParentMap.keySet())) {
                if (!productRecord.Capacities__r.isEmpty()) {
                    for (String childCode : productsToVerifyParentMap.get(productRecord.ProductCode)) {
                        availabilityMap.put(childCode, productRecord.Capacities__r[0].COMM_CalculatedCapacity__c);
                    }
                }
            }
        }

        return availabilityMap;
    }

    /**
     * @description Method to verify if a Product is available.
     * If Product is a Child of Lounge or Subscription Category
     * then an additional check for Parent is required.
     *
     * @param productCodeSet Set with the Product Codes to check for availability
     * @param availabilityMap Map with availability for Product Code, where Value is
     * the available capacity number
     * @param productsToVerifyParentMap Map of Products that required checking parents
     * for availability. Key is Parent Product Code, Value is List of Child Products that
     * are being checked.
     */
    private void verifyAvailability(
        Set<String> productCodeSet,
        Map<String, Decimal> availabilityMap,
        Map<String, List<String>> productsToVerifyParentMap
    ) {
        for (Product2 productRecord : productRep.getProductAndCapacitiesByProductCodes(productCodeSet)) {
            //Verify if Product has a Parent (is Child) and is Lounge or Subscription Category. If it is then a check for parent Capacity is required.
            if (
                String.isNotBlank(productRecord.COMM_ParentProduct__c) &&
                (COMM_DO_Product2.CATEGORY_LOUNGE.equals(productRecord.Family) || COMM_DO_Product2.CATEGORY_SUBSCRIPTION.equals(productRecord.Family))
            ) {
                if (!productsToVerifyParentMap.containsKey(productRecord.COMM_ParentProduct__r.ProductCode)) {
                    productsToVerifyParentMap.put(productRecord.COMM_ParentProduct__r.ProductCode, new List<String>());
                }
                productsToVerifyParentMap.get(productRecord.COMM_ParentProduct__r.ProductCode).add(productRecord.ProductCode);
            } else if (!productRecord.Capacities__r.isEmpty()) {
                availabilityMap.put(productRecord.ProductCode, productRecord.Capacities__r[0].COMM_CalculatedCapacity__c);
            }
        }
    }

    /**
     * @description Verify if Products have pricing setup
     *
     * @param productCodeSet Set with Product Codes to verify
     * @return Map of available codes. Value is the pricing available at current date
     */
    private Map<String, Decimal> verifyProductPricingByCode(Set<String> productCodeSet) {
        Map<String, Decimal> pricingMap = new Map<String, Decimal>();

        List<PricebookEntry> priceBookEntriesList = priceBookEntryRep.getPBEByProductCodeList(productCodeSet);
        if (!priceBookEntriesList.isEmpty()) {
            Map<PricebookEntry, Decimal> priceByPBE = new COMM_SL_PricingCalculation()
                .getPriceByPBE(priceBookEntriesList, System.today(), System.today());

            for (PricebookEntry priceBookEntry : priceByPBE.keySet()) {
                pricingMap.put(priceBookEntry.Product2.ProductCode, priceByPBE.get(priceBookEntry));
            }
        }
        return pricingMap;
    }
}