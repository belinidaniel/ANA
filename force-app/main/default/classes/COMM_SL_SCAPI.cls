/**
 * @author          Diogo Gonçalves
 * @description     COMM_SL_SCAPI class.
 *                  SCAPI client class. Makes calls to SCAPI.
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  03/09/2024      100            Original version
 */
public inherited sharing class COMM_SL_SCAPI {
    private static COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();
    private static final String CREATE_GIFT_CERTIFICATES = 'SCAPI_Create_Gift_Certificates';

    /**
     * @description Method to create a Gift Card in OCAPI
     * @param wrapper Wrapper with the information to create the Gift Card (Gift Card Object and the Gift Card
     *                Card Item List)
     * @return The response from the callout
     */
    public static COMM_SL_GiftCertificateWrapper createGiftCertificates(COMM_SL_GiftCertificateWrapper giftCertificates) {
        String CREATE_GIFT_CERTIFICATES = 'SCAPI_Create_Gift_Certificates';
        COMM_OMS_CalloutSettings__mdt calloutConfiguration = calloutSettingsRep.getCalloutSetting(CREATE_GIFT_CERTIFICATES);
        Map<String, String> headers = COMM_OMS_CalloutUtil.parseHeaders(calloutConfiguration.HTTP_Headers__c);
        String endpoint = calloutConfiguration.Endpoint_Server__c + calloutConfiguration.Endpoint_URI__c;

        HttpResponse response = COMM_OMS_CalloutUtil.doCallout(
            endpoint,
            calloutConfiguration.HTTP_Method__c,
            headers,
            JSON.serialize(giftCertificates, true),
            calloutConfiguration.Timeout__c
        );
        if (response.getStatusCode() == 200) {
            return (COMM_SL_GiftCertificateWrapper) JSON.deserialize(response.getBody(), COMM_SL_GiftCertificateWrapper.class);
        } else {
            throw new CalloutException(response?.getBody());
        }
    }
}