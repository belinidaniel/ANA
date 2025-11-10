/**
 * @author Carlos Fusco
 * @description HTTP Callout Utility Class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco    19/03/2024		Original version
 **/
public class COMM_HttpCallout_Utility {
    public static final String HEADER_CONTENT_TYPE = 'Content-Type';
    public static final String HEADER_CONTENT_TYPE_JSON = 'application/json';
    public static final String HTTP_GET_METHOD = 'GET';
    public static final String HTTP_POST_METHOD = 'POST';
    public static final String HTTP_PUT_METHOD = 'PUT';
    public static final String HTTP_PATCH_METHOD = 'PATCH';

    /**
     * @description Method to build URL query parameters
     *
     * @param queryParametersMap Map with parameters to set HTTP callout URL
     * @return String with query parameters to add on HTTP callout URL
     */
    public static String getUrlQueryParameters(Map<String, String> queryParametersMap) {
        String queryParameters = '';
        if (queryParametersMap != null && queryParametersMap.size() > 0) {
            for (String key : queryParametersMap.keySet()) {
                if (String.isEmpty(queryParameters)) {
                    queryParameters = '?' + key + '=' + queryParametersMap.get(key);
                } else {
                    queryParameters += '&' + key + '=' + queryParametersMap.get(key);
                }
            }
        }
        return queryParameters;
    }

    /**
     * @description Set an HTTP Request based on details passed as argument
     *
     * @param method HTTP method in which the request will rely
     * @param url Endpoint url for the request
     * @param httpHeaders Headers request specification
     * @return HTTPRequest definition
     */
    public static HttpRequest setHttpRequest(String method, String url, Map<String, String> httpHeaders) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(method);
        httpRequest.setEndpoint(url);
        if (!httpHeaders.containsKey(HEADER_CONTENT_TYPE)) {
            httpRequest.setHeader(HEADER_CONTENT_TYPE, HEADER_CONTENT_TYPE_JSON);
        }
        if (httpHeaders != null) {
            for (String httpHeaderKey : httpHeaders.keySet()) {
                httpRequest.setHeader(httpHeaderKey, httpHeaders.get(httpHeaderKey));
            }
        }
        return httpRequest;
    }

    /**
     * @description Perform HTTP Callout
     *
     * @param httpRequest HTTPRequest definition for the Callout
     * @return HttpResponse with the result of the Callout
     */
    public static HttpResponse doCallout(HttpRequest httpRequest) {
        HttpResponse httpResponse;

        try {
            Http http = new Http();
            System.debug('Callout:httpRequest: '+httpRequest);
            httpResponse = http.send(httpRequest);
            System.debug('Callout:httpResponse: '+httpResponse);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'HTTP Callout Utility doCallout', 'COMM_GEN_HttpCalloutUtility');
        }

        return httpResponse;
    }

    /**
     * @description Method for HTTP callouts request with GET verb
     *
     * @param url Callout endpoint URL
     * @param httpRequestHeaders HTTP Request headers definition
     * @param queryParameters Map with parameters to set HTTP request GET URL
     * @return HTTP Response with result of callout
     */
    public static HttpResponse httpGetCallout(String url, Map<String, String> httpRequestHeaders, Map<String, String> queryParameters) {
        url += getUrlQueryParameters(queryParameters);
        HttpRequest httpRequest = setHttpRequest(HTTP_GET_METHOD, url, httpRequestHeaders);
        return doCallout(httpRequest);
    }

    /**
     * @description Method for HTTP callouts request with POST verb
     *
     * @param url Callout endpoint URL
     * @param httpRequestHeaders HTTP Request headers definition
     * @param httpRequestBody HTTP Request Body definition
     * @return HTTP Response with result of callout
     */
    public static HttpResponse httpPostCallout(String url, Map<String, String> httpRequestHeaders, String httpRequestBody) {
        HttpRequest httpRequest = setHttpRequest(HTTP_POST_METHOD, url, httpRequestHeaders);
        if (httpRequestBody != null) {
            httpRequest.setBody(httpRequestBody);
        }
        return doCallout(httpRequest);
    }

    /**
     * @description Method for HTTP callouts request with PUT verb
     *
     * @param url Callout endpoint URL
     * @param httpRequestHeaders HTTP Request headers definition
     * @param httpRequestBody HTTP Request Body definition
     * @return HTTP Response with result of callout
     */
    public static HttpResponse httpPutCallout(String url, Map<String, String> httpRequestHeaders, String httpRequestBody) {
        HttpRequest httpRequest = setHttpRequest(HTTP_PUT_METHOD, url, httpRequestHeaders);
        if (httpRequestBody != null) {
            httpRequest.setBody(httpRequestBody);
        }
        return doCallout(httpRequest);
    }

    /**
     * @description Method for HTTP callouts request with PATCH verb
     *
     * @param url Callout endpoint URL
     * @param httpRequestHeaders HTTP Request headers definition
     * @param httpRequestBody HTTP Request Body definition
     * @return HTTP Response with result of callout
     */
    public static HttpResponse httpPatchCallout(String url, Map<String, String> httpRequestHeaders, String httpRequestBody) {
        HttpRequest httpRequest = setHttpRequest(HTTP_PATCH_METHOD, url, httpRequestHeaders);
        if (httpRequestBody != null) {
            httpRequest.setBody(httpRequestBody);
        }
        return doCallout(httpRequest);
    }

    /**
     * @description Method to generate an Error Log with Callout Information
     *
     * @param e Salesforce Exception that caused the error
     * @param requestBody JSON Body of the Request sent to server
     * @param response HTTP Response that was received from server
     * @param classOrigin Name of the Class where the error originated
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void logResponseError(Exception e, String requestBody, HttpResponse response, String classOrigin) {
        FW_ErrorAndMonitoringLog.ErrorDetailsBuilder errorLogBuilder = new FW_ErrorAndMonitoringLog.ErrorDetailsBuilder()
            .setCategory(FW_ErrorAndMonitoringLog.categoryType.Apex_Class)
            .setActorId(UserInfo.getUserId())
            .setOrigin(classOrigin)
            .setRequestBody(requestBody)
            .setResponseBody(response.getBody())
            .setErrorMessage(response.getStatusCode() + ' | ' + response.getStatus() + ' | ' + e.getStackTraceString() + ' | ' + e.getMessage());
        new FW_SystemNotificationPublr(errorLogBuilder.build());
    }

    /**
     * @description Check if HTTP Response to the callout HTTP Request is successfull
     *
     * @param httpResponse Callout HTTP Response for a integration HTTP Request
     * @return Boolean flagging if HTTP Response is successfull
     */
    public static Boolean isHttpResponseSuccesfull(HttpResponse httpResponse) {
        return httpResponse != null &&
            (httpResponse.getStatusCode() == 200 ||
            httpResponse.getStatusCode() == 201 ||
            httpResponse.getStatusCode() == 204);
    }

    /**
     * @description Class to represent an Exception throwed during processing of Callout services
     */
    public class CalloutServiceException extends Exception {
    }
}