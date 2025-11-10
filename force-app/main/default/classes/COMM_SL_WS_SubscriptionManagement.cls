/**
 * @author Daniel Lascas
 * @description Subscription Management Service class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/06/2024       Original version
 * Miguel Justo     22/08/2024       Updated Variables
 **/
public with sharing class COMM_SL_WS_SubscriptionManagement {
    private COMM_IREP_Subscription subscriptionRep;
    private COMM_IDO_SubscriptionManagementMapping subscriptionMappingDo;

    //Response Fields
    @TestVisible
    private static final String COUNT_KEY = 'count';
    private static final String PAGE_SIZE_KEY = 'pageSize';
    private static final String CURRENT_PAGE_KEY = 'currentPage';
    private static final String DATA_KEY = 'data';

    //Data Fields
    @TestVisible
    private static final String PERIODICITY_KEY = 'periodicity';
    private static final String EXPIRED_KEY = 'isExpired';
    private static final String CURRENCY_KEY = 'currency';
    private static final String IN_RENEWAL_KEY = 'isInRenewal';
    private static final String SUBSCRIPTION_NUMBER_KEY = 'subscriptionNumber';

    //Default Values
    private static final Integer DEFAULT_PAGE = 0;
    private static final String EMPTY_VALUE = '';

    //Custom Error Messages
    private static final String END_DATE_REQUIRED_ERROR = 'End Date is Required when Start Date is Supplied';

    /**
     * @description Constructor to initialize REP classes
     */
    public COMM_SL_WS_SubscriptionManagement() {
        this.subscriptionRep = new COMM_REP_Subscription();
        this.subscriptionMappingDo = new COMM_DO_SubscriptionManagementMapping();
    }

    @TestVisible
    private COMM_SL_WS_SubscriptionManagement(COMM_IREP_Subscription subscriptionRep, COMM_IDO_SubscriptionManagementMapping subscriptionMappingDo) {
        this.subscriptionRep = subscriptionRep;
        this.subscriptionMappingDo = subscriptionMappingDo;
    }

    /**
     * @description Retrieve customer's subscription list based on request
     *
     * @param accountId Id of the Customer's Account in Salesforce
     * @param requestMap Map with request received from REST service
     * @return Map with data to return as response to REST eervice
     */
    public Map<String, Object> searchSubscriptionList(String accountId, Map<String, Object> requestMap) {
        SubscriptionManagementRequest requestBody = new SubscriptionManagementRequest().parseMap(requestMap);

        //Verify if Request has Start Date. If it has then End Date is required
        if (requestBody.orderStartDate != null && requestBody.orderEndDate == null) {
            //Throw Error Exeption (error is captured by WS Class and logged)
            throw new COMM_RestServices_Utility.RestServiceException(END_DATE_REQUIRED_ERROR);
        }

        return buildResponseMap(accountId, requestBody);
    }

    /**
     * @description Build JSON with Response Body to return to REST service
     *
     * @param accountId Id of the Customer's Account in Salesforce
     * @param requestBody Request Body received from REST service
     * @return Map structured as a JSON with response body
     */
    private Map<String, Object> buildResponseMap(String accountId, SubscriptionManagementRequest requestBody) {
        //Query for existing Subscriptions based on filters in Request
        List<COMM_Subscription__c> subscriptionList = subscriptionRep.getSubscriptionsByAccountId(
            accountId,
            requestBody.contactId,
            requestBody.orderStartDate,
            requestBody.orderEndDate,
            requestBody.reservationStartDate,
            requestBody.reservationEndDate,
            requestBody.orderNumber,
            requestBody.airports,
            requestBody.status,
            requestBody.licensePlate,
            requestBody.secondaryLicensePlate,
            requestBody.affiliateNumber
        );

        //Verify if Page Number and Size was provided in request. If not use Default Values.
        Integer pageSize = requestBody.pageSize != null && requestBody.pageSize >= 0 ? requestBody.pageSize : subscriptionList.size();
        Integer page = requestBody.page != null && requestBody.page >= 0 ? requestBody.page : DEFAULT_PAGE;

        //Verify Index based on Subscription List, Page Size and Number
        Integer startingIndex = page * pageSize;
        Integer maxItemIndex = (page + 1) * pageSize;
        Integer maxIndex = maxItemIndex > subscriptionList.size() ? subscriptionList.size() : maxItemIndex;

        //Generate Subscription Data List
        List<Map<String, Object>> subDataList = new List<Map<String, Object>>();
        for (Integer index = startingIndex; index < maxIndex; index++) {
            subDataList.add(buildSubscriptionData(subscriptionList[index]));
        }

        //Build Response Map
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(COUNT_KEY, subscriptionList.size());
        responseMap.put(PAGE_SIZE_KEY, pageSize);
        responseMap.put(CURRENT_PAGE_KEY, page);
        responseMap.put(DATA_KEY, subDataList);

        return responseMap;
    }

    /**
     * @description Build JSON with Subscription Data
     *
     * @param subscription COMM_Subscription__c Record with Data to be mapped
     * @return Map structured as a JSON with Subscription Data
     */
    private Map<String, Object> buildSubscriptionData(COMM_Subscription__c subscription) {
        //Generate JSON with Mapping according to Metadata
        Map<String, Object> subDataMap = subscriptionMappingDo.mapJsonFromSObject(subscription, new Map<String, Object>());

        //Verify if End Date is set in the past (Subscription Expired)
        subDataMap.put(EXPIRED_KEY, subscription.COMM_EndDate__c < System.now());

        //Set Subscription Currency to User's Default
        subDataMap.put(CURRENCY_KEY, UserInfo.getDefaultCurrency());

        //Convert Periodicity Value to Integer
        if (subDataMap.containsKey(PERIODICITY_KEY)) {
            subDataMap.put(PERIODICITY_KEY, getPeriodicityAsInteger(String.valueOf(subDataMap.get(PERIODICITY_KEY))));
        }

        //If Subscription Number is empty (= null) then add value as empty string
        if (!subDataMap.containsKey(SUBSCRIPTION_NUMBER_KEY) || subDataMap.get(SUBSCRIPTION_NUMBER_KEY) == null) {
            subDataMap.put(SUBSCRIPTION_NUMBER_KEY, EMPTY_VALUE);
        }

        return subDataMap;
    }

    /**
     * @description Method to Convert Periodicity to it's Integer value
     *
     * @param periodicityValue String value of Periodicity
     * @return Periodicity Value as an Integer
     */
    private Integer getPeriodicityAsInteger(String periodicityValue) {
        Integer pediocicityAsInteger;
        if (COMM_DO_Subscription.PERIODICITY_MONTHLY.equals(periodicityValue)) {
            pediocicityAsInteger = 2;
        } else if (COMM_DO_Subscription.PERIODICITY_QUARTERLY.equals(periodicityValue)) {
            pediocicityAsInteger = 3;
        } else if (COMM_DO_Subscription.PERIODICITY_HALF_YEARLY.equals(periodicityValue)) {
            pediocicityAsInteger = 4;
        } else if (COMM_DO_Subscription.PERIODICITY_YEARLY.equals(periodicityValue)) {
            pediocicityAsInteger = 5;
        } else {
            pediocicityAsInteger = 1;
        }
        return pediocicityAsInteger;
    }

    /**
     * @description Class that represents expected request body
     */
    private class SubscriptionManagementRequest {
        private Integer page;
        private Integer pageSize;
        private Datetime orderStartDate;
        private Datetime orderEndDate;
        private Datetime reservationStartDate;
        private Datetime reservationEndDate;
        private String orderNumber;
        private List<String> airports;
        private Boolean status;
        private String licensePlate;
        private String secondaryLicensePlate;
        private String affiliateNumber;
        private String contactId;

        /**
         * @description Method to parse JSON
         * @param jsonRequest JSON to parse
         * @return Instance of Request Class
         */
        @SuppressWarnings('PMD.CognitiveComplexity')
        private SubscriptionManagementRequest parseMap(Map<String, Object> requestMap) {
            //Verify for not-string fields if they're empty (value => "").
            //If value is empty convert to null to avoid invalid format error during deserialization.
            if (requestMap.containsKey('page') && String.isBlank(String.valueOf(requestMap.get('page')))) {
                requestMap.put('page', null);
            }
            if (requestMap.containsKey('pageSize') && String.isBlank(String.valueOf(requestMap.get('pageSize')))) {
                requestMap.put('pageSize', null);
            }
            if (requestMap.containsKey('orderStartDate') && String.isBlank(String.valueOf(requestMap.get('orderStartDate')))) {
                requestMap.put('orderStartDate', null);
            }
            if (requestMap.containsKey('orderEndDate') && String.isBlank(String.valueOf(requestMap.get('orderEndDate')))) {
                requestMap.put('orderEndDate', null);
            }
            if (requestMap.containsKey('reservationStartDate') && String.isBlank(String.valueOf(requestMap.get('reservationStartDate')))) {
                requestMap.put('reservationStartDate', null);
            }
            if (requestMap.containsKey('reservationEndDate') && String.isBlank(String.valueOf(requestMap.get('reservationEndDate')))) {
                requestMap.put('reservationEndDate', null);
            }
            if (requestMap.containsKey('airports') && String.isBlank(String.valueOf(requestMap.get('airports')))) {
                requestMap.put('airports', null);
            }
            if (requestMap.containsKey('status') && String.isBlank(String.valueOf(requestMap.get('status')))) {
                requestMap.put('status', null);
            }

            return (SubscriptionManagementRequest) JSON.deserialize(JSON.serialize(requestMap), SubscriptionManagementRequest.class);
        }
    }
}