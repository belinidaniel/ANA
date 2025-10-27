/**
 * @author Jose Passos
 * @description Class to support the Web Service to verify the availability of products.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 * Jose Passos      29/04/2024       Changed to support SFCC before you go Page requirements
 * Daniel Reto      02/05/2024       ECOMM-957
 * Daniel Reto      07/05/2024       ECOMM-281
 **/
public inherited sharing class COMM_SL_WS_OCIAvailability {
    private COMM_IREP_Product2 productRep = new COMM_REP_Product2();
    private static String requestedDateTimesGMTOrLocal = COMM_OCI_Utils.DATETIME_GMT_STRING;
    /**
     * @description Check if there is enough stock in OCI for a set of products for specific dates in GMT
     * @param COMM_WS_AvailabilityInput inputRequest - Set of products and a range of start and end date
     * @param isAvailabilityServiceCall - boolean to identify if it's a call from Availability WebService to check the remaining availability.
     * @return COMM_WS_AvailabilityOutput output with list of products with the respective stock in OCI and requested dates
     */
    public COMM_WS_AvailabilityOutput checkAvailability(COMM_WS_AvailabilityInput inputRequest, Boolean isAvailabilityServiceCall) {
        return checkAvailability(inputRequest, isAvailabilityServiceCall, COMM_OCI_Utils.DATETIME_GMT_STRING);
    }

    /**
     * @description Check if there is enough stock in OCI for a set of products for specific dates
     * @param COMM_WS_AvailabilityInput inputRequest - Set of products and a range of start and end date
     * @param isAvailabilityServiceCall - boolean to identify if it's a call from Availability WebService to check the remaining availability.
     * @param inputDateTimeGMTOrLocal - string to identify if dates passed are in GMT or in product LOCAL timezone. Possible values GMT/LOCAL
     * @return COMM_WS_AvailabilityOutput output with list of products with the respective stock in OCI and requested dates
     */
    public COMM_WS_AvailabilityOutput checkAvailability(
        COMM_WS_AvailabilityInput inputRequest,
        Boolean isAvailabilityServiceCall,
        String inputDateTimeGMTOrLocal
    ) {
        // Set output
        COMM_WS_AvailabilityOutput output = new COMM_WS_AvailabilityOutput();
        List<String> distinctProductList = new List<String>();
        Map<String, COMM_WS_AvailabilityInput.Product> productInputMap = new Map<String, COMM_WS_AvailabilityInput.Product>();
        requestedDateTimesGMTOrLocal = (inputDateTimeGMTOrLocal == null) ? COMM_OCI_Utils.DATETIME_GMT_STRING : inputDateTimeGMTOrLocal;

        for (COMM_WS_AvailabilityInput.Product product : inputRequest.products) {
            if (product.startDate == null) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_START_DATE, null);
            }
            if (product.endDate == null) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_END_DATE, null);
            }
            if (product.startDate > product.endDate) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INVALID_DATE, null);
            }
            productInputMap.put(product.productId, product);
        }
        // get all distinct Products (no duplicates) to validate if there are all products exist in Product2
        distinctProductList.addAll(productInputMap.keySet());
        // get product Family from Product2
        Map<String, Product2> dbProductMap = productRep.getProductsByProductCodes(distinctProductList);
        if (productInputMap.size() != dbProductMap.size()) {
            List<String> productList = new List<String>();
            for (String productKey : productInputMap.keySet()) {
                if (!dbProductMap.containsKey(productKey)) {
                    productList.add(productKey);
                }
            }
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INVALID_PRODUCT, String.join(productList, ','));
        }
        // confirm time zone of each product being send to OCI
        if (!productInputMap.isEmpty() && requestedDateTimesGMTOrLocal == COMM_OCI_Utils.DATETIME_GMT_STRING) {
            for (String productCodeValue : productInputMap.keySet()) {
                productInputMap.get(productCodeValue).startDate = DateTime.valueOfGMT(
                    productInputMap.get(productCodeValue)
                        .startDate.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, dbProductMap.get(productCodeValue).COMM_TimeZoneByAirport__c)
                );
                productInputMap.get(productCodeValue).endDate = DateTime.valueOfGMT(
                    productInputMap.get(productCodeValue)
                        .endDate.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, dbProductMap.get(productCodeValue).COMM_TimeZoneByAirport__c)
                );
            }
            for (COMM_WS_AvailabilityInput.Product product : inputRequest.products) {
                product.startDate = productInputMap.get(product.productId).startDate;
                product.endDate = productInputMap.get(product.productId).endDate;
            }
        }

        // Map with products grouped by stock locations
        List<Product2> dbProductList = dbProductMap.values();
        Map<String, List<String>> productsMap = COMM_OCI_Utils.groupProductsByCategory(null, dbProductList);

        Map<String, List<String>> productDayByLocationMap = new Map<String, List<String>>();
        for (String family : productsMap.keySet()) {
            COMM_OCI_Utils.generateProductLocationList(family, inputRequest, productDayByLocationMap, productsMap);
        }

        Map<String, Double> productAvailableMap = new Map<String, Double>();
        Map<String, List<COMM_WS_AvailabilityOutput.ProductRecord>> inventoryAvailabilityByProductCodeMap = new Map<String, List<COMM_WS_AvailabilityOutput.ProductRecord>>();

        if (!productDayByLocationMap.isEmpty()) {
            checkAvailable(productAvailableMap, inventoryAvailabilityByProductCodeMap, productDayByLocationMap, isAvailabilityServiceCall);
        }

        if (isAvailabilityServiceCall) {
            output.products = new List<COMM_WS_AvailabilityOutput.Product>();
            for (String productCode : productAvailableMap.keySet()) {
                COMM_WS_AvailabilityOutput.Product outputProduct = new COMM_WS_AvailabilityOutput.Product();
                outputProduct.startDate = productInputMap.get(productCode).startDate;
                outputProduct.endDate = productInputMap.get(productCode).endDate;
                outputProduct.productId = productCode;
                outputProduct.available = productAvailableMap.get(productCode);
                output.products.add(outputProduct);
            }
        } else {
            output.inventory = new List<COMM_WS_AvailabilityOutput.InventoryRecord>();
            for (String productCode : inventoryAvailabilityByProductCodeMap.keySet()) {
                COMM_WS_AvailabilityOutput.InventoryRecord inventoryRecord = new COMM_WS_AvailabilityOutput.InventoryRecord();
                inventoryRecord.productCode = productCode;
                inventoryRecord.productList = inventoryAvailabilityByProductCodeMap.get(productCode);
                output.inventory.add(inventoryRecord);
            }
        }

        return output;
    }

    /**
     * @description Verify if products are available on the target locations.
     *
     * @param productAvailableMap - Products to verify.
     * @param inventoryAvailabilityByProductCodeMap - map of Output wrapper by Product Code.
     * @param productDayByLocationMap - The stock keeping units by locations.
     * @param isAvailabilityServiceCall - boolean to identify if it's a call from Availability WebService to check the remaining availability.
     */
    private static void checkAvailable(
        Map<String, Double> productAvailableMap,
        Map<String, List<COMM_WS_AvailabilityOutput.ProductRecord>> inventoryAvailabilityByProductCodeMap,
        Map<String, List<String>> productDayByLocationMap,
        Boolean isAvailabilityServiceCall
    ) {
        if (productDayByLocationMap != null && !productDayByLocationMap.isEmpty()) {
            ConnectApi.OCIGetInventoryAvailabilityInputRepresentation input = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
            for (String locationValue : productDayByLocationMap.keySet()) {
                input.locationIdentifiers = new List<String>{ locationValue };
                input.useCache = false;
                Integer index = 0;
                Integer count = 0;
                while (index < productDayByLocationMap.get(locationValue).size()) {
                    input.stockKeepingUnits = new List<String>();
                    while (true) {
                        String stockSku = productDayByLocationMap.get(locationValue)?.get(index);
                        String productSku = stockSku?.substringBeforeLast('_');
                        /* PERFORMANCE OPTIMIZATION
                         * If it is a call from Availability Webservice only continues to check availability if the available quantity is > 0.
                         * Stop checking if it is already 0 (no point on checking further days/hours)
                         * If the call is from Alarmistic Batch, get full list of days/hours to populate the full list of days/hours
                         */
                        if (
                            isAvailabilityServiceCall && (!productAvailableMap.containsKey(productSku) || productAvailableMap.get(productSku) > 0) ||
                            !isAvailabilityServiceCall
                        ) {
                            input.stockKeepingUnits.add(stockSku);
                            count++;
                        }
                        index++;
                        if (count == COMM_OCI_Utils.MAX_REQUESTS || index == productDayByLocationMap.get(locationValue).size()) {
                            count = 0;
                            break;
                        }
                    }
                    if (isAvailabilityServiceCall) {
                        if (!input.stockKeepingUnits.isEmpty()) {
                            invokeAvailable(productAvailableMap, input);
                        }
                    } else {
                        invokeInventoryAvailability(inventoryAvailabilityByProductCodeMap, input);
                    }
                }
            }
        }
    }

    /**
     * @description Call OCI API to verify the availability of procuts.
     *
     * @param productAvailableMap - Products to verify.
     * @param input - The OCI availability input.
     */
    private static void invokeAvailable(Map<String, Double> productAvailableMap, ConnectApi.OCIGetInventoryAvailabilityInputRepresentation input) {
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output;
        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.getInventoryAvailability(input);
        } else {
            output = getInventoryAvailabilityMock(input);
        }
        for (ConnectApi.OCILocationAvailabilityOutputRepresentation loc : output.locations) {
            for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : loc.inventoryRecords) {
                String mainProduct = inventoryRecord.stockKeepingUnit.substringBeforeLast('_');
                if (productAvailableMap.containsKey(mainProduct)) {
                    productAvailableMap.put(mainProduct, Math.min(productAvailableMap.get(mainProduct), inventoryRecord.availableToOrder));
                } else {
                    productAvailableMap.put(mainProduct, inventoryRecord.availableToOrder);
                }
            }
        }
    }
    /**
     * @description Call OCI API to verify the availability of products.
     *
     * @param inventoryAvailabilityByProductCodeMap - map of Output wrapper by Product Code.
     * @param input - The OCI availability input.
     */
    private static void invokeInventoryAvailability(
        Map<String, List<COMM_WS_AvailabilityOutput.ProductRecord>> inventoryAvailabilityByProductCodeMap,
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation input
    ) {
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output;
        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.getInventoryAvailability(input);
        } else {
            output = getInventoryAvailabilityMock(input);
        }
        for (ConnectApi.OCILocationAvailabilityOutputRepresentation loc : output.locations) {
            for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : loc.inventoryRecords) {
                String mainProduct = inventoryRecord.stockKeepingUnit.substringBeforeLast('_');
                COMM_WS_AvailabilityOutput.ProductRecord outputInventoryRecord = new COMM_WS_AvailabilityOutput.ProductRecord();
                outputInventoryRecord.externalId = inventoryRecord.stockKeepingUnit;
                outputInventoryRecord.locationIdentifier = loc.locationIdentifier;
                outputInventoryRecord.onHand = inventoryRecord.onHand;
                outputInventoryRecord.reserved = inventoryRecord.reserved;
                if (inventoryAvailabilityByProductCodeMap.containsKey(mainProduct)) {
                    inventoryAvailabilityByProductCodeMap.get(mainProduct).add(outputInventoryRecord);
                } else {
                    COMM_WS_AvailabilityOutput outputRecord = new COMM_WS_AvailabilityOutput();
                    inventoryAvailabilityByProductCodeMap.put(
                        mainProduct,
                        new List<COMM_WS_AvailabilityOutput.ProductRecord>{ outputInventoryRecord }
                    );
                }
            }
        }
    }

    /**
     * @descrition getInventoryAvailability Mock method to use in tests that generates a mock response based on the input
     *
     * @param input ConnectApi.OCIGetInventoryAvailabilityInputRepresentation
     * @return ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation
     */
    private static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation getInventoryAvailabilityMock(
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation input
    ) {
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output = new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();
        output.success = true;
        output.locations = new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
        for (String inputLocation : input.locationIdentifiers) {
            ConnectApi.OCILocationAvailabilityOutputRepresentation outputLocation = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
            outputLocation.locationIdentifier = inputLocation;
            outputLocation.inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
            for (String inputProductCode : input.stockKeepingUnits) {
                ConnectApi.OCIInventoryRecordOutputRepresentation outputProduct = new ConnectApi.OCIInventoryRecordOutputRepresentation();
                outputProduct.availableToFulfill = 50;
                outputProduct.availableToOrder = 50;
                outputProduct.effectiveDate = DateTime.now();
                outputProduct.onHand = 100;
                outputProduct.reserved = 50;
                outputProduct.safetyStockCount = 10;
                outputProduct.stockKeepingUnit = inputProductCode;
                outputLocation.inventoryRecords.add(outputProduct);
            }
            output.locations.add(outputLocation);
        }
        return output;
    }
}