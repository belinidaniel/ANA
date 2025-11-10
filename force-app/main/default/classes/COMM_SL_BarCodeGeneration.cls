/**
 * @author  Diogo Gonçalves
 * @description Service Layer class used to generate the Barcode/QR Code image.
 *              NOTE: Authentication is handled by the external credential COMM_BarcodeGeneration
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * ------------------------------------------------------------------------------------
 * Diogo Gonçalves          11/04/2024      ECOMM-105: Original version
 */
public inherited sharing class COMM_SL_BarCodeGeneration {
    public static final String CONFIGLABEL = 'Barcode_Generation';
    private static COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();

    /**
     * @description Method to generate the Barcode/QR Code image in base64 format.
     *              Performs callout.
     * @param {String} codeText - text for the code to be generated
     * @param {String} format - Can be QR_CODE or EAN128
     * @returns {COMM_SL_BarcodeResponse}
     */
    public static COMM_SL_BarcodeResponse getBarCodeBase64(String codeText, String format) {
        COMM_OMS_CalloutSettings__mdt calloutConfiguration = calloutSettingsRep.getCalloutSetting(CONFIGLABEL);
        Map<String, String> headers = COMM_OMS_CalloutUtil.parseHeaders(calloutConfiguration.HTTP_Headers__c);
        String queryParameters = COMM_HttpCallout_Utility.getUrlQueryParameters(
            new Map<String, String>{ 'codeText' => codeText, 'format' => format }
        );
        String endpoint = calloutConfiguration.Endpoint_Server__c + calloutConfiguration.Endpoint_URI__c + queryParameters;

        HttpResponse response = COMM_OMS_CalloutUtil.doCallout(
            endpoint,
            calloutConfiguration.HTTP_Method__c,
            headers,
            null,
            calloutConfiguration.Timeout__c
        );
        if (response != null) {
            return (COMM_SL_BarcodeResponse) JSON.deserialize(response.getBody(), COMM_SL_BarcodeResponse.class);
        } else {
            return null;
        }
    }
}