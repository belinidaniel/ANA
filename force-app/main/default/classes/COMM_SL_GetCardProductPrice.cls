/**
 * @author Daniel Reto
 * @description Service Layer class to get Card Product Price for Subscriptions request
 * process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto     10/05/2024       Original version
 **/
public inherited sharing class COMM_SL_GetCardProductPrice {
    /**
     * @description Get Card product pricing information
     *
     * @param productCodeValue Product Code from Flow
     * @return product related PricebookEntry
     */
    @InvocableMethod(label='Get Card Product Price' description='Get Card Product Prices depending on inputs')
    public static List<PricebookEntry> getCardProductPrice(List<String> productCodeList) {
        Set<String> productCodeSet = new Set<String>();
        productCodeSet.addAll(productCodeList);
        List<PricebookEntry> priceBookEntriesList = new List<PricebookEntry>();
        Map<PricebookEntry, Decimal> priceByPBEMap = new Map<PricebookEntry, Decimal>();
        List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();

        COMM_REP_PricebookEntry priceBookEntryREP = new COMM_REP_PricebookEntry();
        priceBookEntriesList = priceBookEntryREP.getPBEByProductCodeList(productCodeSet);

        COMM_SL_PricingCalculation pricingCalculationService = new COMM_SL_PricingCalculation();
        priceByPBEMap = pricingCalculationService.getPriceByPBE(priceBookEntriesList, System.today(), System.today());

        for (PricebookEntry pbe : priceByPBEMap.keySet()) {
            priceBookEntryList.add(pbe);
        }

        return priceBookEntryList.isEmpty() ? null : priceBookEntryList;
    }
}