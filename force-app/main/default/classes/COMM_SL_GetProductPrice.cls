/**
 * @author Carlos Fusco
 * @description Service Layer class to get Product Price for new Subscriptions request
 * process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco   21/03/2024       Original version
 **/
public inherited sharing class COMM_SL_GetProductPrice {
    /**
     * @description Wrapper definition with variable set from Flow
     */
    public class InputWrapper {
        @InvocableVariable(label='Subcategories' description='Product Sub-Categories')
        public String subCategories;
        @InvocableVariable(label='Airports' description='Product Airports')
        public String airports;
        @InvocableVariable(label='Categories' description='Product Categories')
        public String categories;
        @InvocableVariable(label='Periodicities' description='Product Periodicities')
        public String periodicities;
        @InvocableVariable(label='Codes' description='Product Codes')
        public List<String> codes;
        @InvocableVariable(label='Quantities' description='Product Quantities')
        public Decimal quantities;
    }

    /**
     * @description Get product pricing information
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    @InvocableMethod(label='Get Product Price' description='Get Product Prices depending on inputs')
    public static List<List<COMM_SL_FlowChoice>> getProductPrice(List<InputWrapper> inputWrapper) {
        List<COMM_SL_FlowChoice> flowChoices = new List<COMM_SL_FlowChoice>();
        Map<String, Integer> availableProductCodes = new Map<String, Integer>();
        Map<String, Double> availableQuantitiesByProductCode = new Map<String, Double>();
        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        Map<PricebookEntry, Decimal> priceByPBE = new Map<PricebookEntry, Decimal>();

        availableProductCodes = COMM_SL_GetProductAvailability.getProductAvailability(inputWrapper);

        COMM_REP_PricebookEntry priceBookEntryREP = new COMM_REP_PricebookEntry();
        priceBookEntries = priceBookEntryREP.getPBEByProductCodeList(availableProductCodes.keySet());

        COMM_SL_PricingCalculation pricingCalculationService = new COMM_SL_PricingCalculation();
        priceByPBE = pricingCalculationService.getPriceByPBE(priceBookEntries, System.today(), System.today());

        for (PricebookEntry priceBookEntry : priceByPBE.keySet()) {
            if (isProductAvailableForSelection(inputWrapper.get(0), priceBookEntry)) {
                flowChoices.add(
                    new COMM_SL_FlowChoice(
                        priceBookEntry.Product2.Id,
                        priceBookEntry.Product2.Name,
                        priceBookEntry.UnitPrice,
                        inputWrapper.get(0).periodicities,
                        priceBookEntry.Product2.COMM_Tax__c,
                        priceBookEntry.Product2.ProductCode,
                        availableProductCodes.get(priceBookEntry.Product2.ProductCode)
                    )
                );
            }
        }

        return new List<List<COMM_SL_FlowChoice>>{ flowChoices };
    }

    /**
     * @description Check if the available products details match options entered in screen flow
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @param priceBookEntry Price Book Entry related on available products
     * @return Boolean flagging if product should be available for User selection in screen flow
     */
    public static Boolean isProductAvailableForSelection(InputWrapper inputWrapper, PricebookEntry priceBookEntry) {
        return priceBookEntry.UnitPrice > 0 &&
            priceBookEntry.Product2.COMM_SubCategory__c == inputWrapper.subCategories &&
            priceBookEntry.Product2.COMM_Periodicity__c == inputWrapper.periodicities &&
            priceBookEntry.Product2.COMM_Airport__c == inputWrapper.airports;
    }
}