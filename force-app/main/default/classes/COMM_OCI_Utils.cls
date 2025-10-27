/**
 * @author Jose Passos
 * @description Class with OCI utility methods
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos    11/03/2024       Original version
 * Daniel Reto    02/05/2024       ECOMM-957
 **/
public with sharing class COMM_OCI_Utils {
    public static final Integer MAX_REQUESTS = 100;
    public static final String INVENTORY_API = 'Inventory_API';
    static List<String> hexMap = new List<String>{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
    public static final String OCI_DATE_TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.000000-00:00';
    public static final string DATETIME_LOCAL_STRING = 'LOCAL';
    public static final string DATETIME_GMT_STRING = 'GMT';

    /**
     * @description This method gets the configuration for which API should be used to manage inventory
     * It can use OCI Connect API or B2C commerce API (headless)
     * @return String with ConnectAPI or B2CCommerceAPI
     * */
    public static String getInventoryAPISetting() {
        COMM_OMS_UnifiedSettings__mdt setting = COMM_OMS_UnifiedSettings__mdt.getInstance(INVENTORY_API);
        return setting.COMM_Value__c;
    }

    /**
     * @description This method receives an existing map with list of products details by category
     * and updates it with a list of Product2 details, returning the updated map
     * @param productsMap Map<String, List<Product2>>
     * @param dbProductList List<Product2>
     * @return map with list of products by category
     * */
    public static Map<String, List<String>> groupProductsByCategory(Map<String, List<String>> productsMap, List<Product2> dbProductList) {
        if (productsMap == null) {
            productsMap = new Map<String, List<String>>();
        }
        for (Product2 product : dbProductList) {
            if (product.Family == null) {
                throw new COMM_WS_OCIException('Unknown family for product code = ' + product.ProductCode);
            } else if (product.Family.equals(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION)) {
                List<String> products = productsMap.get(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION);
                if (products == null) {
                    products = new List<String>();
                }
                products.add(product.ProductCode);
                productsMap.put(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION, products);
            } else {
                // Parking, Lounge or Fast Track
                List<String> products = productsMap.get('Others');
                if (products == null) {
                    products = new List<String>();
                }
                products.add(product.ProductCode);
                productsMap.put('Others', products);
            }
        }
        return productsMap;
    }

    /**
     * @description This method generates a list of OCI locations based on a Product Category
     * and a range of DateTimes Hour, example: Hour_NN.
     * Exception: with the exception of Subscription Products, which the location will be Subscription
     * It populates 3 lists with the locations (hours) for the first day, last day and all days in between
     * @param family String, product category
     * @param startDateTime DateTime
     * @param endDateTime DateTime
     * @param firstDayLocationsList List<String> output paramter
     * @param fullDayLocationsList List<String> output paramter
     * @param lastDayLocationsList List<String> output paramter
     * */
    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.CognitiveComplexity')
    public static void generateLocationList(
        String family,
        Datetime startDateTime,
        Datetime endDateTime,
        List<String> firstDayLocationsList,
        List<String> fullDayLocationsList,
        List<String> lastDayLocationsList
    ) {
        if (family.equals(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION)) {
            firstDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_SUBSCRIPTIONS);
            lastDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_SUBSCRIPTIONS);
            fullDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_SUBSCRIPTIONS);
        } else {
            // single day
            if (startDateTime.dateGMT() == endDateTime.dateGMT()) {
                for (Integer i = startDateTime.hourGMT(); i <= endDateTime.hourGMT(); i++) {
                    firstDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_HOUR_PATTERN + String.valueOf(i).leftPad(2, '0'));
                }
            } else {
                // first day
                for (Integer i = startDateTime.hourGMT(); i < 24; i++) {
                    firstDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_HOUR_PATTERN + String.valueOf(i).leftPad(2, '0'));
                }
                // last day
                for (Integer i = 0; i <= endDateTime.hourGMT(); i++) {
                    lastDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_HOUR_PATTERN + String.valueOf(i).leftPad(2, '0'));
                }
                // only if more than 2 days
                if (startDateTime.dateGMT().addDays(1) != endDateTime.dateGMT()) {
                    // full day
                    for (Integer i = 0; i < 24; i++) {
                        fullDayLocationsList.add(COMM_OCI_Constants.OCI_LOCATION_HOUR_PATTERN + String.valueOf(i).leftPad(2, '0'));
                    }
                }
            }
        }
    }

    /**
     * @description This method  receives a SKU and generates a list of OCI products based on
     * a range of DateTimes Days, example: <SKU>_YYYYMMDD
     * It populates 3 lists with the products (daily products) for the first day, last day and all days in between
     * @param productCode String, product category
     * @param startDateTime DateTime
     * @param endDateTime DateTime
     * @param firstDayProducts List<String> output paramter
     * @param fullDayProducts List<String> output paramter
     * @param lastDayProducts List<String> output paramter
     * */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void generateProductList(
        String productCode,
        Datetime startDateTime,
        Datetime endDateTime,
        List<String> firstDayProducts,
        List<String> fullDayProducts,
        List<String> lastDayProducts
    ) {
        DateTime calcDate = startDateTime;
        // first day
        firstDayProducts.add(productCode + '_' + calcDate.formatGMT(COMM_OCI_Constants.DATE_FORMAT));
        // more than 1 day
        if (startDateTime.dateGMT() != endDateTime.dateGMT()) {
            while (true) {
                calcDate = calcDate.addDays(1);
                if (calcDate.dateGMT() == endDateTime.dateGMT()) {
                    lastDayProducts.add(productCode + '_' + calcDate.formatGMT(COMM_OCI_Constants.DATE_FORMAT));
                    break;
                }
                fullDayProducts.add(productCode + '_' + calcDate.formatGMT(COMM_OCI_Constants.DATE_FORMAT));
            }
        }
    }

    /**
     * @description Generates a GUID
     * */
    public static String newGuid() {
        String randomStringAsHex = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));

        String versionHexBits = randomStringAsHex.SubString(14, 16); // 7th bit
        String variantHexBits = randomStringAsHex.SubString(18, 20); // 9th bit

        Integer versionIntBits = convertHexToInt(versionHexBits);
        Integer variantIntBits = convertHexToInt(variantHexBits);

        Integer versionShiftedIntBits = versionIntBits & 15 | 64; // (i & 0x0f) | 0x40
        Integer variantShiftedIntBits = variantIntBits & 63 | 128; // (i & 0x3f) | 0x80

        String versionShiftedHexBits = convertIntToHex(versionShiftedIntBits); // Always begins with 4
        String variantShiftedHexBits = convertIntToHex(variantShiftedIntBits); // Always begins with one of 8,9,a,b

        String guid =
            randomStringAsHex.SubString(0, 8) +
            '-' +
            randomStringAsHex.SubString(8, 12) +
            '-' +
            versionShiftedHexBits +
            randomStringAsHex.SubString(14, 16) +
            '-' +
            variantShiftedHexBits +
            randomStringAsHex.SubString(18, 20) +
            '-' +
            randomStringAsHex.substring(20);

        return guid;
    }

    /**
     * @description This method generates a list of OCI locations based on a Product Category
     * and a range of DateTimes Hour, example: Hour_NN.
     * Exception: with the exception of Subscription Products, which the location will be Subscription
     * It populates 3 lists with the locations (hours) for the first day, last day and all days in between
     * @param family String, product category
     * @param input COMM_WS_AvailabilityInput input
     * @param productDayByLocationMap Map<String,Set<String>> output parameter
     * dayLocationsList to delete
     * */
    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.CognitiveComplexity')
    public static void generateProductLocationList(
        String family,
        COMM_WS_AvailabilityInput input,
        Map<String, List<String>> productDayByLocationMap,
        Map<String, List<String>> productsMap
    ) {
        for (COMM_WS_AvailabilityInput.Product inputProduct : input.products) {
            if (productsMap.get(family).contains(inputProduct.productId)) {
                if (family.equals(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION)) {
                    DateTime startDate = inputProduct.startDate;
                    DateTime endDate = inputProduct.endDate;
                    while (startDate.dateGMT() <= endDate.dateGMT()) {
                        String productIdDay = inputProduct.productId + '_' + startDate.formatGMT(COMM_OCI_Constants.DATE_FORMAT);
                        addProductDay(COMM_OCI_Constants.OCI_LOCATION_SUBSCRIPTIONS, productIdDay, productDayByLocationMap);
                        startDate = startDate.addDays(1);
                    }
                } else {
                    DateTime startDate = inputProduct.startDate;
                    DateTime endDate = inputProduct.endDate;
                    while (startDate.dateGMT() <= endDate.dateGMT()) {
                        Integer startHour = (startDate.dateGMT() == inputProduct.startDate.dateGMT()) ? inputProduct.startDate.hourGMT() : 0;
                        Integer endHour = (startDate.dateGMT() == inputProduct.endDate.dateGMT()) ? inputProduct.endDate.hourGMT() : 23;
                        for (Integer i = startHour; i <= endHour; i++) {
                            String locationValue = COMM_OCI_Constants.OCI_LOCATION_HOUR_PATTERN + String.valueOf(i).leftPad(2, '0');
                            String productIdDay = inputProduct.productId + '_' + startDate.formatGMT(COMM_OCI_Constants.DATE_FORMAT);
                            addProductDay(locationValue, productIdDay, productDayByLocationMap);
                        }
                        startDate = startDate.addDays(1);
                    }
                }
            }
        }
    }

    /**
     * @description Function to add product day to the map
     * */
    private static void addProductDay(String location, String productIdDay, Map<String, List<String>> productDayByLocationMap) {
        if (productDayByLocationMap.containsKey(location)) {
            productDayByLocationMap.get(location).add(productIdDay);
        } else {
            productDayByLocationMap.put(location, new List<String>{ productIdDay });
        }
    }

    /**
     * @description Converts 2 Hexadecimal character to Integer
     * */
    private static Integer convertHexToInt(String hex) {
        Integer d0 = hexMap.IndexOf(hex.Substring(1, 2));
        Integer d1 = hexMap.IndexOf(hex.Substring(0, 1));

        Integer intval = d0 + (d1 * 16);
        return intval;
    }

    /**
     * @description Converts 2 Integer character to Hexadecimal
     * */
    private static String convertIntToHex(Integer intval) {
        String hs0 = hexMap.Get(intval & 15); // i & 0x0f
        String hs1 = hexMap.Get(((intval >> 4) & 15)); //(i >> 4) & 0x0f
        return hs1 + hs0;
    }

    /**
     * @description Prepares a response for a REST API call.
     * @param res The response object to update
     * @param response The data to include in the response, formatted as a map
     */
    public static void setResponse(RestResponse res, Integer statusCode, String responseBody) {
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = statusCode;
        if (!String.isBlank(responseBody)) {
            res.responseBody = Blob.valueOf(responseBody);
        }
    }
}