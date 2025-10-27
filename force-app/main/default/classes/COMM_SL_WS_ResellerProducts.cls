/**
 * @author Daniel Lascas
 * @description Class to verify the availability of products for resellers.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/05/2024       ECOMM-386: Original version
 * Daniel Reto      25/10/2024       ECOMM-327: Commerce API update
 * Daniel Reto      04/11/2024       ECOMM-327: Commerce API update
 **/
public with sharing class COMM_SL_WS_ResellerProducts {
    private COMM_IREP_Account accountRep;
    private COMM_IREP_ProductVariations variationRep;
    private COMM_SL_WS_OCIAvailability ociAvailability;
    private COMM_IREP_PricebookEntry pbeRep;
    private COMM_SL_PricingCalculation pricingSl;
    private COMM_IDO_ResellerApiMapping apiMappingDo;

    //JSON Fields
    private static final String MIN_RESELLER_PRICE_KEY = 'minResellerPrice';
    private static final String STOCK_AVAILABILITY_KEY = 'stockAvailability';
    private static final String START_DATE_KEY = 'startDate';
    private static final String END_DATE_KEY = 'endDate';
    private static final String PRODUCT_QUANTITY_KEY = 'productQuantity';
    private static final String BUNDLE_ITEMS_KEY = 'bundleProduct';
    private static final String PRODUCTS_KEY = 'product';

    private static final String PRODUCT_SKU_KEY = 'productId';

    //Default Values
    private static final Integer DEFAULT_PAGE = 0;
    private static final Integer DEFAULT_PAGE_SIZE = 100;

    //Custom Error Messages
    private static final String NO_RESELLER_FOUND = 'no active reseller account found with provided Id';
    private static final String REQUIRED_FIELD_MISSING = 'request has data missing: ';

    //Required fields
    private static final String RESELLER_ID_KEY = 'resellerId';
    private static final String PAGE_KEY = 'page';
    private static final String PAGE_SIZE_KEY = 'pageSize';

    /**
     * @description Class Constructor to initialize REP and SL
     */
    public COMM_SL_WS_ResellerProducts() {
        this.accountRep = new COMM_REP_Account();
        this.variationRep = new COMM_REP_ProductVariations();
        this.ociAvailability = new COMM_SL_WS_OCIAvailability();
        this.pbeRep = new COMM_REP_PricebookEntry();
        this.pricingSl = new COMM_SL_PricingCalculation();
        this.apiMappingDo = new COMM_DO_ResellerApiMapping();
    }

    @TestVisible
    private COMM_SL_WS_ResellerProducts(
        COMM_IREP_Account accountRep,
        COMM_IREP_ProductVariations variationRep,
        COMM_SL_WS_OCIAvailability ociAvailability,
        COMM_IREP_PricebookEntry pbeRep,
        COMM_SL_PricingCalculation pricingSl,
        COMM_IDO_ResellerApiMapping apiMappingDo
    ) {
        this.accountRep = accountRep;
        this.variationRep = variationRep;
        this.ociAvailability = ociAvailability;
        this.pbeRep = pbeRep;
        this.pricingSl = pricingSl;
        this.apiMappingDo = apiMappingDo;
    }

    /**
     * @description Method to verify reseller stock
     *
     * @param requestJSON Request Body in the form of a JSON
     * @return Response to be sent by the API
     */
    public COMM_SL_WS_ResellerSearchResponse getResellerStock(String requestJSON) {
        //Parse data from Request
        COMM_SL_WS_ResellerSearchRequest requestObject = COMM_SL_WS_ResellerSearchRequest.parse(requestJSON);

        //Verify Request has required fields
        if (requestObject.resellerId == null || requestObject.page == null || requestObject.pageSize == null) {
            Set<String> missingList = new Set<String>{
                requestObject.resellerId == null ? RESELLER_ID_KEY : null,
                requestObject.page == null ? PAGE_KEY : null,
                requestObject.pageSize == null ? PAGE_SIZE_KEY : null
            };
            missingList.remove(null);
            throw new COMM_RestServices_Utility.RestServiceException(REQUIRED_FIELD_MISSING + missingList);
        }

        String resellerId = requestObject.resellerId;
        String airportCode = requestObject.airportId;
        String category = requestObject.productCategory;
        Datetime startDate = requestObject.startDate;
        Datetime endDate = requestObject.endDate;
        Integer page = requestObject.page;
        Integer pageSize = requestObject.pageSize;

        List<Account> accountList = accountRep.getResellerAccountProducts(resellerId, airportCode, category);
        //Verify if Reseller Account exists
        if (accountList.isEmpty() || !accountList[0].COMM_IsReseller__c) {
            throw new COMM_RestServices_Utility.RestServiceException(NO_RESELLER_FOUND);
        }

        Set<Id> bundleProductIdSet = new Set<Id>();
        Set<Id> resellerProductIdSet = new Set<Id>();
        Set<Id> resellerPricebookIdSet = new Set<Id>();

        ///Map of OCI Product Code by Product Code (in some scenarios we need to use the Parent Product Code)
        Map<String, String> ociProductCodeByProductCodeMap = new Map<String, String>();

        //Verify Reseller Products
        List<COMM_WS_AvailabilityInput.Product> productToSearchList = verifyAssortment(
            accountList[0].ResellerAssortments__r,
            bundleProductIdSet,
            resellerProductIdSet,
            resellerPricebookIdSet,
            startDate,
            endDate,
            ociProductCodeByProductCodeMap
        );

        //Verify Product Variation Records for Bundle Products
        Map<Id, List<COMM_WS_AvailabilityInput.Product>> productInBundleToSearchMap = new Map<Id, List<COMM_WS_AvailabilityInput.Product>>();
        Map<Id, List<COMM_ProductVariations__c>> bundleVariationMap = verifyBundleVariations(
            bundleProductIdSet,
            startDate,
            productInBundleToSearchMap,
            ociProductCodeByProductCodeMap
        );

        //Verify Availability in OMS for Reseller Products. If startDate or endDate is missing, skip verification.
        Map<String, COMM_WS_AvailabilityOutput.Product> availabilityByProductCodeMap = (startDate != null &&
            endDate != null)
            ? getAvailabilityMap(productToSearchList)
            : new Map<String, COMM_WS_AvailabilityOutput.Product>();

        //Verify Availability in OMS for each Product in Reseller (products in bundles can have different end dates so a separate check is made)
        Map<Id, Map<String, COMM_WS_AvailabilityOutput.Product>> availabilityByBundleMap = getBundleAvailabilityMap(
            productInBundleToSearchMap,
            startDate,
            endDate
        );

        //Verify Product Reseller Pricing
        Map<String, Decimal> pricingMap = getPricingMap(resellerProductIdSet, resellerPricebookIdSet, startDate, endDate);

        //Build Response
        List<Map<String, Object>> productList = buidResponse(
            accountList[0].ResellerAssortments__r,
            availabilityByProductCodeMap,
            availabilityByBundleMap,
            bundleVariationMap,
            pricingMap,
            startDate,
            endDate,
            page,
            pageSize,
            ociProductCodeByProductCodeMap
        );
        Decimal resellerAssortmentsListSize = accountList[0].ResellerAssortments__r.size();
        Decimal maxPages = resellerAssortmentsListSize / (Decimal) pageSize;
        Long totalPages = maxPages.round(System.RoundingMode.CEILING);
        Map<String, Object> responseMap = new Map<String, Object>{
            'page' => page,
            'pageSize' => pageSize,
            'totalPages' => totalPages,
            PRODUCTS_KEY => productList
        };
        COMM_SL_WS_ResellerSearchResponse responseObject = COMM_SL_WS_ResellerSearchResponse.parse(JSON.serialize(responseMap));
        return responseObject;
    }

    /**
     * @description Verify Assortment List
     *
     * @param assortmentList List of Reseller Assortment Records belonging to Reseller Account
     * @param bundleProductIdSet Set of Ids where Reseller Products that are bundles will be stored
     * @param resellerProductIdSet Set of Ids where Reselller Product to Query will be stored
     * @param resellerPricebookIdSet Set of Ids where Reseller Pricebooks to Query will be stored
     * @param ociProductCodeByProductCodeMap Map between OCI Product Code and Product Code
     * @return List of Availability Input Request Wrapper (to query OCI for Current Stock Availability)
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private List<COMM_WS_AvailabilityInput.Product> verifyAssortment(
        List<COMM_ResellerAssortment__c> assortmentList,
        Set<Id> bundleProductIdSet,
        Set<Id> resellerProductIdSet,
        Set<Id> resellerPricebookIdSet,
        Datetime startDate,
        Datetime endDate,
        Map<String, String> ociProductCodeByProductCodeMap
    ) {
        List<COMM_WS_AvailabilityInput.Product> productToSearchList = new List<COMM_WS_AvailabilityInput.Product>();
        for (COMM_ResellerAssortment__c assortment : assortmentList) {
            //Verify if Product is a Bundle. If it is then add Id to set to obtain bundle products.
            if (COMM_DO_Product2.PRODUCT_TYPE_BUNDLE.equals(assortment.COMM_Product__r.COMM_ProductType__c)) {
                bundleProductIdSet.add(assortment.COMM_Product__c);
            } else {
                String ociProductCode = assortment.COMM_Product__r.COMM_ParentProduct__c == null ? assortment.COMM_Product__r.ProductCode : assortment.COMM_Product__r.COMM_ParentProductCode__c;
                COMM_WS_AvailabilityInput.Product productToSearch = new COMM_WS_AvailabilityInput.Product();
                productToSearch.productId = ociProductCode;
                productToSearch.startDate = startDate;
                productToSearch.endDate = endDate;
                productToSearchList.add(productToSearch);
                ociProductCodeByProductCodeMap.put(assortment.COMM_Product__r.ProductCode, ociProductCode);
            }

            //Store Product and Pricebook Ids (to query for Pricing)
            resellerProductIdSet.add(assortment.COMM_Product__c);
            resellerPricebookIdSet.add(assortment.COMM_PriceBook__c);
        }
        return productToSearchList;
    }

    /**
     * @description Method to Verify Products that compose a Bundle
     *
     * @param bundleProductIdSet Set with the Id of Bundle Products to verify
     * @param startDate Startn date of when availability verification is checked
     * @param productInBundleToSearchMap Map to store Availability Request Objects for each Product in Bundle
     * @param ociProductCodeByProductCodeMap Map between OCI Product Code and Product Code
     * @return Map with list of Product Variations for each bundle.
     */
    private Map<Id, List<COMM_ProductVariations__c>> verifyBundleVariations(
        Set<Id> bundleProductIdSet,
        Datetime startDate,
        Map<Id, List<COMM_WS_AvailabilityInput.Product>> productInBundleToSearchMap,
        Map<String, String> ociProductCodeByProductCodeMap
    ) {
        Map<Id, List<COMM_ProductVariations__c>> bundleVariationMap = new Map<Id, List<COMM_ProductVariations__c>>();
        if (!bundleProductIdSet.isEmpty()) {
            for (COMM_ProductVariations__c variationRecord : variationRep.getProductVariationsByProductId(bundleProductIdSet)) {
                //End Date is sent to Start Date + Number of Hours set in Variation Record - 1
                Datetime productEndDate = startDate?.addHours(Integer.valueOf(variationRecord.COMM_NumberOfHours__c) - 1);

                String ociProductCode = variationRecord.COMM_RelatedProduct__r.COMM_ParentProduct__c == null ? variationRecord.COMM_RelatedProduct__r.ProductCode : variationRecord.COMM_RelatedProduct__r.COMM_ParentProductCode__c;
                COMM_WS_AvailabilityInput.Product productToSearch = new COMM_WS_AvailabilityInput.Product();
                productToSearch.productId = ociProductCode;
                productToSearch.startDate = startDate;
                productToSearch.endDate = productEndDate;
                ociProductCodeByProductCodeMap.put(variationRecord.COMM_RelatedProduct__r.ProductCode, ociProductCode);

                if (!productInBundleToSearchMap.containsKey(variationRecord.COMM_MasterProduct__c)) {
                    productInBundleToSearchMap.put(variationRecord.COMM_MasterProduct__c, new List<COMM_WS_AvailabilityInput.Product>());
                }
                productInBundleToSearchMap.get(variationRecord.COMM_MasterProduct__c).add(productToSearch);

                if (!bundleVariationMap.containsKey(variationRecord.COMM_MasterProduct__c)) {
                    bundleVariationMap.put(variationRecord.COMM_MasterProduct__c, new List<COMM_ProductVariations__c>());
                }
                bundleVariationMap.get(variationRecord.COMM_MasterProduct__c).add(variationRecord);
            }
        }
        return bundleVariationMap;
    }

    /**
     * @description Method to obtain product availability as a Map where Key is
     * Product Code and Value is current stock according to OMS.
     *
     * @param productToSearchList List of Products to search in OMS
     * @return Map with availability in OMS.
     */
    private Map<String, COMM_WS_AvailabilityOutput.Product> getAvailabilityMap(List<COMM_WS_AvailabilityInput.Product> productToSearchList) {
        Map<String, COMM_WS_AvailabilityOutput.Product> availabilityByProductCodeMap = new Map<String, COMM_WS_AvailabilityOutput.Product>();
        if (!productToSearchList.isEmpty()) {
            COMM_WS_AvailabilityInput inputRequest = new COMM_WS_AvailabilityInput();
            inputRequest.products = productToSearchList;
            COMM_WS_AvailabilityOutput output = ociAvailability.checkAvailability(inputRequest, true);
            for (COMM_WS_AvailabilityOutput.Product product : output.products) {
                if (product.available >= 0) {
                    availabilityByProductCodeMap.put(product.productId, product);
                }
            }
        }
        return availabilityByProductCodeMap;
    }

    /**
     * @description Method to obtain product availability for Products in a Bundle as a Map
     * where Key is Bundle Product Id and Value is List of Related Products with current stock according to OMS.
     *
     * @param productInBundleToSearchMap Map with List of Availability Request to send to OMS. Key is Bundle Product Id.
     * @return Map with availability in OMS where Key is Bundle Product Id.
     */
    private Map<Id, Map<String, COMM_WS_AvailabilityOutput.Product>> getBundleAvailabilityMap(
        Map<Id, List<COMM_WS_AvailabilityInput.Product>> productInBundleToSearchMap,
        Datetime startDate,
        Datetime endDate
    ) {
        //Verify Availability in OMS for each Product in Reseller (products in bundles can have different end dates so a separate check is made)
        Map<Id, Map<String, COMM_WS_AvailabilityOutput.Product>> availabilityByBundleMap = new Map<Id, Map<String, COMM_WS_AvailabilityOutput.Product>>();
        for (Id bundleId : productInBundleToSearchMap.keySet()) {
            List<COMM_WS_AvailabilityInput.Product> bundleProductToSearchList = productInBundleToSearchMap.get(bundleId);
            Map<String, COMM_WS_AvailabilityOutput.Product> availabilityForBundleMap = (startDate != null &&
                endDate != null)
                ? getAvailabilityMap(bundleProductToSearchList)
                : new Map<String, COMM_WS_AvailabilityOutput.Product>();
            availabilityByBundleMap.put(bundleId, availabilityForBundleMap);
        }
        return availabilityByBundleMap;
    }

    /**
     * @description Method to obtain available Pricing as a Map where Key is
     * Product Id + Pricebook Id and Value is cheapest pricing available
     *
     * @param resellerProductIdSet Set of Product Ids to check Pricing
     * @param resellerPricebookIdSet Set of Pricebook Ids to check Pricing
     * @param startDate Start Date of when Pricing starts
     * @param endDate End Date of when Pricing ends
     * @return Map with cheapest reseller pricing for the given time period
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Map<String, Decimal> getPricingMap(Set<Id> resellerProductIdSet, Set<Id> resellerPricebookIdSet, Datetime startDate, Datetime endDate) {
        Map<String, Decimal> pricingMap = new Map<String, Decimal>();
        if (!resellerProductIdSet.isEmpty() && startDate != null && endDate != null) {
            List<PricebookEntry> pbeList = pbeRep.getPBEByProductAndPricebookIds(resellerProductIdSet, resellerPricebookIdSet);
            Map<PricebookEntry, Decimal> pbeMap = pricingSl.getPriceByPBE(pbeList, startDate, endDate);
            for (PricebookEntry pbeRecord : pbeMap.keySet()) {
                String mapKey = (String) pbeRecord.Product2Id + (String) pbeRecord.Pricebook2Id;
                pricingMap.put(mapKey, pbeMap.get(pbeRecord));
            }
        }
        return pricingMap;
    }

    /**
     * @description Method to build response map to be sent
     *
     * @param assortmentList List of Reseller Assortment Records with Products available for the Reseller
     * @param availabilityByProductCodeMap Map with Available Stock for Products
     * @param bundleVariationMap Map with the List of Products that compose a Bundle
     * @param pricingMap Map with the Pricing available for Resellers
     * @param startDate Starting date for available products
     * @param endDate Ending date for available products
     * @param page starting page for available products
     * @param pageSize page size for available products
     * @param ociProductCodeByProductCodeMap Map between OCI Product Code and Product Code
     * @return Map in the form of a JSON with response to sent to reseller
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private List<Map<String, Object>> buidResponse(
        List<COMM_ResellerAssortment__c> assortmentList,
        Map<String, COMM_WS_AvailabilityOutput.Product> availabilityByProductCodeMap,
        Map<Id, Map<String, COMM_WS_AvailabilityOutput.Product>> availabilityByBundleMap,
        Map<Id, List<COMM_ProductVariations__c>> bundleVariationMap,
        Map<String, Decimal> pricingMap,
        Datetime startDate,
        Datetime endDate,
        Integer page,
        Integer pageSize,
        Map<String, String> ociProductCodeByProductCodeMap
    ) {
        List<Map<String, Object>> productList = new List<Map<String, Object>>();
        //Verify Response Paging
        Integer startingIndex = ((page-1) * pageSize);
        Integer maxItemIndex = page * pageSize;
        Integer maxIndex = maxItemIndex > assortmentList.size() ? assortmentList.size() : maxItemIndex;
        for (Integer index = startingIndex; index < maxIndex; index++) {
            COMM_ResellerAssortment__c assortmentRecord = assortmentList[index];
            String mapKey = (String) assortmentRecord.COMM_Product__c + (String) assortmentRecord.COMM_PriceBook__c;

            Map<String, Object> productMap = buildProductMap(assortmentRecord, startDate, endDate, availabilityByProductCodeMap, ociProductCodeByProductCodeMap);
            productMap.putAll(buildProductMap(assortmentRecord.COMM_Product__r, startDate, endDate, availabilityByProductCodeMap, ociProductCodeByProductCodeMap));

            productMap.put(MIN_RESELLER_PRICE_KEY, pricingMap.get(mapKey));
            if((Integer) productMap.get(STOCK_AVAILABILITY_KEY) > (Integer) assortmentRecord.COMM_AvailableDailyQuantity__c){
                productMap.put(STOCK_AVAILABILITY_KEY, (Integer) assortmentRecord.COMM_AvailableDailyQuantity__c);
            }

            //Verify if Product is a Bundle.
            if (COMM_DO_Product2.PRODUCT_TYPE_BUNDLE.equals(assortmentRecord.COMM_Product__r.COMM_ProductType__c)) {
                //Build list of Products in Bundle
                List<Map<String, Object>> bundleProductList = new List<Map<String, Object>>();
                Integer bundleStock;

                Map<String, COMM_WS_AvailabilityOutput.Product> availabilityForBundleProductMap = availabilityByBundleMap.get(
                    assortmentRecord.COMM_Product__c
                );
                for (COMM_ProductVariations__c bundleVariation : bundleVariationMap.get(assortmentRecord.COMM_Product__c)) {
                    Map<String, Object> productInBundleMap = buildProductMap(
                        bundleVariation.COMM_RelatedProduct__r,
                        availabilityForBundleProductMap.get(ociProductCodeByProductCodeMap.get(bundleVariation.COMM_RelatedProduct__r.ProductCode))?.startDate,
                        availabilityForBundleProductMap.get(ociProductCodeByProductCodeMap.get(bundleVariation.COMM_RelatedProduct__r.ProductCode))?.endDate,
                        availabilityForBundleProductMap,
                        ociProductCodeByProductCodeMap
                    );
                    productInBundleMap.put(PRODUCT_QUANTITY_KEY, bundleVariation.COMM_Quantity__c);
                    bundleProductList.add(productInBundleMap);

                    //Update Bundle Stock based on least available bundle item
                    bundleStock = getBundleStock(
                        bundleStock,
                        Integer.valueOf(bundleVariation.COMM_Quantity__c),
                        availabilityForBundleProductMap.get(ociProductCodeByProductCodeMap.get(bundleVariation.COMM_RelatedProduct__r.ProductCode))?.available.intValue()
                    );
                }
                productMap.put(BUNDLE_ITEMS_KEY, bundleProductList);

                //Set Bundle Stock based on least available bundle item but never more than the one available for the reseller to sell
                Integer resellerAvailableStock = (Integer) (bundleStock < assortmentRecord.COMM_AvailableDailyQuantity__c ? bundleStock : assortmentRecord.COMM_AvailableDailyQuantity__c);
                productMap.put(STOCK_AVAILABILITY_KEY, resellerAvailableStock);
                //Set Bundle Start and End dates
                productMap.put(START_DATE_KEY, startDate);
                productMap.put(END_DATE_KEY, endDate);
            }
            productList.add(productMap);
        }
        return productList;
    }

    /**
     * @description Obtain Bundle Stock from previous stock with bundle item
     * quantity and availability
     *
     * @param bundleStock Current Bundle Stock from processing previous bundle items
     * @param itemQuantity Quantity of currently processed bundle item
     * @param stock Stock Availability of currently processed bundle item
     * @return Updated Bundle Stock
     */
    private Integer getBundleStock(Integer bundleStock, Integer itemQuantity, Integer stock) {
        Decimal stockLimit = stock == null ? 0 : ((Decimal) stock / itemQuantity).setScale(0, RoundingMode.DOWN);
        return bundleStock == null || bundleStock > stockLimit ? Integer.valueOf(stockLimit) : bundleStock;
    }

    /**
     * @description Build Map for Product to be sent in response.
     *
     * @param sobjectRecord SObject Record with Product details to be mapped.
     * @param startDate Starting Date of when Product is available.
     * @param endDate End Date of when Product is available.
     * @param availabilityByProductCodeMap Map with available quantities.
     * @param ociProductCodeByProductCodeMap Map between OCI Product Code and Product Code
     * @return Map with values to pass to response JSON.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Map<String, Object> buildProductMap(
        SObject sobjectRecord,
        Datetime startDate,
        Datetime endDate,
        Map<String, COMM_WS_AvailabilityOutput.Product> availabilityByProductCodeMap,
        Map<String, String> ociProductCodeByProductCodeMap
    ) {
        Map<String, Object> productMap = apiMappingDo.mapJsonFromSObject(sobjectRecord, new Map<String, Object>());
        String productCode = ociProductCodeByProductCodeMap.get((String) productMap.get(PRODUCT_SKU_KEY));
        productMap.put(START_DATE_KEY, availabilityByProductCodeMap.get(productCode)?.startDate);
        productMap.put(END_DATE_KEY, availabilityByProductCodeMap.get(productCode)?.endDate);
        productMap.put(STOCK_AVAILABILITY_KEY, availabilityByProductCodeMap.get(productCode)?.available.intValue());
        return productMap;
    }
}