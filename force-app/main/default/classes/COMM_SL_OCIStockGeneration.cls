/**
 * @author Ruben Rodrigues
 * @description Class to upload stock in OCI and check upload process status
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues      26/03/2024       Original version
 **/
public inherited sharing class COMM_SL_OCIStockGeneration {
    private static final String SKIPPED_RECORDS_STRING = ' skipped record';

    private static COMM_IREP_Product2 productRep = new COMM_REP_Product2();

    private class ItemLocQtyWrapper {
        String item;
        String location;
        Integer quantity;
    }

    private class ProductRequestedWrapper {
        String productCode;
        String family;
        DateTime startDateTime;
        DateTime endDateTime;
        Integer quantity;
        String recordId;
        Integer onHand;
        String sku;
        DateTime effectiveDate;
    }

    /**
     * @description This will generate and upload the stock in OCI if the record is Not Processed
     * or get the status of an upload request that was previously submitted
     *
     * @param COMM_WS_ReservationInput inputRequest - Set of products and a range of start and end date
     * @return String
     */
    public ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation uploadStock(List<COMM_Capacity__c> capacityList) {
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output;

        // Generate a map with Item Loc and Quantity
        Map<String, ItemLocQtyWrapper> itemLocQtyMap = new Map<String, ItemLocQtyWrapper>();
        itemLocQtyMap = generateItemLocQtyMap(capacityList);

        // Upload Stock in OCI
        if (COMM_OCI_Utils.getInventoryAPISetting() == COMM_OCI_Constants.INVENTORY_API_CONNECT) {
            output = uploadStockConnectAPI(itemLocQtyMap);
        }

        return output;
    }

    /**
     * @description Method to prepare the BinaryInput and call the invokeUploadConnectAPI
     *
     * @param itemLocQtyMap Map<String, ItemLocQtyWrapper> - Set of items, locations and quantities to upload
     * @return ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation
     */
    private static ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation uploadStockConnectAPI(Map<String, ItemLocQtyWrapper> itemLocQtyMap) {
        Map<String, List<ProductRequestedWrapper>> locItemQtyMap = new Map<String, List<ProductRequestedWrapper>>();
        for (ItemLocQtyWrapper myItems : itemLocQtyMap.values()) {
            String locKey = myItems.location;
            ProductRequestedWrapper itemQty = new ProductRequestedWrapper();
            itemQty.productCode = myItems.item;
            itemQty.quantity = myItems.quantity;
            List<ProductRequestedWrapper> itemQtyLst = locItemQtyMap.get(locKey);

            if (itemQtyLst == null) {
                itemQtyLst = new List<ProductRequestedWrapper>();
            }
            itemQtyLst.add(itemQty);
            locItemQtyMap.put(locKey, itemQtyLst);
        }

        // Build file Content
        String fileContent = buildFileContent(locItemQtyMap);
        Blob fileContentBlob = Blob.valueof(fileContent);

        String fileName = 'COMM_SL_OCIStockGeneration_' + DateTime.now();
        ConnectApi.BinaryInput apiBin = new ConnectApi.BinaryInput(fileContentBlob, 'text/plain', fileName);
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output = invokeUploadConnectAPI(apiBin);

        return output;
    }

    /**
     * @description Method that receives a Map with Locations and a list of Item Quantities
     * and builds the file content to update stock in OCI
     *
     * @param Map<String, List<ProductRequestedWrapper>> itemLocQtyMap - Item and respective quantities per location
     * @return String - file content
     */
    private static String buildFileContent(Map<String, List<ProductRequestedWrapper>> locItemQtyMap) {
        String dateTimeString = Datetime.now().format(COMM_OCI_Utils.OCI_DATE_TIME_FORMAT);
        String fileContent = '';

        for (String location : locItemQtyMap.keySet()) {
            fileContent = fileContent + '{"location":"' + location + '","mode":"UPDATE"}' + '\r\n';
            for (ProductRequestedWrapper item : locItemQtyMap.get(location)) {
                String recId = COMM_OCI_Utils.newGuid();
                fileContent =
                    fileContent +
                    '{"recordId":"' +
                    recId +
                    '","onHand":' +
                    item.quantity +
                    ',"sku":"' +
                    item.productCode +
                    '","effectiveDate":"' +
                    DateTimeString +
                    '"}' +
                    '\r\n';
            }
        }
        return fileContent;
    }

    /**
     * @description Method that calls the Connect API to Upload the stock into OCI
     * @param input ConnectApi.BinaryInput - file with the list of locations/item/quantity to upload
     * @return String - Upload Job ID
     */
    private static ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation invokeUploadConnectAPI(ConnectApi.BinaryInput input) {
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output;
        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.submitInventoryAvailabilityUpload(input);
        } else {
            output = submitInventoryAvailabilityUploadMock(input);
        }
        return output;
    }

    /**
     * @description Method to get the current processing status of a Stock Upload Job
     *
     * @param uploadJobId String - Connect API upload JobID
     * @param errorMessageList List<String>
     * @return String Job Status
     */
    public String getJobIdStatus(String uploadJobId, List<String> errorMessageList) {
        ConnectApi.OCIUploadInventoryAvailabilityStatusOutputRepresentation output;

        if (!Test.isRunningTest()) {
            output = ConnectApi.Omnichannelinventoryservice.getInventoryAvailabilityUploadStatus(uploadJobId);
        } else {
            output = getInventoryAvailabilityUploadStatusMock(uploadJobId);
        }

        List<String> tempErrorList = new List<String>();

        if (!output?.validationErrors?.isEmpty()) {
            for (String errors : output.validationErrors) {
                output.status = COMM_OCI_Constants.PROCESS_STATUS_FAILED;
                tempErrorList.add(errors);
            }
        } else if (output.recordsSkippedCount > 0) {
            tempErrorList.add(output.recordsSkippedCount + SKIPPED_RECORDS_STRING);
        }
        errorMessageList = tempErrorList;

        return output.status;
    }

    /**
     * @description Method that receives a List of COMM_Capacity__c records and returns a map with the list of
     * product and locations and respective quantity to Upload the Stock in OCI
     *
     * @param inputRequest List<COMM_Capacity__c>
     * @return Map<String, ItemLocQtyWrapper>
     */
    @TestVisible
    private static Map<String, ItemLocQtyWrapper> generateItemLocQtyMap(List<COMM_Capacity__c> inputCapacityList) {
        List<String> distinctProductList = new List<String>();

        List<ProductRequestedWrapper> productRequestedList = new List<ProductRequestedWrapper>();
        Map<String, COMM_Capacity__c> productInputMap = new Map<String, COMM_Capacity__c>();

        for (COMM_Capacity__c inputCapacity : inputCapacityList) {
            ConnectApi.OCICreateReservationSingleInputRepresentation singleReservationInput = new ConnectApi.OCICreateReservationSingleInputRepresentation();
            productInputMap.put(inputCapacity.COMM_Product__r.ProductCode, inputCapacity);
            ProductRequestedWrapper productRequested = new ProductRequestedWrapper();
            productRequested.productCode = inputCapacity.COMM_Product__r.ProductCode;
            productRequested.startDateTime = inputCapacity.COMM_ValidFrom__c;
            productRequested.endDateTime = inputCapacity.COMM_ValidTo__c;
            productRequested.quantity = (Integer) inputCapacity.COMM_CalculatedCapacity__c;
            productRequestedList.add(productRequested);
        }

        // get all distinct Products (no duplicates) to validate if there are all products exist in Product2
        distinctProductList.addAll(productInputMap.keySet());

        // get product Family from Product2
        Map<String, Product2> dbProductMap = productRep.getProductsByProductCodes(distinctProductList);
        if (productInputMap.size() <> dbProductMap.size()) {
            throw new COMM_SL_OCIStockGenerationException(COMM_OCI_Constants.ERROR_INVALID_PRODUCT, null);
        }

        // Populate list with Product, Family, Start and End datetimes
        setProductFamily(productRequestedList, dbProductMap);

        // Generate ItemLocQty with daily products and hourly locations
        Map<String, ItemLocQtyWrapper> itemLocQtyMap = generateItemLocQty(productRequestedList);

        return itemLocQtyMap;
    }

    /**
     * @description This method receives a list of requested Products and updates products family (category) with the
     * details from a List of Product2
     *
     * @param productRequestedList List<ProductRequestedWrapper> - Input and Output parameter
     * @param distinctProductMap Map<String, Product2>
     */
    private static void setProductFamily(List<ProductRequestedWrapper> productRequestedList, Map<String, Product2> distinctProductMap) {
        for (ProductRequestedWrapper productRequested : productRequestedList) {
            productRequested.family = distinctProductMap.get(productRequested.productCode).family;
        }
    }

    /**
     * @description This method generates a the OCI skus and locations based on the start and end datetimes
     * and generates a map with Product/Location/quantity to Upload the stock in OCI
     * Products will be generated based on start and end date (days)
     * Locations will be generated based on the start and end time (Hours)
     *
     * @param productRequestedList List<ProductRequestedWrapper>
     * @return Map<String, ItemLocQtyWrapper>
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public static Map<String, ItemLocQtyWrapper> generateItemLocQty(List<ProductRequestedWrapper> productRequestedList) {
        Map<String, ItemLocQtyWrapper> itemLocQtyMap = new Map<String, ItemLocQtyWrapper>();

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
                    updateMapItemLocQty(itemLocQtyMap, firstDayProduct, firstDayLocation, product.quantity);
                }
            }
            for (String fullDayProduct : fullDayProductsList) {
                for (String fullDayLocation : fullDayLocationsList) {
                    updateMapItemLocQty(itemLocQtyMap, fullDayProduct, fullDayLocation, product.quantity);
                }
            }
            for (String lastDayProduct : lastDayProductsList) {
                for (String lastDayLocation : lastDayLocationsList) {
                    updateMapItemLocQty(itemLocQtyMap, lastDayProduct, lastDayLocation, product.quantity);
                }
            }
        }

        return itemLocQtyMap;
    }

    /**
     * @description This method updates a map with ItemLocQtyWrapper.
     * Adds the product/location/quantity to the map if that product/location does not exist yet.
     * If a product/location already exists in the map the quantity is incremented with the new quantity
     *
     * @param itemLocQtyMap Map<String, ItemLocQtyWrapper>
     * @param product String
     * @param location String
     * @param quantity Integer
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void updateMapItemLocQty(Map<String, ItemLocQtyWrapper> itemLocQtyMap, String product, String location, Integer quantity) {
        // Item Loc map Key
        String itemLocKey = product + '_' + location;
        // if ItemLoc already exists, just update Quantity
        ItemLocQtyWrapper reservationItemLocQty = itemLocQtyMap.get(itemLocKey);
        if (reservationItemLocQty == null) {
            reservationItemLocQty = new ItemLocQtyWrapper();
            reservationItemLocQty.item = product;
            reservationItemLocQty.location = location;
        }
        reservationItemLocQty.quantity = quantity;
        itemLocQtyMap.put(itemLocKey, reservationItemLocQty);
    }

    /**
     * @descrition submitInventoryAvailabilityUpload Mock method to use in tests that generates a mock response based on the input
     *
     * @param input ConnectApi.BinaryInput - file with the list of locations/item/quantity to upload
     * @return ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation
     */
    private static ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation submitInventoryAvailabilityUploadMock(ConnectApi.BinaryInput input) {
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output = new ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation();

        output.success = true;
        output.uploadId = 'ce21d9b7-6646-453b-8b9a-cbf5e179c750';

        return output;
    }

    /**
     * @descrition getInventoryAvailabilityUploadStatus Mock method to use in tests that generates a mock response based on the input
     *
     * @param uploadJobId String
     * @return ConnectApi.OCIUploadInventoryAvailabilityStatusOutputRepresentation
     */
    private static ConnectApi.OCIUploadInventoryAvailabilityStatusOutputRepresentation getInventoryAvailabilityUploadStatusMock(String uploadJobId) {
        ConnectApi.OCIUploadInventoryAvailabilityStatusOutputRepresentation output = new ConnectApi.OCIUploadInventoryAvailabilityStatusOutputRepresentation();
        output.recordsProcessedCount = 1;
        DateTime dt = DateTime.now();
        output.endTimeUTC = dt.addSeconds(90).format();
        output.recordsReadCount = 1;
        output.recordsSkippedCount = 0;
        output.startTimeUTC = dt.format();
        output.status = COMM_OCI_Constants.PROCESS_STATUS_COMPLETED;
        output.success = true;
        output.uploadId = 'ce21d9b7-6646-453b-8b9a-cbf5e179c750';
        output.validationErrors = new List<String>{ 'some errors', 'other errors' };
        output.validationStatus = 'Success';

        return output;
    }
}