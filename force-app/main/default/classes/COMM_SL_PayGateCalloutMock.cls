/**
 * @author Diogo Gonçalves
 * @description PayGate api callout mock for COMM_SL_PayGateAdapter
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date                Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      20/03/2024        Original version
 **/
public class COMM_SL_PayGateCalloutMock implements HttpCalloutMock {
    private static final String SUCCESS_RESPONSE = 'success';
    private static final String FAIL_RESPONSE = 'fail';
    private static final String ERROR_RESPONSE = 'error';
    private String responseType;

    public COMM_SL_PayGateCalloutMock(String responseType) {
        this.responseType = responseType;
    }

    public HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        List<String> jsonResponse;
        if (this.responseType == ERROR_RESPONSE) {
            jsonResponse = new List<String>{
                '"errors": { "ACCESS_TOKEN": ["The ACCESS_TOKEN field is required."] }',
                '"type": "https://tools.ietf.org/html/rfc9110#section-15.5.1"',
                '"title": "One or more validation errors occurred."',
                '"status": 400',
                '"traceId": "00-60e121f3888e9d96d9718e3065f6a32f-558ee7930b8455a8-00"'
            };
        } else {
            jsonResponse = new List<String>{
                '"InProgress": false',
                '"ShortReturnMessage": "string"',
                '"LongReturnMessage": "string"',
                '"SessionToken": "string"',
                '"TransactionID": "string"',
                '"PaymentID": 0',
                '"WalletID": "string" '
            };
            if (responseType == SUCCESS_RESPONSE) {
                jsonResponse.add('"Success": true');
                jsonResponse.add('"OperationProgressStatus": 0');
                jsonResponse.add('"ReturnCode": "00"');
            } else {
                jsonResponse.add('"Success": false');
                jsonResponse.add('"OperationProgressStatus": -1');
                jsonResponse.add('"ReturnCode": "ERR"');
            }
            res.setStatusCode(200);
        }
        res.setBody('{' + String.join(jsonResponse, ',') + '}');
        return res;
    }
}