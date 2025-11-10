/**
 * @author Diogo Gonçalves
 * @description COMM_SL_CreditPaymentAdapterTest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    27/03/2024      75            Original version
 **/
@isTest
public class COMM_SL_CreditPaymentAdapterTest {
    @isTest
    public static void testCaptureRequest() {
        PaymentAuthorization auth = initializeAuthObject();
        insert auth;
        //Dmls and http request can't be performed in a single transaction in apex
        //segreagating the transaction by starting a test context
        Test.startTest();
        //Create an capture request
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest(80, auth.id);

        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(captureRequest, commercepayments.RequestType.capture);
        COMM_SL_CreditPaymentAdapter adapter = new COMM_SL_CreditPaymentAdapter();

        commercepayments.GatewayResponse captureResponse = adapter.processRequest(p);
        system.assert(captureResponse instanceof commercepayments.CaptureResponse, 'Response is not a valid Capture response');
        Test.stopTest();
    }

    @isTest
    public static void testReferencedRefundRequest() {
        Payment pmt = initializePaymentObject();
        insert pmt;
        //Dmls and http request can't be performed in a single transaction in apex
        //segreagating the transaction by starting a test context
        Test.startTest();
        //Create an capture request
        commercepayments.ReferencedRefundRequest refundRequest = new commercepayments.ReferencedRefundRequest(80, pmt.id);

        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(
            refundRequest,
            commercepayments.RequestType.referencedrefund
        );
        COMM_SL_CreditPaymentAdapter adapter = new COMM_SL_CreditPaymentAdapter();

        commercepayments.GatewayResponse refundResponse = adapter.processRequest(p);
        system.assert(refundResponse instanceof commercepayments.ReferencedRefundResponse, 'Response is not a valid Refund response');
        Test.stopTest();
    }

    @isTest
    public static void testCaptureFailureRequest() {
        PaymentAuthorization auth = initializeAuthObject();
        insert auth;
        //Dmls and http request can't be performed in a single transaction in apex
        //segreagating the transaction by starting a test context
        Test.startTest();
        //Create an capture request
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest(80, auth.id);

        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(captureRequest, commercepayments.RequestType.Capture);
        COMM_SL_CreditPaymentAdapter adapter = new COMM_SL_CreditPaymentAdapter();

        commercepayments.GatewayResponse captureResponse = adapter.processRequest(p);
        system.assert(captureResponse instanceof commercepayments.CaptureResponse, 'Response is not a valid Capture response');
        Test.stopTest();
    }

    @isTest
    public static void testReferencedRefundFailureRequest() {
        Payment pmt = initializePaymentObject();
        insert pmt;
        //Dmls and http request can't be performed in a single transaction in apex
        //segreagating the transaction by starting a test context
        Test.startTest();
        //Create an capture request
        commercepayments.ReferencedRefundRequest refundRequest = new commercepayments.ReferencedRefundRequest(80, pmt.id);

        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(
            refundRequest,
            commercepayments.RequestType.referencedrefund
        );
        COMM_SL_CreditPaymentAdapter adapter = new COMM_SL_CreditPaymentAdapter();

        commercepayments.GatewayResponse refundResponse = adapter.processRequest(p);
        system.assert(refundResponse instanceof commercepayments.ReferencedRefundResponse, 'Response is not a valid Refund response');
        Test.stopTest();
    }

    private static PaymentAuthorization initializeAuthObject() {
        PaymentAuthorization auth = new PaymentAuthorization();
        auth.amount = 1500;
        auth.Status = 'Processed';
        auth.ProcessingMode = 'External';
        auth.GatewayRefNumber = 'testreferencenumber';
        auth.GatewayRefDetails = '{"method":"credit_card","transaction_id":"ET119982"}';
        return auth;
    }

    private static Payment initializePaymentObject() {
        Payment pmt = new Payment();
        pmt.amount = 1500;
        pmt.Status = 'Processed';
        pmt.ProcessingMode = 'External';
        pmt.GatewayRefNumber = 'testreferencenumber';
        pmt.Type = 'Capture';
        pmt.GatewayRefDetails = '{"method":"credit_card","transaction_id":"ET119982"}';
        return pmt;
    }
}