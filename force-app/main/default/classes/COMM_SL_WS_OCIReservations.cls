/**
 * @author Jose Passos
 * @description Web Service to pre reserve the availability of product.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 * Jose Passos      02/05/2024       Changed to cope with child products and get price calls
 * Jose Passos      03/05/2024       ECOMM-979 - rollback partial reserved records from the chunk that had some errors
 * Jose Passos      24/05/2024       ECOMM-1191 - change reservation request to have a new actionRequestID per product to create the reservations
 * Jose Passos      02/09/2024       ECOMM-2146 + ECOMM-2148 - Fix TimeZone conversions to only convert if dates passed are in GMT + minor changes
 * Jose Passos      20/09/2024       ECOMM-2269 - Fix Permanent Reservations Rollback to call Release service
 **/
@SuppressWarnings('PMD.CognitiveComplexity, PMD.AvoidGlobalModifier')
global inherited sharing class COMM_SL_WS_OCIReservations {
    private static COMM_IREP_Product2 productRep = new COMM_REP_Product2();
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();
    private static String requestedDateTimesGMTOrLocal = COMM_OCI_Utils.DATETIME_GMT_STRING;

    public class ItemLocQtyActionWrapper {
        String actionRequestId;
        String item;
        String location;
        Integer quantity;
    }

    private class ProductRequestedWrapper {
        String actionRequestId;
        String productCode;
        String originalProductCode;
        String family;
        DateTime startDateTime;
        DateTime endDateTime;
    }

    /**
     * @description This method receives a list of requested Products and updates products family (category) and shifts
     * update productCode to parent product to reserve stock
     *
     * @param productRequestedList List<ProductRequestedWrapper> - Input and Output parameter
     * @param distinctProductMap Map<String, Product2>
     */
    private static void setProductDetails(List<ProductRequestedWrapper> productRequestedList, Map<String, Product2> distinctProductMap) {
        for (ProductRequestedWrapper productRequested : productRequestedList) {
            productRequested.family = distinctProductMap.get(productRequested.productCode).family;
            if (
                productRequested.family == COMM_OCI_Constants.PRODUCT_FAMILY_LOUNGE ||
                productRequested.family == COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION
            ) {
                // store child product in originalProductCode and use parent ProductCode to reserve stock
                if (distinctProductMap.get(productRequested.productCode).COMM_ParentProduct__r.ProductCode != null) {
                    productRequested.originalProductCode = productRequested.productCode;
                    productRequested.productCode = distinctProductMap.get(productRequested.productCode).COMM_ParentProduct__r.ProductCode;
                }
            }
        }
    }

    /**
     * @description This method generates a the OCI skus and locations based on the start and end datetimes requested
     * and generates a map with Product/Location/quantity to reserve/release in OCI
     * Products will be generated based on start and end date (days)
     * Locations will be generated based on the start and end time (Hours)
     *
     * @param productRequestedList List<ProductRequestedWrapper>
     * @return Map<String, ItemLocQtyActionWrapper>
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public static Map<String, Map<String, ItemLocQtyActionWrapper>> generateItemLocQty(List<ProductRequestedWrapper> productRequestedList) {
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyMap = new Map<String, Map<String, ItemLocQtyActionWrapper>>();

        for (ProductRequestedWrapper product : productRequestedList) {
            // generate Locations (hourly/subscription) based on type of product
            List<String> firstDayLocationsList = new List<String>();
            List<String> fullDayLocationsList = new List<String>();
            List<String> lastDayLocationsList = new List<String>();
            COMM_OCI_Utils.generateLocationList(
                product.family,
                product.startDateTime,
                product.endDateTime,
                firstDayLocationsList,
                fullDayLocationsList,
                lastDayLocationsList
            );

            // generate daily Products
            List<String> firstDayProductsList = new List<String>();
            List<String> fullDayProductsList = new List<String>();
            List<String> lastDayProductsList = new List<String>();
            COMM_OCI_Utils.generateProductList(
                product.productCode,
                product.startDateTime,
                product.endDateTime,
                firstDayProductsList,
                fullDayProductsList,
                lastDayProductsList
            );

            // update Item Location Map with Quantities
            for (String firstDayProduct : firstDayProductsList) {
                for (String firstDayLocation : firstDayLocationsList) {
                    updateMapItemLocQty(itemLocQtyMap, product.actionRequestId, firstDayProduct, firstDayLocation, 1);
                }
            }
            for (String fullDayProduct : fullDayProductsList) {
                for (String fullDayLocation : fullDayLocationsList) {
                    updateMapItemLocQty(itemLocQtyMap, product.actionRequestId, fullDayProduct, fullDayLocation, 1);
                }
            }
            for (String lastDayProduct : lastDayProductsList) {
                for (String lastDayLocation : lastDayLocationsList) {
                    updateMapItemLocQty(itemLocQtyMap, product.actionRequestId, lastDayProduct, lastDayLocation, 1);
                }
            }
        }

        return itemLocQtyMap;
    }

    /**
     * @description This method updates a map with ItemLocQtyActionWrapper.
     * Adds the product/location/quantity to the map if that product/location does not exist yet.
     * If a product/location already exists in the map the quantity is incremented with the new quantity
     *
     * @param itemLocQtyMap Map<String, Map<String, ItemLocQtyActionWrapper>>
     * @param product String
     * @param location String
     * @param actionRequestId String
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void updateMapItemLocQty(
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyRequestMap,
        String actionRequestId,
        String product,
        String location,
        Integer quantity
    ) {
        // Check if the outer map contains the actionRequestId
        if (!itemLocQtyRequestMap.containsKey(actionRequestId)) {
            // Initialize the inner map if it doesn't exist
            itemLocQtyRequestMap.put(actionRequestId, new Map<String, ItemLocQtyActionWrapper>());
        }

        // Get the inner map for the actionRequestId
        Map<String, ItemLocQtyActionWrapper> itemLocQtyMap = itemLocQtyRequestMap.get(actionRequestId);

        // Item Loc map Key
        String itemLocKey = product + '_' + location;

        // Get the ItemLocQtyActionWrapper for the key
        ItemLocQtyActionWrapper itemLocQtyActionWrapper = itemLocQtyMap.get(itemLocKey);
        if (itemLocQtyActionWrapper == null) {
            itemLocQtyActionWrapper = new ItemLocQtyActionWrapper();
            itemLocQtyActionWrapper.actionRequestId = actionRequestId;
            itemLocQtyActionWrapper.item = product;
            itemLocQtyActionWrapper.location = location;
            itemLocQtyActionWrapper.quantity = 1;
        } else {
            itemLocQtyActionWrapper.quantity += quantity;
        }

        // Update the map with the new/updated itemLocQtyActionWrapper
        itemLocQtyMap.put(itemLocKey, itemLocQtyActionWrapper);
    }

    /**
     * @description Method that receives the requestBody and returns a map with the list of
     * product and locations and respective quantity to reserve/release
     *
     * @param inputRequest COMM_WS_ReservationInput
     * @return Map<String, ItemLocQtyActionWrapper>
     */
    @TestVisible
    private static Map<String, Map<String, ItemLocQtyActionWrapper>> generateItemLocQtyMap(COMM_WS_ReservationInput inputRequest) {
        List<String> distinctProductList = new List<String>();
        Map<String, COMM_WS_ReservationInput.Product> productInputMap = new Map<String, COMM_WS_ReservationInput.Product>();
        List<ProductRequestedWrapper> productRequestedList = new List<ProductRequestedWrapper>();

        for (COMM_WS_ReservationInput.Product product : inputRequest.product) {
            productInputMap.put(product.productId, product);
            if (product.startDate == null) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_START_DATE, null);
            }
            if (product.endDate == null) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_END_DATE, null);
            }
            if (product.startDate > product.endDate) {
                throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INVALID_DATE, null);
            }

            ProductRequestedWrapper productRequested = new ProductRequestedWrapper();
            productRequested.actionRequestId = product.actionRequestId;
            productRequested.productCode = product.productId;
            productRequested.startDateTime = product.startDate;
            productRequested.endDateTime = product.endDate;
            productRequestedList.add(productRequested);
        }

        // get all distinct Products (no duplicates) to validate if there are all products exist in Product2
        distinctProductList.addAll(productInputMap.keySet());
        // get product Family from Product2
        Map<String, Product2> dbProductMap = productRep.getProductsByProductCodes(distinctProductList);
        if (productInputMap.size() <> dbProductMap.size()) {
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INVALID_PRODUCT, null);
        }
        // Convert datetimes to time zone of each product being send to OCI if they are passed in GMT
        if (!productInputMap.isEmpty() && requestedDateTimesGMTOrLocal == COMM_OCI_Utils.DATETIME_GMT_STRING) {
            for (ProductRequestedWrapper productRequested : productRequestedList) {
                productRequested.startDateTime = DateTime.valueOfGMT(
                    productRequested.startDateTime.format(
                        COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT,
                        dbProductMap.get(productRequested.productCode).COMM_TimeZoneByAirport__c
                    )
                );
                productRequested.endDateTime = DateTime.valueOfGMT(
                    productRequested.endDateTime.format(
                        COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT,
                        dbProductMap.get(productRequested.productCode).COMM_TimeZoneByAirport__c
                    )
                );
            }
        }

        // Populate list with Product, Family, Start and End datetimes
        setProductDetails(productRequestedList, dbProductMap);

        // Generate ItemLocQty with daily products and hourly locations
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyMap = generateItemLocQty(productRequestedList);

        return itemLocQtyMap;
    }

    /**
     * @description This will get the price for all requested products
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @return List<COMM_WS_AvailabilityOutput> list of products and price of the reserved stock
     */
    public List<COMM_WS_ReservationOutput> getPrice(COMM_WS_ReservationInput inputRequest) {
        COMM_SL_WS_Pricing pricingCalculationInstance = new COMM_SL_WS_Pricing();

        String priceRequest = '{"product":' + JSON.serialize(inputRequest.product, true) + '}';
        Map<String, Object> requestMap = COMM_RestServices_Utility.parseRequest(priceRequest);
        Map<String, Object> responseMap = pricingCalculationInstance.calculatePricingResponse(requestMap);

        String errorDetails = '';
        List<Map<String, Object>> errors = (List<Map<String, Object>>) responseMap.get('error');
        if (!errors.isEmpty()) {
            for (Map<String, Object> error : errors) {
                if (String.isEmpty(errorDetails)) {
                    errorDetails = error.get('message') + ' ' + error.get('productId');
                } else {
                    errorDetails = errorDetails + ', ' + error.get('message') + ' ' + error.get('productId');
                }
            }
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_GET_PRICE, errorDetails);
        }

        List<COMM_WS_ReservationOutput> outputProductList = new List<COMM_WS_ReservationOutput>();
        List<Map<String, Object>> products = (List<Map<String, Object>>) responseMap.get('product');
        if (products != null) {
            for (COMM_WS_ReservationInput.product productInput : inputRequest.product) {
                COMM_WS_ReservationOutput outputProduct = new COMM_WS_ReservationOutput();
                outputProduct.actionRequestId = productInput.actionRequestId;
                outputProduct.productId = productInput.productId;
                outputProduct.startDate = productInput.startDate;
                outputProduct.endDate = productInput.endDate;
                for (Map<String, Object> product : products) {
                    if (
                        (String) product.get('productId') == productInput.productId &&
                        ((DateTime) product.get('startDate')).format(COMM_OCI_Utils.OCI_DATE_TIME_FORMAT) ==
                        productInput.startDate.format(COMM_OCI_Utils.OCI_DATE_TIME_FORMAT) &&
                        ((DateTime) product.get('endDate')).format(COMM_OCI_Utils.OCI_DATE_TIME_FORMAT) ==
                        productInput.endDate.format(COMM_OCI_Utils.OCI_DATE_TIME_FORMAT)
                    ) {
                        outputProduct.price = (Double) product.get('price');
                        break;
                    }
                }
                outputProductList.add(outputProduct);
            }
        }

        return outputProductList;
    }

    /**
     * @description This will reserve stock in OCI and by default it will request for all products passed assuming the dates on the request are in GMT
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @param inputGetPriceFlag inputGetPriceFlag
     * @return List<COMM_WS_AvailabilityOutput> list of products and price of the reserved stock
     */
    public List<COMM_WS_ReservationOutput> reserve(COMM_WS_ReservationInput inputRequest, Boolean inputGetPriceFlag) {
        return reserve(inputRequest, inputGetPriceFlag, COMM_OCI_Utils.DATETIME_GMT_STRING);
    }

    /**
     * @description This will reserve stock in OCI and get product price (if needed) and specifying the timezone flag of the dates passed
     * if parent products are passed on the request, this inputGetPriceFlag must be sent as false.
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @param Boolean inputGetPriceFlag - true if the price needs to be calculated, false otherwise.
     * @param String inputDateTimeGMTOrLocal - Flag that indicates if passed dateTimes are in GMT or on Product Local Timezone. Possible values GMT / LOCAL
     * @return List<COMM_WS_AvailabilityOutput> list of products and price of the reserved stock
     */
    public List<COMM_WS_ReservationOutput> reserve(COMM_WS_ReservationInput inputRequest, Boolean inputGetPriceFlag, String inputDateTimeGMTOrLocal) {
        if (inputRequest.expirationSeconds > COMM_OCI_Constants.MAX_EXPIRATION_SECONDS) {
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INVALID_EXPIRATION_SECONDS, null);
        }
        if (inputRequest.product == null || inputRequest.product.isEmpty()) {
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_PRODUCT, null);
        }
        requestedDateTimesGMTOrLocal = (inputDateTimeGMTOrLocal == null) ? COMM_OCI_Utils.DATETIME_GMT_STRING : inputDateTimeGMTOrLocal;
        Integer expirationSeconds = inputRequest.expirationSeconds;
        String reservationId = inputRequest.reservationId;

        // Prepare response with Prices or without
        List<COMM_WS_ReservationOutput> outputProductList = new List<COMM_WS_ReservationOutput>();
        if (inputGetPriceFlag) {
            outputProductList = getPrice(inputRequest);
        } else {
            for (COMM_WS_ReservationInput.Product product : inputRequest.product) {
                COMM_WS_ReservationOutput outputProduct = new COMM_WS_ReservationOutput();
                outputProduct.actionRequestId = product.actionRequestId;
                outputProduct.productId = product.productId;
                outputProduct.startDate = product.startDate;
                outputProduct.endDate = product.endDate;
                outputProductList.add(outputProduct);
            }
        }

        // validate request and generate a map with Item Loc with Quantity
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyMap = new Map<String, Map<String, ItemLocQtyActionWrapper>>();
        itemLocQtyMap = generateItemLocQtyMap(inputRequest);

        List<String> actionRequestIdList = new List<String>();
        List<String> errorMessageList = new List<String>();
        // Map with itemLocations reserved in case a rollback is required
        Map<String, ItemLocQtyActionWrapper> itemLocQtyReservedMap = new Map<String, ItemLocQtyActionWrapper>();
        Boolean successAPICall = false;
        if (COMM_OCI_Utils.getInventoryAPISetting() == COMM_OCI_Constants.INVENTORY_API_CONNECT) {
            successAPICall = reserveConnectAPI(
                errorMessageList,
                itemLocQtyMap,
                expirationSeconds,
                reservationId,
                actionRequestIdList,
                itemLocQtyReservedMap
            );
        }
        if (!successAPICall) {
            Boolean isTemporaryReservation = expirationSeconds > 0 ? true : false;
            rollbackReservedRecords(isTemporaryReservation, reservationId, actionRequestIdList, itemLocQtyReservedMap);
            String errorMessage = '';
            for (String error : errorMessageList) {
                errorMessage = errorMessage + error;
            }
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_RESERVATION_FAILED, errorMessage);
        }

        return outputProductList;
    }

    /**
     * @description Method to prepare the input in chunks and call the invokeReserveConnectAPI method.
     *
     * @param errorMessageList List<String> - Output parameter
     * @param itemLocQtyMap Map<String, Map<String, ItemLocQtyActionWrapper>> - map with the actionRequestId and a Map of itemLocationKey and respective quantity to reserve
     * @param expirationSeconds Integer
     * @param reservationId String
     * @param itemLocQtyReservedMap Map<String, ItemLocQtyActionWrapper> -  Output parameter - map with the itemLocationKey and respective quantity that was successfully reserved
     * @return Boolean
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Boolean reserveConnectAPI(
        List<String> errorMessageList,
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyMap,
        Integer expirationSeconds,
        String reservationId,
        List<String> actionRequestIdList,
        Map<String, ItemLocQtyActionWrapper> itemLocQtyReservedMap
    ) {
        Boolean success = true;
        Map<String, ItemLocQtyActionWrapper> itemLocQtyReservedChunkMap = new Map<String, ItemLocQtyActionWrapper>();
        List<String> failedItemLocQtyKeyList = new List<String>(); // to remove from itemLocQtyReservedChunkMap the ones that failed

        // Prepare input payload for each actionRequestId (by product)
        for (String actionRequestId : itemLocQtyMap.keySet()) {
            ConnectApi.OCICreateReservationInputRepresentation input = new ConnectApi.OCICreateReservationInputRepresentation();
            input.allowPartialReservations = false;
            input.reservationId = reservationId;
            input.externalRefId = reservationId;
            if (expirationSeconds > 0) {
                input.expirationSeconds = expirationSeconds;
            }
            Integer countItemLocs = 0;
            Integer countItemLocsChunk = 0;
            Integer countItemLocsChunkTotal = 0;
            Integer totalItemLocs = itemLocQtyMap.get(actionRequestId).size();

            for (String itemLocQtyKey : itemLocQtyMap.get(actionRequestId).keySet()) {
                ItemLocQtyActionWrapper itemLocQty = itemLocQtyMap.get(actionRequestId).get(itemLocQtyKey);
                input.actionRequestId = itemLocQty.actionRequestId;
                itemLocQtyReservedChunkMap.put(itemLocQtyKey, itemLocQty);

                if (countItemLocsChunk == 0) {
                    input.createRecords = new List<ConnectApi.OCICreateReservationSingleInputRepresentation>();
                }

                ConnectApi.OCICreateReservationSingleInputRepresentation singleReservationInput = new ConnectApi.OCICreateReservationSingleInputRepresentation();
                singleReservationInput.stockKeepingUnit = itemLocQty.item;
                singleReservationInput.locationIdentifier = itemLocQty.location;
                singleReservationInput.quantity = itemLocQty.quantity;
                input.createRecords.add(singleReservationInput);

                countItemLocsChunk++;
                countItemLocs++;
                if (countItemLocsChunk == COMM_OCI_Utils.MAX_REQUESTS || countItemLocs == totalItemLocs) {
                    countItemLocsChunk = 0;
                    countItemLocsChunkTotal++;
                    input.actionRequestId =
                        (input.actionRequestId == null ? COMM_OCI_Utils.newGuid() : input.actionRequestId) +
                        '_' +
                        countItemLocsChunkTotal;
                    actionRequestIdList.add(input.actionRequestId);
                    success = invokeReserveConnectAPI(errorMessageList, input, failedItemLocQtyKeyList);
                    if (!success) {
                        // remove the failedItemLocQtyKeyList from itemLocQtyReservedChunkMap to rollback only the successful ones
                        for (String failedItemLocQtyKey : failedItemLocQtyKeyList) {
                            itemLocQtyReservedChunkMap.remove(failedItemLocQtyKey);
                        }
                        itemLocQtyReservedMap.putAll(itemLocQtyReservedChunkMap);
                        itemLocQtyReservedChunkMap.clear();
                        break;
                    } else {
                        itemLocQtyReservedMap.putAll(itemLocQtyReservedChunkMap);
                        itemLocQtyReservedChunkMap.clear();
                    }
                }
            }
            if (!success) {
                break;
            }
        }
        return success;
    }

    /**
     * @description Method to that calls the Connect API to reserve the stock
     * @param errorMessageList List<String> - Output parameter
     * @param input ConnectApi.OCICreateReservationInputRepresentation
     * @return Boolean
     */
    private static Boolean invokeReserveConnectAPI(
        List<String> errorMessageList,
        ConnectApi.OCICreateReservationInputRepresentation input,
        List<String> failedItemLocQtyKeyList
    ) {
        Boolean success = true;
        ConnectApi.OCICreateReservationOutputRepresentation output;
        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.createReservation(input);
        } else {
            output = createReservationMock(input);
        }
        success = processInvokeReserveErrors(output, errorMessageList, failedItemLocQtyKeyList);
        return success;
    }

    /**
     * @description Receives Connect API output and populates a list with errors
     *
     * @param output ConnectApi.OCICreateReservationOutputRepresentation
     * @param errorMessageList List<String> - Output parameter
     * @return Boolean
     */
    @TestVisible
    private static Boolean processInvokeReserveErrors(
        ConnectApi.OCICreateReservationOutputRepresentation output,
        List<String> errorMessageList,
        List<String> failedItemLocQtyKeyList
    ) {
        Boolean success = true;
        Map<String, Set<String>> errorsMap = new Map<String, Set<String>>();
        String sku;
        if (output.success) {
            for (ConnectApi.OCICreateReservationSingleOutputRepresentation outputDetail : output.details) {
                if (outputDetail.errorCode != null) {
                    failedItemLocQtyKeyList.add(outputDetail.stockKeepingUnit + '_' + outputDetail.locationIdentifier);
                    sku = outputDetail.stockKeepingUnit.substringBeforeLast('_');
                    if (!errorsMap.containsKey(outputDetail.errorCode)) {
                        errorsMap.put(outputDetail.errorCode, new Set<String>{ sku });
                    } else {
                        errorsMap.get(outputDetail.errorCode).add(sku);
                    }
                }
            }
        } else {
            for (ConnectApi.OCICreateReservationErrorOutputRepresentation outputErrors : output.errors) {
                errorsMap.put(outputErrors.errorCode, new Set<String>{ outputErrors.message });
            }
        }

        // if there are no errors success = true
        success = errorsMap.isEmpty();

        String errorMessage;
        for (String errorCode : errorsMap.keySet()) {
            errorMessage = errorCode + ' for ' + String.join(errorsMap.get(errorCode), ' ');
            errorMessageList.add(errorMessage);
        }
        return success;
    }

    /**
     * @description Rollback a reservation that had errors
     * In case a batch of a reservation fails we may have to rollback the previous itemLocs that were successfully reserved
     * If it was a temporary reservation we need to call OCI RESERVE service with the same actionRequestIDs and a dummy product and a valid location
     * If it was a permanent reservation we need to call OCI RELEASE service with the item/location/quantities that were reserved
     * @param isTempReservation Boolean - Indicates if the reservation is temporary or not
     * @param reservationId String
     * @param actionRequestIdList List<String> - List of actionRequestIds that were reserved
     * @param itemLocQtyReservedMap Map<String, ItemLocQtyActionWrapper> -  Output parameter - map with the itemLocationKey and respective quantity that was successfully reserved
     * @return Boolean
     */
    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Boolean rollbackReservedRecords(
        Boolean isTempReservation,
        String reservationId,
        List<String> actionRequestIdList,
        Map<String, ItemLocQtyActionWrapper> itemLocQtyReservedMap
    ) {
        List<String> errorMessageList = new List<String>();
        Boolean successAPICall = false;

        if (isTempReservation) {
            ConnectApi.OCICreateReservationInputRepresentation input = new ConnectApi.OCICreateReservationInputRepresentation();
            for (String actionRequestId : actionRequestIdList) {
                input.reservationId = reservationId;
                input.externalRefId = reservationId;
                input.actionRequestId = actionRequestId;
                input.expirationSeconds = 1;
                input.createRecords = new List<ConnectApi.OCICreateReservationSingleInputRepresentation>();
                ConnectApi.OCICreateReservationSingleInputRepresentation singleReservationInput = new ConnectApi.OCICreateReservationSingleInputRepresentation();
                singleReservationInput.stockKeepingUnit = 'Rollback'; // Non existing Product to rollback the reservation
                singleReservationInput.locationIdentifier = COMM_OCI_Constants.OCI_LOCATION_SUBSCRIPTIONS; // Any valid location works to rollback
                singleReservationInput.quantity = 1;
                input.createRecords.add(singleReservationInput);
                if (COMM_OCI_Utils.getInventoryAPISetting() == COMM_OCI_Constants.INVENTORY_API_CONNECT) {
                    ConnectApi.OCICreateReservationOutputRepresentation output;
                    if (!Test.isRunningTest()) {
                        output = ConnectApi.Omnichannelinventoryservice.createReservation(input);
                    } else {
                        output = createReservationMock(input);
                    }
                    successAPICall = output.success;
                }
            }
        } else {
            if (COMM_OCI_Utils.getInventoryAPISetting() == COMM_OCI_Constants.INVENTORY_API_CONNECT) {
                Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyToReleaseMap = new Map<String, Map<String, ItemLocQtyActionWrapper>>();
                // for each itemLocQtyReservedMap key generate a random hash and populate itemLocQtyToReleaseMap
                for (String itemLocQtyKey : itemLocQtyReservedMap.keySet()) {
                    String releaseActionRequestId = COMM_OCI_Utils.newGuid();
                    itemLocQtyToReleaseMap.put(
                        releaseActionRequestId,
                        new Map<String, ItemLocQtyActionWrapper>{ itemLocQtyKey => itemLocQtyReservedMap.get(itemLocQtyKey) }
                    );
                }
                successAPICall = releaseConnectAPI(errorMessageList, itemLocQtyToReleaseMap, reservationId);
            }
        }
        if (!successAPICall) {
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_RESERVE_ROLLBACK_FAILED, null);
        }
        return successAPICall;
    }

    /**
     * @description This will release a previous stock reservation in OCI, assuming the dateTimes are in GMT
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     */
    public void release(COMM_WS_ReservationInput inputRequest) {
        release(inputRequest, COMM_OCI_Utils.DATETIME_GMT_STRING);
    }

    /**
     * @description This will release a previous stock reservation in OCI
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @param String inputDateTimeGMTOrLocal - Flag that indicates if passed dateTimes are in GMT or on Product Local Timezone. Possible values GMT / LOCAL
     */
    public void release(COMM_WS_ReservationInput inputRequest, String inputDateTimeGMTOrLocal) {
        if (inputRequest.product == null || inputRequest.product.isEmpty()) {
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_INV_NULL_PRODUCT, null);
        }
        requestedDateTimesGMTOrLocal = (inputDateTimeGMTOrLocal == null) ? COMM_OCI_Utils.DATETIME_GMT_STRING : inputDateTimeGMTOrLocal;
        String reservationId = inputRequest.reservationId;

        // validate request and generate a map with Item Loc with Quantity
        Map<String, Map<String, ItemLocQtyActionWrapper>> itemLocQtyMap = new Map<String, Map<String, ItemLocQtyActionWrapper>>();
        itemLocQtyMap = generateItemLocQtyMap(inputRequest);

        List<String> errorMessageList = new List<String>();
        Boolean successAPICall = false;
        if (COMM_OCI_Utils.getInventoryAPISetting() == COMM_OCI_Constants.INVENTORY_API_CONNECT) {
            successAPICall = releaseConnectAPI(errorMessageList, itemLocQtyMap, reservationId);
        }
        if (!successAPICall) {
            String errorMessage = '';
            for (String error : errorMessageList) {
                errorMessage = errorMessage + error;
            }
            throw new COMM_WS_OCIException(COMM_OCI_Constants.ERROR_RELEASE_FAILED, errorMessage);
        }
    }

    /**
     * @description Method to prepare the input in chunks and call the invokeReleaseConnectAPI method
     * @param errorMessageList List<String> - Output parameter
     * @param itemLocQtyMap Map<String, ItemLocQtyActionWrapper> - map with the itemLocationKey and respective quantity to reserve
     * @param reservationId String
     * @return Boolean
     */
    private static Boolean releaseConnectAPI(
        List<String> errorMessageList,
        Map<String, Map<String, ItemLocQtyActionWrapper>> actionRequestitemLocQtMap,
        String reservationId
    ) {
        Boolean success = true;
        Map<String, ItemLocQtyActionWrapper> itemLocQtyMap = new Map<String, ItemLocQtyActionWrapper>();
        for (String actionRequestId : actionRequestitemLocQtMap.keySet()) {
            itemLocQtyMap = actionRequestitemLocQtMap.get(actionRequestId);

            // Prepare input payload
            ConnectApi.OCIReleaseReservationInputRepresentation input = new ConnectApi.OCIReleaseReservationInputRepresentation();
            input.reservationId = reservationId;
            Integer totalItemLocs = itemLocQtyMap.size();
            Integer countItemLocs = 0;
            Integer countItemLocsChunk = 0;

            for (ItemLocQtyActionWrapper itemLocQty : itemLocQtyMap.values()) {
                if (countItemLocsChunk == 0) {
                    input.releaseRecords = new List<ConnectApi.OCIReleaseReservationSingleInputRepresentation>();
                }

                ConnectApi.OCIReleaseReservationSingleInputRepresentation singleReleaseInput = new ConnectApi.OCIReleaseReservationSingleInputRepresentation();
                singleReleaseInput.reservationId = reservationId;
                singleReleaseInput.actionRequestId = COMM_OCI_Utils.newGuid();
                singleReleaseInput.locationIdentifier = itemLocQty.location;
                singleReleaseInput.quantity = itemLocQty.quantity;
                singleReleaseInput.stockKeepingUnit = itemLocQty.item;
                input.releaseRecords.add(singleReleaseInput);

                countItemLocsChunk++;
                countItemLocs++;
                if (countItemLocsChunk == COMM_OCI_Utils.MAX_REQUESTS || countItemLocs == totalItemLocs) {
                    countItemLocsChunk = 0;
                    success = invokeReleaseConnectAPI(errorMessageList, input);
                    if (!success) {
                        break;
                    }
                }
            }
        }
        return success;
    }

    /**
     * @description Method to that calls the Connect API to release the stock
     * @param errorMessageList List<String> - Output parameter
     * @param input ConnectApi.OCIReleaseReservationInputRepresentation
     * @return Boolean
     */
    private static Boolean invokeReleaseConnectAPI(List<String> errorMessageList, ConnectApi.OCIReleaseReservationInputRepresentation input) {
        Boolean success = true;
        ConnectApi.OCIReleaseReservationOutputRepresentation output;
        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.releaseReservation(input);
        } else {
            output = releaseReservationMock(input);
        }
        success = processInvokeReleaseErrors(output, errorMessageList);
        return success;
    }

    /**
     * @description Receives Connect API output and populates a list with errors
     * @param output ConnectApi.OCIReleaseReservationOutputRepresentation
     * @param errorMessageList List<String> - Output parameter
     * @return Boolean
     */
    @TestVisible
    private static Boolean processInvokeReleaseErrors(ConnectApi.OCIReleaseReservationOutputRepresentation output, List<String> errorMessageList) {
        Boolean success = true;
        Map<String, Set<String>> errorsMap = new Map<String, Set<String>>();
        List<String> errorItems = new List<String>();
        String sku;
        if (output.success) {
            for (ConnectApi.OCIReleaseReservationErrorOutputRepresentation outputErrors : output.errors) {
                if (outputErrors.errorCode != null) {
                    sku = outputErrors.details.stockKeepingUnit.substringBeforeLast('_');
                    if (!errorsMap.containsKey(outputErrors.errorCode)) {
                        errorsMap.put(outputErrors.errorCode, new Set<String>{ sku });
                    } else {
                        errorsMap.get(outputErrors.errorCode).add(sku);
                    }
                }
            }
        } else {
            for (ConnectApi.OCIReleaseReservationErrorOutputRepresentation outputErrors : output.errors) {
                if (outputErrors.errorCode != null) {
                    errorsMap.put(outputErrors.errorCode, new Set<String>{ outputErrors.message });
                }
            }
        }

        // if there are no errors success = true
        success = errorsMap.isEmpty();

        String errorMessage;
        for (String errorCode : errorsMap.keySet()) {
            errorMessage = errorCode + ' for ' + String.join(errorsMap.get(errorCode), ' ');
            errorMessageList.add(errorMessage);
        }
        return success;
    }

    /**
     * @description This will release a previous permanent Reservation and create a new temporary Reservation with the specified expiration time
     * if parent products are passed on the request, inputGetPriceFlag must be sent as false (price is defined at child level)
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @param Boolean inputGetPriceFlag - true if the price needs to be calculated, false otherwise.
     * @return List<COMM_WS_AvailabilityOutput> list of products and price of the new temporary reservation
     */
    public List<COMM_WS_ReservationOutput> revertPermanentReservation(
        COMM_WS_ReservationInput inputRequest,
        Boolean inputGetPriceFlag,
        String inputDateTimeGMTOrLocal
    ) {
        // Release previous reservation
        release(inputRequest, inputDateTimeGMTOrLocal);
        // Reserve stock and list the reserved products
        List<COMM_WS_ReservationOutput> outputProductList = reserve(inputRequest, inputGetPriceFlag, inputDateTimeGMTOrLocal);

        return outputProductList;
    }

    /**
     * @Descrition: createReservation Mock method to use in tests that generates a mock response based on the input
     *
     * @param input ConnectApi.OCICreateReservationInputRepresentation
     * @return ConnectApi.OCICreateReservationOutputRepresentation
     */
    private static ConnectApi.OCICreateReservationOutputRepresentation createReservationMock(
        ConnectApi.OCICreateReservationInputRepresentation input
    ) {
        ConnectApi.OCICreateReservationOutputRepresentation output = new ConnectApi.OCICreateReservationOutputRepresentation();
        output.success = true;
        DateTime dt = DateTime.now();
        output.reservationTime = dt.format();
        output.expirationTime = dt.addSeconds(90).format();
        output.errors = null;
        output.details = new List<ConnectApi.OCICreateReservationSingleOutputRepresentation>();
        for (ConnectApi.OCICreateReservationSingleInputRepresentation inputItemLoc : input.createRecords) {
            ConnectApi.OCICreateReservationSingleOutputRepresentation outputItemLoc = new ConnectApi.OCICreateReservationSingleOutputRepresentation();
            outputItemLoc.locationIdentifier = inputItemLoc.locationIdentifier;
            outputItemLoc.stockKeepingUnit = inputItemLoc.stockKeepingUnit;
            outputItemLoc.quantity = inputItemLoc.quantity;
            output.details.add(outputItemLoc);
        }
        return output;
    }

    /**
     * @Descrition: releaseReservation Mock method to use in tests that generates a mock response based on the input
     * @param input ConnectApi.OCIReleaseReservationInputRepresentation
     * @return ConnectApi.OCIReleaseReservationOutputRepresentation
     */
    private static ConnectApi.OCIReleaseReservationOutputRepresentation releaseReservationMock(
        ConnectApi.OCIReleaseReservationInputRepresentation input
    ) {
        ConnectApi.OCIReleaseReservationOutputRepresentation output = new ConnectApi.OCIReleaseReservationOutputRepresentation();
        output.success = true;
        output.errors = new List<ConnectApi.OCIReleaseReservationErrorOutputRepresentation>();
        return output;
    }
}