/**
 * @author Diogo Gonçalves
 * @description COMM_SL_PayGateAdapter test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    20/03/2024      75            Original version
 **/
@isTest
private class COMM_SL_PayGateAdapterTest {
    private static String SUCCESS_RESPONSE = 'success';
    private static String FAIL_RESPONSE = 'fail';
    private static String ERROR_RESPONSE = 'error';

    @TestSetup
    static void setupMethd() {
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'PaymentAuthorization',
            new Map<String, Object>{
                'Amount' => 1500,
                'Status' => 'Pending',
                'ProcessingMode' => 'External',
                'GatewayRefNumber' => 'testreferencenumber',
                'GatewayRefDetails' => '{"method":"credit_card","transaction_id":"ET119982"}'
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
                'GatewayRefDetails' => '{"method":"credit_card","transaction_id":"ET119982"}'
            }
        );
    }

    @isTest
    public static void testCaptureRequestSuccess() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(SUCCESS_RESPONSE));
        commercepayments.GatewayResponse captureResponse = processCaptureRequest();
        Test.stopTest();

        Assert.isInstanceOfType(captureResponse, commercepayments.CaptureResponse.class, 'Response is not a valid Capture response');
    }

    @isTest
    public static void testCaptureRequestFail() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(FAIL_RESPONSE));
        commercepayments.GatewayResponse captureResponse = processCaptureRequest();
        Test.stopTest();

        Assert.isInstanceOfType(captureResponse, commercepayments.CaptureResponse.class, 'Response is not a valid Capture response');
    }

    @isTest
    public static void testCaptureRequestError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(ERROR_RESPONSE));
        commercepayments.GatewayResponse captureResponse = processCaptureRequest();
        Test.stopTest();

        Assert.isInstanceOfType(captureResponse, commercepayments.GatewayErrorResponse.class, 'Response didn\'t return error');
    }

    @isTest
    public static void testRefundRequestSuccess() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(SUCCESS_RESPONSE));
        commercepayments.GatewayResponse refundResponse = processRefundRequest();
        Test.stopTest();

        Assert.isInstanceOfType(refundResponse, commercepayments.ReferencedRefundResponse.class, 'Response is not a valid Refund response');
    }

    @isTest
    public static void testRefundRequestFail() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(FAIL_RESPONSE));
        commercepayments.GatewayResponse refundResponse = processRefundRequest();
        Test.stopTest();

        Assert.isInstanceOfType(refundResponse, commercepayments.ReferencedRefundResponse.class, 'Response is not a valid Refund response');
    }

    @isTest
    public static void testRefundRequestError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new COMM_SL_PayGateCalloutMock(ERROR_RESPONSE));
        commercepayments.GatewayResponse refundResponse = processRefundRequest();
        Test.stopTest();

        Assert.isInstanceOfType(refundResponse, commercepayments.GatewayErrorResponse.class, 'Response is not a valid Refund response');
    }

    private static commercepayments.GatewayResponse processCaptureRequest() {
        PaymentAuthorization auth = [SELECT Id FROM PaymentAuthorization LIMIT 1];
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest(80, auth.id);
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(captureRequest, commercepayments.RequestType.capture);
        COMM_SL_PayGateAdapter adapter = new COMM_SL_PayGateAdapter();
        return adapter.processRequest(p);
    }

    private static commercepayments.GatewayResponse processRefundRequest() {
        Payment payment = [SELECT Id FROM Payment LIMIT 1];
        commercepayments.ReferencedRefundRequest refundRequest = new commercepayments.ReferencedRefundRequest(80, payment.id);
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(
            refundRequest,
            commercepayments.RequestType.referencedrefund
        );
        COMM_SL_PayGateAdapter adapter = new COMM_SL_PayGateAdapter();
        return adapter.processRequest(p);
    }
}