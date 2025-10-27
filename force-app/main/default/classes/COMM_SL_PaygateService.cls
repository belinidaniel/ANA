/**
 * @author Diogo Gonçalves
 * @description Service class for PayGate
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  14/08/2024     Original version
 **/
public with sharing class COMM_SL_PaygateService {
    private final String REFUND_ENDPOINT = '/api/DoRefund';
    private String accessToken;
    private String merchantCode;
    public class COMM_SL_PaygateException extends Exception {
    }

    public COMM_SL_PaygateService(String accessToken, String merchantCode) {
        this.accessToken = accessToken;
        this.merchantCode = merchantCode;
    }

    /**
     * @description Method to do refund through PayGate
     * @param {Map<String, Object>} refundRequest - Request object
     * @return {Map<String, Object>} Response object
     */
    public Map<String, Object> doRefund(Map<String, Object> refundRequest) {
        if (String.isBlank(this.accessToken) || String.isBlank(this.merchantCode)) {
            throw new COMM_SL_PaygateException('No access token or merchant code found');
        }
        refundRequest.putAll(new Map<String, String>{ 'ACCESS_TOKEN' => accessToken, 'MERCHANT_CODE' => merchantCode });
        HttpResponse res = COMM_OMS_CalloutUtil.doCallout(
            'callout:COMM_PayGateNamedCredential' + REFUND_ENDPOINT,
            'POST',
            new Map<String, String>{ 'Content-Type' => 'application/json' },
            JSON.serialize(refundRequest),
            30000
        );

        if (res.getStatusCode() == 200 || res.getStatusCode() == 400) {
            return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        } else {
            throw new COMM_SL_PaygateException('Unknown error returned from Paygate');
        }
    }
}