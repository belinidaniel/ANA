/**
 * @author Carlos Fusco
 * @description Service Layer class to get Product Availability for new Subscriptions request
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco   28/03/2024       Original version
 * Daniel Reto    02/05/2024       ECOMM-957
 * Daniel Reto    07/05/2024       ECOMM-281
 **/
public inherited sharing class COMM_SL_GetProductAvailability {
    private static COMM_IREP_Product2 productRep = new COMM_REP_Product2();
    /**
     * @description Get product pricing information
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    public static Map<String, Integer> getProductAvailability(List<COMM_SL_GetProductPrice.InputWrapper> inputWrapper) {
        List<Product2> productsList = new List<Product2>();
        Map<String, List<Product2>> productsByParentMap = new Map<String, List<Product2>>();
        List<COMM_Capacity__c> capacitiesList = new List<COMM_Capacity__c>();
        Map<String, COMM_Capacity__c> capacityByProducCodeMap = new Map<String, COMM_Capacity__c>();
        Map<String, Integer> quantitiesByProductCodeMap = new Map<String, Integer>();

        productsList = productRep.getProductsByProductCodes(inputWrapper.get(0).codes).values();

        for (Product2 product : productsList) {
            if (!productsByParentMap.containsKey(product.COMM_ParentProduct__c)) {
                productsByParentMap.put(product.COMM_ParentProduct__c, new List<Product2>());
            }
            productsByParentMap.get(product.COMM_ParentProduct__c).add(product);
        }

        COMM_REP_Capacity capacityRep = new COMM_REP_Capacity();
        capacitiesList = capacityRep.getCapacityByProductIds(productsByParentMap.keySet());

        for (COMM_Capacity__c capacity : capacitiesList) {
            List<Product2> productsToProcess = productsByParentMap.get(capacity.COMM_Product__c);

            for (Product2 currentProduct : productsToProcess) {
                capacityByProducCodeMap.put(currentProduct.ProductCode, capacity);
            }
        }

        for (String productCode : capacityByProducCodeMap.keySet()) {
            COMM_WS_AvailabilityInput input = new COMM_WS_AvailabilityInput();
            COMM_WS_AvailabilityInput.Product productRecordInput = new COMM_WS_AvailabilityInput.Product();
            productRecordInput.productId = capacityByProducCodeMap.get(productCode).COMM_Product__r.ProductCode;
            productRecordInput.startDate = System.today();
            productRecordInput.endDate = capacityByProducCodeMap.get(productCode).COMM_ValidTo__c;
            input.products = new List<COMM_WS_AvailabilityInput.Product>{ productRecordInput };

            COMM_SL_WS_OCIAvailability ociAvailability = new COMM_SL_WS_OCIAvailability();
            COMM_WS_AvailabilityOutput output = ociAvailability.checkAvailability(input, true);

            for (COMM_WS_AvailabilityOutput.Product product : output.products) {
                if (product.available > 0) {
                    quantitiesByProductCodeMap.put(productCode, product.available.intValue());
                }
            }
        }

        return quantitiesByProductCodeMap;
    }
}