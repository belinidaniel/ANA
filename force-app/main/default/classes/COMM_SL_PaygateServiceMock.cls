/**
 * @author           Diogo Gonçalves
 * @description      Callout mock for Paygate service
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    19/08/2024     ECOMM-1758: Original version
 **/
@isTest
public class COMM_SL_PaygateServiceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if (req.getEndpoint().contains('DoRefund')) {
            res.setBody(
                '{' +
                    '"OperationProgressStatus": 0,' +
                    '"Success": true,' +
                    '"InProgress": true,' +
                    '"ReturnCode": "sample_code",' +
                    '"ShortReturnMessage": "sample_short_message",' +
                    '"LongReturnMessage": "sample_long_message",' +
                    '"SessionToken": "sample_token",' +
                    '"TransactionID": "sample_transaction_id",' +
                    '"PaymentID": 0,' +
                    '"WalletID": "sample_wallet_id"' +
                    '}'
            );
        }
        res.setStatusCode(200);
        return res;
    }
}