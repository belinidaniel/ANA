/**
 * @author Ricardo Dias
 * @description Pricing Webservice service layer class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024       Original version
 * Ricardo Dias    08/04/2024       Rework service
 * Ricardo Dias    15/05/2024       Update date validation
 **/
public inherited sharing class COMM_SL_WS_Pricing {
    private static final String INVALID_START_DATE_TIME_FORMAT_ERROR = 'Invalid Start date/time format';
    private static final String INVALID_END_DATE_TIME_FORMAT_ERROR = 'Invalid End date/time format';
    private static final String INVALID_MIN_REQ_HOURS_ERROR = 'Invalid Minimum Required Hours';
    private static final String NUMBER_DAYS_ERROR = 'Incorrect Number of days';
    private static final String START_GREATER_ERROR = 'Start date set after End date';
    private static final String START_SETPAST_ERROR = 'Start date set in the past';
    private static final String END_SETPAST_ERROR = 'End date set in the past';
    private static final String START_EQUAL_END_ERROR = 'Start date equal to End date';
    private static final String PRODUCT_NOT_FOUND_ERROR = 'Product not found';
    private static final String PARKING = 'Parking';
    private static final String PRICE = 'price';
    private static final String PRICEBOOK_ENTRY_ID = 'pricebookEntryId';
    private static final String START_DATE = 'startDate';
    private static final String END_DATE = 'endDate';
    private static final String PRODUCT_ID = 'productId';
    private static final String ERROR = 'error';
    private static final String MESSAGE = 'message';
    public static final String VALIDATED = 'validated';

    private COMM_REP_PricebookEntry pbeRep;
    private COMM_SL_PricingCalculation pricingCalculationInstance;
    private COMM_REP_ResellerAssortment resellerAssortmentRep;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_SL_WS_Pricing() {
        pbeRep = new COMM_REP_PricebookEntry();
        pricingCalculationInstance = new COMM_SL_PricingCalculation();
        resellerAssortmentRep = new COMM_REP_ResellerAssortment();
    }

    @TestVisible
    private COMM_SL_WS_Pricing(COMM_REP_PricebookEntry pbeRep) {
        this.pbeRep = pbeRep;
        pricingCalculationInstance = new COMM_SL_PricingCalculation();
        this.resellerAssortmentRep = resellerAssortmentRep;
    }

    /**
     * @description Calculates pricing based on the provided request and updates the response accordingly
     *
     * @param requestMap The request parameters as a map
     * @return A map with a single entry where the key is either 'validated' or an error message, and the value is the pricing information or null in case of error
     */
    public Map<String, Object> calculatePricingResponse(Map<String, Object> requestMap) {

        Set<String> productCodes = getProductCodes(requestMap);
        Map<String, List<PricebookEntry>> pricebookEntries = getPriceBookEntriesByProductCodes(productCodes, null);
        List<Object> productsList = (List<Object>) requestMap.get(COMM_GEN_Utility.PRODUCT);

        return parseAndValidateResponse(pricebookEntries, productsList);

    }

    /**
     * @description Calculates pricing based on the provided request and updates the response accordingly for Reseller
     *
     * @param requestMap The request parameters as a map
     * @param resellerAssortmentList Related Reseller Assortment  records List
     * @return A map with a single entry where the key is either 'validated' or an error message, and the value is the pricing information or null in case of error
     */
    public Map<String, Object> calculatePricingResellerResponse(Map<String, Object> requestMap, List<COMM_ResellerAssortment__c> resellerAssortmentList) {

        Set<String> productCodes = getProductCodes(requestMap);
        Set<Id> pricebookIdSet = new Set<Id>();
        for(COMM_ResellerAssortment__c resellerAssortmentRecord : resellerAssortmentList) {
            pricebookIdSet.add(resellerAssortmentRecord.COMM_PriceBook__c);
        }
        Map<String, List<PricebookEntry>> pricebookEntries = getPriceBookEntriesByProductCodes(productCodes, pricebookIdSet);
        List<Object> productsList = (List<Object>) requestMap.get(COMM_GEN_Utility.PRODUCT);

        return parseAndValidateResponse(pricebookEntries, productsList);

    }

    /**
     * @description Method to parse and validate the request parameters
     *
     * @param pricebookEntries 
     * @param productsList 
     * @return A map with a single entry where the key is either 'validated' or an error message, and the value is the pricing information or null in case of error
     */
    public Map<String, Object> parseAndValidateResponse(Map<String, List<PricebookEntry>> pricebookEntries, List<Object> productsList) {
        List<Map<String, Object>> pricedProductsMap = new List<Map<String, Object>>();
        List<Map<String, Object>> errorsMap = new List<Map<String, Object>>();

        for (Object productObj : productsList) {
            Map<String, Object> productMap = (Map<String, Object>) productObj;
            String productId = (String) productMap.get(PRODUCT_ID);
            List<PricebookEntry> entriesList = pricebookEntries.get(productId);

            // Parsing and validation
            Datetime startDateTime = String.isNotBlank(String.valueOf(productMap.get(START_DATE)))
                ? COMM_RestServices_Utility.parseDatetime((String) productMap.get(START_DATE))
                : null;
            Datetime endDateTime = String.isNotBlank(String.valueOf(productMap.get(END_DATE)))
                ? COMM_RestServices_Utility.parseDatetime((String) productMap.get(END_DATE))
                : null;
            String category = entriesList != null && !entriesList.isEmpty() ? entriesList[0].Product2.Family : '';
            String validationResponse = validateData(startDateTime, endDateTime, category);

            if (VALIDATED.equals(validationResponse) && entriesList != null) {
                pricedProductsMap.add(getPricingMap(entriesList, startDateTime, endDateTime));
            } else {
                errorsMap.add(prepareErrorMap(productId, validationResponse, startDateTime, endDateTime));
            }
        }

        return prepareResponseMap(pricedProductsMap, errorsMap);
    }

    /**
     * @description Retrieves pricing details for given product codes over a specified date range
     *
     * @param pricebookEntriesList A List of pricebook Entries
     * @param startDateTime The start date of the pricing period
     * @param endDateTime The end date of the pricing period
     * @return A list of maps, each containing pricing for a product
     */
    private Map<String, Object> getPricingMap(List<PricebookEntry> pricebookEntriesList, Datetime startDateTime, Datetime endDateTime) {
        // Calculate pricing for each PricebookEntry over the given date range
        Map<PricebookEntry, Decimal> pbeCostMap = pricingCalculationInstance.getPriceByPBE(pricebookEntriesList, startDateTime, endDateTime);
        // Since pbeCostMap is expected to only have one entry, we can directly access this entry without a loop
        PricebookEntry entry = pbeCostMap.keySet().iterator().next();
        Decimal cost = pbeCostMap.get(entry);

        return prepareProductCostMap(entry, cost, startDateTime, endDateTime);
    }

    /**
     * @description Fetches Valid(Valid From <= NOW AND Valid To >= NOW) Active PricebookEntry records for specified product codes and organizes PricebookEntry records by their associated product codes
     *
     * @param productCodesSet A Set of String representing the product codes to retrieve PricebookEntries for
     * @return A Map with product codes as keys and Lists of PricebookEntry records as values. Each List contains all PricebookEntries associated with its product code
     */
    private Map<String, List<PricebookEntry>> getPriceBookEntriesByProductCodes(Set<String> productCodesSet, Set<Id> pricebookIdSet) {
        List<PricebookEntry> pbeList;
        if(pricebookIdSet == null){
            pbeList = pbeRep.getPBEByProductCodeList(productCodesSet);
        } else {
            pbeList = pbeRep.getPBEByProductCodeList(productCodesSet, pricebookIdSet);
        }

        Map<String, List<PricebookEntry>> pricebookEntriesMap = new Map<String, List<PricebookEntry>>();

        for (PricebookEntry entry : pbeList) {
            String productCode = entry.Product2.ProductCode;

            if (!pricebookEntriesMap.containsKey(productCode)) {
                pricebookEntriesMap.put(productCode, new List<PricebookEntry>());
            }

            pricebookEntriesMap.get(productCode).add(entry);
        }

        return pricebookEntriesMap;
    }

    /**
     * @description Validates the input data for a specific category within a given date range.
     *
     * @param startDateTime The start date and time for the validation period.
     * @param endDateTime The end date and time for the validation period.
     * @param category The category of the product or service being validated.
     * @return A String indicating the result of the validation: a success message or an error message indicating the nature of the validation failure.
     */
    private String validateData(Datetime startDateTime, Datetime endDateTime, String category) {
        //Return an error message if the category string is empty
        if (String.isEmpty(category)) {
            return PRODUCT_NOT_FOUND_ERROR;
        }

        //Return an error message if start date is null
        if (startDateTime == null) {
            return INVALID_START_DATE_TIME_FORMAT_ERROR;
        }

        //Return an error message if start date is set in past
        if (startDateTime < DateTime.NOW()) {
            return START_SETPAST_ERROR;
        }

        //Return an error message if the end datetime is before as the start datetime
        if (endDateTime < startDateTime) {
            return START_GREATER_ERROR;
        }

        //Perform additional, specific validation if the category is "PARKING" and return the result
        if (category == PARKING) {
            return validateParkingCategory(startDateTime, endDateTime);
        }

        return VALIDATED;
    }

    /**
     * @description Validates the date and time range for parking based on specific business rules.
     *
     * @param startDateTime The start datetime of the parking period.
     * @param endDateTime The end datetime of the parking period.
     * @return A String indicating the validation result: an error message for invalid inputs or a success message for valid inputs.
     */
    private String validateParkingCategory(Datetime startDateTime, Datetime endDateTime) {
        //Return an error message if end date is null
        if (endDateTime == null) {
            return INVALID_END_DATE_TIME_FORMAT_ERROR;
        }

        //Return an error message if end date is set in past
        if (endDateTime < DateTime.NOW()) {
            return END_SETPAST_ERROR;
        }

        //Return an error message if the start datetime is equal to end datetime
        if (startDateTime == endDateTime) {
            return START_EQUAL_END_ERROR;
        }

        //Check if the total days is less than the minimum number of charged days
        Integer totalDays = startDateTime.date().daysBetween(endDateTime.date()) + 1;
        Decimal minNumberOfDays = COMM_PricingCalculationSetting__mdt.getInstance(PARKING).COMM_MinimumChargedDays__c;

        if (totalDays < minNumberOfDays.intValue()) {
            return NUMBER_DAYS_ERROR;
        }

        //Check if the total hours is less than the minimum required hours for parking
        Decimal minRequiredHours = COMM_PricingCalculationSetting__mdt.getInstance(PARKING).COMM_MinimumRequiredHours__c;
        Decimal hours = (endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60);

        if (hours < minRequiredHours) {
            return INVALID_MIN_REQ_HOURS_ERROR;
        }

        return VALIDATED;
    }

    /**
     *@description Extracts product codes from a request map
     *
     * @param requestMap The request payload containing product information
     * @return A set of unique product codes extracted from the request
     */
    private Set<String> getProductCodes(Map<String, Object> requestMap) {
        List<Object> productList = (List<Object>) requestMap.get(COMM_GEN_Utility.PRODUCT);
        Set<String> productCodesSet = new Set<String>();

        for (Object productObject : productList) {
            Map<String, Object> product = (Map<String, Object>) productObject;

            // Extract the productId and add it to the Set
            String productId = (String) product.get(PRODUCT_ID);
            productCodesSet.add(productId);
        }
        return productCodesSet;
    }

    /**
     * @description  Creates a map detailing the cost of a product over a specified time period
     *
     * @param product The product entry from the pricebook
     * @param totalCost The total cost of the product
     * @param startDateTime Start of the time period
     * @param endDateTime End of the time period
     * @return A map containing the product's code, its total cost, and the time period
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Map<String, Object> prepareProductCostMap(PricebookEntry product, Decimal totalCost, Datetime startDateTime, Datetime endDateTime) {
        Map<String, Object> productCostMap = new Map<String, Object>();
        productCostMap.put(PRODUCT_ID, product.ProductCode);
        productCostMap.put(PRICE, totalCost);
        productCostMap.put(START_DATE, startDateTime);
        productCostMap.put(END_DATE, endDateTime);
        productCostMap.put(PRICEBOOK_ENTRY_ID, product.Id);
        return productCostMap;
    }

    /**
     * @description Prepares a map containing error details for a product
     *
     * @param productCode The product's unique identifier
     * @param messageError Description of the error
     * @param startDateTime When the error started
     * @param endDateTime When the error ended
     * @return A map with error details, keyed by specific identifiers
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Map<String, Object> prepareErrorMap(String productCode, String messageError, Datetime startDateTime, Datetime endDateTime) {
        Map<String, Object> errorMap = new Map<String, Object>();
        errorMap.put(PRODUCT_ID, productCode);
        errorMap.put(MESSAGE, messageError);
        errorMap.put(START_DATE, startDateTime);
        errorMap.put(END_DATE, endDateTime);
        return errorMap;
    }

    /**
     * @description Prepares a response map containing product information and any errors
     *
     * @param productInfoList A list of maps, each representing details of a product
     * @param errorList A list of maps, each containing error details
     * @return A map with keys 'product' and 'error' leading to the respective lists
     */
    private Map<String, Object> prepareResponseMap(List<Map<String, Object>> productInfoList, List<Map<String, Object>> errorList) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('product', productInfoList);
        response.put('error', errorList);
        return response;
    }
}