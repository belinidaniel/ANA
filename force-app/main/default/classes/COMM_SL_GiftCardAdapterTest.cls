/**
 * @author Diogo Gonçalves
 * @description COMM_SL_GiftCardAdapter test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    02/05/2024      75            Original version
 * Diogo Gonçalves    17/09/2024      89            ECOMM-481: Changed the API endpoint
 **/
@isTest
private class COMM_SL_GiftCardAdapterTest {
    private static final String FAKE_RESPONSE_DATA = '{"created":[{"enabled":true,"status":1,"statusText":"Active","recipientName":"John Doe","recipientEmail":"john.doe@example.com","senderName":"Jane Smith","sendEmail":true,"isEmailSent":false,"sentEmailDates":[],"code":"GFT123456789","merchantId":"MCH987654321","amount":100.0,"balance":100.0,"currencyCode":"USD","description":"Gift certificate for John Doe","creationDate":"2024-01-01T10:00:00Z","lastModifiedDate":"2024-01-01T10:00:00Z","orderNo":"ORD0011223344"}]}';

    @TestSetup
    static void setupMethd() {
        AlternativePaymentMethod paymentMethod = (AlternativePaymentMethod) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'AlternativePaymentMethod',
            new Map<String, Object>{ 'Status' => 'Active', 'ProcessingMode' => 'External' }
        )[0];

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PaymentAuthorization',
            new Map<String, Object>{
                'Amount' => 1500,
                'Status' => 'Pending',
                'ProcessingMode' => 'External',
                'GatewayRefNumber' => 'testreferencenumber',
                'GatewayRefDetails' => '{"method":"credit_card","transaction_id":"ET119982"}',
                'PaymentMethodId' => paymentMethod.Id
            }
        );

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Payment',
            new Map<String, Object>{
                'Amount' => 1500,
                'Status' => 'Processed',
                'Type' => 'Sale',
                'ProcessingMode' => 'External',
                'GatewayRefNumber' => 'testreferencenumber',
                'GatewayRefDetails' => '{"method":"credit_card","transaction_id":"ET119982"}',
                'PaymentMethodId' => paymentMethod.Id
            }
        );
    }

    @isTest
    public static void testCaptureRequest() {
        Test.startTest();
        PaymentAuthorization auth = [SELECT Id FROM PaymentAuthorization LIMIT 1];
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest(80, auth.id);
        commercepayments.PaymentGatewayContext context = new commercepayments.PaymentGatewayContext(
            captureRequest,
            commercepayments.RequestType.Capture
        );
        COMM_SL_GiftCardAdapter adapter = new COMM_SL_GiftCardAdapter();
        commercepayments.GatewayResponse captureResponse = adapter.processRequest(context);
        Test.stopTest();

        Assert.isInstanceOfType(captureResponse, commercepayments.CaptureResponse.class, 'Response is not a valid Capture response');
    }

    @isTest
    public static void testRefundRequest() {
        // Set up the mock callout environment
        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock(FAKE_RESPONSE_DATA));
        Test.startTest();
        Payment payment = [SELECT Id FROM Payment LIMIT 1];
        commercepayments.ReferencedRefundRequest refundRequest = new commercepayments.ReferencedRefundRequest(80, payment.id);
        commercepayments.PaymentGatewayContext context = new commercepayments.PaymentGatewayContext(
            refundRequest,
            commercepayments.RequestType.referencedrefund
        );
        COMM_SL_GiftCardAdapter adapter = new COMM_SL_GiftCardAdapter();
        commercepayments.GatewayResponse refundResponse = adapter.processRequest(context);
        Test.stopTest();

        Assert.isInstanceOfType(refundResponse, commercepayments.ReferencedRefundResponse.class, 'Response is not a valid Refund response');
    }
}