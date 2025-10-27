/**
 * @author Carlos Fusco
 * @description Service Layer class to set Product Reservation for new Subscriptions request
 * process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco     28/03/2024       Original version
 * Jose Passos      02/05/2024       Update ociReservation.reserve to request Prices as this is a parent product
 **/
public inherited sharing class COMM_SL_SetProductReservation {
    private static COMM_IREP_Product2 productRep = new COMM_REP_Product2();
    /**
     * @description Wrapper definition with variable set from Flow
     */
    public class InputWrapper {
        @InvocableVariable(label='Codes' description='Product Codes')
        public List<String> codes;
    }

    /**
     * @description Set product reservation
     *
     * @param inputWrapper Wrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    @InvocableMethod(label='Set Product Reservation' description='Set Product Reservation depending on chosen product code')
    public static List<List<COMM_SL_FlowChoice>> setProductReservation(List<InputWrapper> inputWrapper) {
        InputWrapper inputs = inputWrapper.get(0);
        List<COMM_SL_FlowChoice> flowChoices = new List<COMM_SL_FlowChoice>();

        List<String> codes = inputWrapper.get(0).codes;
        setReserve(codes);
        flowChoices.add(new COMM_SL_FlowChoice());

        return new List<List<COMM_SL_FlowChoice>>{ flowChoices };
    }

    /**
     * @description Call OCI reservation service
     *
     * @param codes Product codes to reserve
     */
    @future(callout=true)
    private static void setReserve(List<String> codes) {
        List<Product2> productsList = new List<Product2>();
        Map<String, List<Product2>> productsByParentMap = new Map<String, List<Product2>>();
        List<COMM_Capacity__c> capacitiesList = new List<COMM_Capacity__c>();
        Map<String, COMM_Capacity__c> capacityByProductCodeMap = new Map<String, COMM_Capacity__c>();

        productsList = productRep.getProductsByProductCodes(codes).values();

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
                capacityByProductCodeMap.put(currentProduct.ProductCode, capacity);
            }
        }

        COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
        input.expirationSeconds = 0;
        input.product = new List<COMM_WS_ReservationInput.Product>();

        for (String code : codes) {
            COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
            product.productId = capacityByProductCodeMap.get(code).COMM_Product__r.ProductCode;
            product.startDate = System.now();
            product.endDate = capacityByProductCodeMap.get(code).COMM_ValidTo__c;
            input.product.add(product);
        }

        COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
        ociReservation.reserve(input, false);
    }
}