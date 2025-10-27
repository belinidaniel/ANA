/**
 * @author Daniel Reto
 * @description Service Layer class to get Product Periodicity for a Periodicity Change Subscriptions request
 * process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      30/04/2024       Original version
 **/
public inherited sharing class COMM_SL_GetProductByPeriodicity {
    /**
     * @description Get product pricing information
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    @InvocableMethod(label='Get Product by Periodicity' description='Get Product by Periodicity depending on inputs')
    public static List<List<COMM_SL_FlowChoice>> getProductByPeriodicity(List<List<Product2>> productRecordList) {
        List<COMM_SL_FlowChoice> flowChoicesList = new List<COMM_SL_FlowChoice>();
        List<PricebookEntry> priceBookEntriesList = new List<PricebookEntry>();
        Map<PricebookEntry, Decimal> priceByPBEMap = new Map<PricebookEntry, Decimal>();
        Set<String> productCodeSet = new Set<String>();

        for (Product2 productRecord : productRecordList[0]) {
            productCodeSet.add(productRecord.ProductCode);
        }

        COMM_REP_PricebookEntry priceBookEntryREP = new COMM_REP_PricebookEntry();
        priceBookEntriesList = priceBookEntryREP.getPBEByProductCodeDataBaseQueryList(productCodeSet);

        COMM_SL_PricingCalculation pricingCalculationService = new COMM_SL_PricingCalculation();
        priceByPBEMap = pricingCalculationService.getPriceByPBE(priceBookEntriesList, System.today(), System.today());

        for (PricebookEntry pbe : priceByPBEMap.keySet()) {
            flowChoicesList.add(
                new COMM_SL_FlowChoice(
                    pbe.Product2Id,
                    pbe.Product2.Name,
                    pbe.UnitPrice,
                    pbe.Product2.COMM_Periodicity__c,
                    (String) pbe.Product2.get('productPeriodicityLabel')
                )
            );
        }

        return new List<List<COMM_SL_FlowChoice>>{ flowChoicesList };
    }
}