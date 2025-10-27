/**
 * @author Ruben Rodrigues
 * @description Class to call SAP mulesoft endpoint to generate a fiscal document
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues      12/04/2024       Original version
 * Daniel Reto	        23/07/2024       ECOMM-1827
 **/
public inherited sharing class COMM_SL_GenerateSAPDoc {
    private static final String CONFIGLABEL = 'SAP';
    private static final String DEVCONFIGLABEL = 'SAPDEV';
    private static final String PE_MESSAGE = 'Communication with SAP failed';
    private static final String SUCCESS = 'SUCCESS';
    private static COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();

    /**
     * @description Method to make callout to SAP
     *
     * @param requestBody Body of the Request to be sent to SAP
     * @param isLoadTesting Boolean to confirm for each SAP named credencial the request should be send
     * @return Response received from SAP
     */
    public static COMM_SL_SAPDocumentResponse makeCallout(COMM_SL_SAPDocumentRequest requestBody, Boolean isLoadTesting) {
        if (isLoadTesting) {
            return makeCallout(requestBody, DEVCONFIGLABEL);
        } else {
            return makeCallout(requestBody, CONFIGLABEL);
        }
    }

    /**
     * @description Method to make callout to SAP to generate fiscal document
     * @param requestBody Body of the Request to be sent to SAP
     * @param configString custom metadata to catch correct SAP configuration
     * @return Response received from SAP
     */
    public static COMM_SL_SAPDocumentResponse makeCallout(COMM_SL_SAPDocumentRequest requestBody, String configString) {
        COMM_OMS_CalloutSettings__mdt calloutConfiguration = calloutSettingsRep.getCalloutSetting(configString);
        Map<String, String> headers = COMM_OMS_CalloutUtil.parseHeaders(calloutConfiguration.HTTP_Headers__c);

        HttpResponse response = COMM_OMS_CalloutUtil.doCallout(
            calloutConfiguration.Endpoint_Server__c + calloutConfiguration.Endpoint_URI__c,
            calloutConfiguration.HTTP_Method__c,
            headers,
            JSON.serialize(requestBody, true),
            calloutConfiguration.Timeout__c
        );
        COMM_SL_SAPDocumentResponse responses;
        try {
            responses = COMM_SL_SAPDocumentResponse.parse(response.getBody());
        } catch (Exception e) {
            //Log error and generate a SAP Response. If server response doesn't match expected (ex: response when can't reach server)
            COMM_HttpCallout_Utility.logResponseError(e, JSON.serialize(requestBody), response, 'COMM_SL_GenerateSAPDoc');
            responses = new COMM_SL_SAPDocumentResponse();
            responses.resultCode = response.getStatusCode().toString();
            responses.resultDesc = response.getBody();
        }
        return responses;
    }
}