/**
 * @author Ruben Rodrigues
 * @description COMM_SL_GenerateSAPDoc Test Class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date                Coverage(%)         Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues      12/04/2024          95                  Original version
 * Daniel Reto          23/07/2024          95                  ECOMM-1827
 **/
@isTest
public class COMM_SL_GenerateSAPDocTest {
    private static final String FAKE_RESPONSE_JSON = '{' + '    "documentId":"4187000039",' + '     "resultCode":"",' + '     "resultDesc":""' + '}';

    @isTest
    static void makeCalloutTest() {
        String fakeReq =
            '{' +
            '    "paymentMode":"Prepaid",' +
            '     "id":"02RESERVA000004",' +
            '     "documentSerie":"FT",' +
            '     "documentType":"CreditNote",' +
            '    "documentDate":"2024-01-17",' +
            '    "billingDate":"2024-01-17",' +
            '   "paymentDays": 0,' +
            '  "dueDate": "2024-01-17",' +
            '    "netAmount": 200,' +
            '    "taxAmout": 45,' +
            '    "billingName": "Cliente teste 1",' +
            '    "billingAddicionalName": "",' +
            '    "billingEmail": "Test@teste.com",' +
            '    "billingAddress": "Morada Teste",' +
            '    "billingPostalCode": "1000-000",' +
            '    "billingCity": "Lisboa",' +
            '    "billingVat": "PT501279237",' +
            '    "billingCountry": "PT",' +
            '    "orderItems": [' +
            '        {' +
            '            "location": "510000",' +
            '            "productId": "1",' +
            '            "taxCode": "PP",' +
            '            "quantity": 1,' +
            '            "description": "Produto 1 Cont",' +
            '            "totalNetAmount": 100,' +
            '            "itemReference": "REF 1"' +
            '        },' +
            '        {' +
            '            "location": "510000",' +
            '            "productId": "1",' +
            '            "taxCode": "PS",' +
            '            "quantity": 1,' +
            '            "description": "Produto 2 Mad",' +
            '            "totalNetAmount": 100,' +
            '            "itemReference": "REF 2"' +
            '        }' +
            '    ]' +
            '}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock(FAKE_RESPONSE_JSON));
        COMM_SL_SAPDocumentRequest req = COMM_SL_SAPDocumentRequest.parse(fakeReq);
        COMM_SL_SAPDocumentResponse resp = COMM_SL_GenerateSAPDoc.makeCallout(req, false);
        Test.stopTest();

        Assert.areEqual('4187000039', resp.documentID, 'Expected a 200 HTTP request.');
    }

    @isTest
    static void calloutErrorTest() {
        //Scenario: Callout to server is made but server is offline
        //Expected: Error Log created and response with server error

        //Mock Request Body
        String fakeReq =
            '{' +
            '    "paymentMode":"Prepaid",' +
            '     "id":"02RESERVA000004",' +
            '     "documentSerie":"FT",' +
            '     "documentType":"CreditNote",' +
            '    "documentDate":"2024-01-17",' +
            '    "billingDate":"2024-01-17",' +
            '   "paymentDays": 0,' +
            '  "dueDate": "2024-01-17",' +
            '    "netAmount": 200,' +
            '    "taxAmout": 45,' +
            '    "billingName": "Cliente teste 1",' +
            '    "billingAddicionalName": "",' +
            '    "billingEmail": "Test@teste.com",' +
            '    "billingAddress": "Morada Teste",' +
            '    "billingPostalCode": "1000-000",' +
            '    "billingCity": "Lisboa",' +
            '    "billingVat": "PT501279237",' +
            '    "billingCountry": "PT",' +
            '    "orderItems": [' +
            '        {' +
            '            "location": "510000",' +
            '            "productId": "1",' +
            '            "taxCode": "PP",' +
            '            "quantity": 1,' +
            '            "description": "Produto 1 Cont",' +
            '            "totalNetAmount": 100,' +
            '            "itemReference": "REF 1"' +
            '        },' +
            '        {' +
            '            "location": "510000",' +
            '            "productId": "1",' +
            '            "taxCode": "PS",' +
            '            "quantity": 1,' +
            '            "description": "Produto 2 Mad",' +
            '            "totalNetAmount": 100,' +
            '            "itemReference": "REF 2"' +
            '        }' +
            '    ]' +
            '}';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ServerFailureHttpResponseGenerator());
        COMM_SL_SAPDocumentRequest req = COMM_SL_SAPDocumentRequest.parse(fakeReq);
        COMM_SL_SAPDocumentResponse resp = COMM_SL_GenerateSAPDoc.makeCallout(req, false);
        Test.stopTest();

        Integer errorCount = [SELECT COUNT() FROM Error_Log__c];

        Assert.areEqual('500', resp.resultCode, 'Expected a 500 HTTP response.');
        Assert.areEqual('The requested URL could not be retrieved', resp.resultDesc, 'Expected server error message.');
        Assert.areEqual(1, errorCount, 'expected one error log to have been generated');
    }

    /**
     * @description Implements a mocked server that fails to process (ex: server offline)
     **/
    public class ServerFailureHttpResponseGenerator implements HttpCalloutMock {
        /**
         * @description Returns an expected mocked response from a failed server
         *
         * @param req HTTP Request that server receives from Salesforce
         * @return HTTP Response expected from server
         **/
        public HTTPResponse respond(HTTPRequest req) {
            String reqEndpoint = req.getEndpoint();
            HttpResponse response = new HttpResponse();
            response.setBody('The requested URL could not be retrieved');
            response.setStatusCode(500);
            response.setStatus('Internal Server Error');
            return response;
        }
    }
}