/**
 * @author Daniel Lascas
 * @description Service Layer Class with methods to communicate with SAP for
 * financial document generation and retrieval
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer		Date             Description
 * ------------------------------------------------------------------------------------
 * Daniel Lascas    01/04/2024       ECOMM-194: Original version
 **/
public with sharing class COMM_WS_SAPFinancialDocument implements COMM_IWS_SAPFinancialDocument {
    //Developer Name of Custom Metadata Record where callout settings are stored
    private final static string POST_SETTING_NAME = 'SAP_POST_FinancialDocument';
    private final static string GET_SETTING_NAME = 'SAP_GET_FinancialDocument';

    /**
     * @description Method to send a request to SAP to generate an Invoice Document
     *
     * @param requestBodyMap Map with the body of the request
     * @return HTTP Response from SAP
     **/
    public HttpResponse postFinancialDocument(Map<String, Object> requestBodyMap) {
        COMM_CalloutSetting__mdt setting = COMM_CalloutSetting__mdt.getInstance(POST_SETTING_NAME);
        String endpointUrl = setting.COMM_NamedCredential__c + setting.COMM_Path__c;
        return COMM_HttpCallout_Utility.httpPostCallout(endpointUrl, new Map<String, String>(), JSON.serialize(requestBodyMap));
    }

    /**
     * @description Method to send a request to SAP to get an Invoice Document
     *
     * @param requestMap Map with the request parameters
     * @return HTTP Response from SAP
     **/
    public HttpResponse getFinancialDocument(Map<String, String> requestMap) {
        COMM_CalloutSetting__mdt setting = COMM_CalloutSetting__mdt.getInstance(GET_SETTING_NAME);
        String endpointUrl = setting.COMM_NamedCredential__c + setting.COMM_Path__c;
        return COMM_HttpCallout_Utility.httpGetCallout(endpointUrl, new Map<String, String>(), requestMap);
    }
}