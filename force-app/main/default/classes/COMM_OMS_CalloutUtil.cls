/**
 * @author Rui Salgado
 * @description COMM_OMS_HttpLog__c and Callout utils
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/

public inherited sharing class COMM_OMS_CalloutUtil {
    private static HttpRequest request;
    private static List<COMM_OMS_HttpLog__c> httpLogs = new List<COMM_OMS_HttpLog__c>();

    /**
     * @description Checks HTTP log configurations and decides whether the log should be created
     * @return boolean variable which determines whether the log should be created
     */
    private static Boolean shouldCreateHttpLog() {
        return Boolean.valueOf(COMM_REP_UnifiedSettingMdt.getUnifiedSetting(COMM_OMS_Constants.HTTP_LOG_ENABLED)) &&
            (Boolean.valueOf(COMM_REP_UnifiedSettingMdt.getUnifiedSetting(COMM_OMS_Constants.HTTP_REQUEST_LOG_ENABLED)) ||
            Boolean.valueOf(COMM_REP_UnifiedSettingMdt.getUnifiedSetting(COMM_OMS_Constants.HTTP_RESPONSE_LOG_ENABLED)));
    }

    /**
     * @description Assigns value to Request fields of Http Log
     * @param httpLog HTTP log
     * @param requestHeaders Map of request headers
     * @return COMM_OMS_HttpLog__c instance
     */
    private static COMM_OMS_HttpLog__c setRequestFields(COMM_OMS_HttpLog__c httpLog, Map<String, String> requestHeaders) {
        httpLog.Method__c = request.getMethod();
        httpLog.Endpoint__c = request.getEndpoint();
        httpLog.RequestBody__c = request.getBody();
        httpLog.RequestHeader__c = JSON.serialize(requestHeaders);
        return httpLog;
    }

    /**
     * @description Assigns value to Response fields of Http Log
     * @param httpLog HTTP log
     * @param response Response
     * @return COMM_OMS_HttpLog__c instance
     */
    private static COMM_OMS_HttpLog__c setResponseFields(COMM_OMS_HttpLog__c httpLog, HttpResponse response) {
        List<String> headerKeys = response.getHeaderKeys();
        Map<String, String> responseHeaders = new Map<String, String>();
        for (String headerKey : headerKeys) {
            responseHeaders.put(headerKey, response.getHeader(headerKey));
        }
        httpLog.ResponseBody__c = response.getBody();
        httpLog.ResponseHeader__c = JSON.serialize(responseHeaders);
        httpLog.StatusCode__c = response.getStatusCode();
        return httpLog;
    }

    /**
     * @description Creates COMM_OMS_HttpLog__c object
     * @param requestHeaders Headers of Http Request
     * @param response Response of Http request
     * @return COMM_OMS_HttpLog__c instance
     */
    private static COMM_OMS_HttpLog__c createHttpLog(Map<String, String> requestHeaders, HttpResponse response) {
        COMM_OMS_HttpLog__c httpLog = new COMM_OMS_HttpLog__c();
        // Check HTTP Request configurations
        if (Boolean.valueOf(COMM_REP_UnifiedSettingMdt.getUnifiedSetting(COMM_OMS_Constants.HTTP_REQUEST_LOG_ENABLED))) {
            httpLog = setRequestFields(httpLog, requestHeaders);
        }
        // Check HTTP Response configurations
        if (Boolean.valueOf(COMM_REP_UnifiedSettingMdt.getUnifiedSetting(COMM_OMS_Constants.HTTP_RESPONSE_LOG_ENABLED))) {
            httpLog = setResponseFields(httpLog, response);
        }
        httpLogs.add(httpLog);
        return httpLog;
    }

    /**
     * @description Http request callout
     * @param endpoint Endpoint
     * @param method Http method
     * @param headers Request headers (if any)
     * @param body String body (if any)
     * @param timeout timeout (zero or negative = disabled)
     * @return Http response
     */
    @suppressWarnings('PMD.ExcessiveParameterList')
    public static HttpResponse doCallout(String endpoint, String method, Map<String, String> headers, String body, Decimal timeout) {
        request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        if (timeout > 0) {
            request.setTimeout(timeout.intValue());
        }

        if (headers != null && !headers.isEmpty()) {
            setRequestHeaders(headers);
        }

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        HttpResponse response = new Http().send(request);
        // Check HTTP Request configurations
        if (shouldCreateHttpLog()) {
            createHttpLog(headers, response);
        }
        return response;
    }

    /**
     * @description Http request callout
     * @param endpoint Endpoint
     * @param method Http method
     * @param headers Request headers (if any)
     * @param body String body (if any)
     * @return Http response
     */
    @suppressWarnings('PMD.ExcessiveParameterList')
    public static HttpResponse doCallout(String endpoint, String method, Map<String, String> headers, String body) {
        return doCallout(endpoint, method, headers, body, 0);
    }

    /**
     * @description CommercePayments http request callout
     * @param endpoint Endpoint
     * @param method Http method
     * @param headers Request headers (if any)
     * @param body String body (if any)
     * @return Http response
     */
    @suppressWarnings('PMD.ExcessiveParameterList')
    public static HttpResponse doCalloutCommercePayments(String endpoint, String method, Map<String, String> headers, String body) {
        request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);

        if (headers != null && !headers.isEmpty()) {
            setRequestHeaders(headers);
        }

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        HttpResponse response = new CommercePayments.PaymentsHttp().send(request);
        // Check HTTP Request configurations
        /* in commerce payments we cannot do dml
		if (shouldCreateHttpLog()) {
			createHttpLog(headers, response);
		}
		*/
        return response;
    }

    /**
     * @description Inserts List of Http Log objects
     * @return Insertion results
     */
    public static Database.SaveResult[] insertHttpLogs() {
        Database.SaveResult[] insertionResults = COMM_OMS_DatabaseUtil.insertRecords(httpLogs, false);
        httpLogs.clear();
        return insertionResults;
    }

    /**
     * @description Sets headers to Http request
     * @param headers Request headers
     */
    private static void setRequestHeaders(Map<String, String> headers) {
        for (String header : headers.keySet()) {
            request.setHeader(header, headers.get(header));
        }
    }

    public static Map<String, String> parseHeaders(String headerConfiguration) {
        Map<String, String> mapHeaders = new Map<String, String>();
        // Parse the HTTP Headers from the Callout Setting
        if (String.isNotBlank(headerConfiguration)) {
            for (String headers : headerConfiguration.split(';')) {
                List<String> listHeaderMember = headers.split('=>');
                if (listHeaderMember != null && listHeaderMember.size() == 2) {
                    mapHeaders.put(listHeaderMember[0].trim(), listHeaderMember[1].trim());
                }
            }
        }
        return mapHeaders;
    }
}