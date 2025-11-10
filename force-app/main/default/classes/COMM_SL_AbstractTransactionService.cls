/**
 * @author           Diogo Gonçalves
 * @description      COMM_SL_CaptureTransactionService test class.
 *                   Abstract class for all transaction service classes,
 *                   contains common methods for all service classes
 *                   Every service class should extend the COMM_SL_AbstractTransactionService
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  20/03/2024      Original version
 */
public abstract class COMM_SL_AbstractTransactionService {
    protected final commercepayments.SalesforceResultCode SUCCESS_SALESFORCE_RESULT_CODE = commercepayments.SalesforceResultCode.SUCCESS;
    protected final commercepayments.SalesforceResultCode DECLINE_SALESFORCE_RESULT_CODE = commercepayments.SalesforceResultCode.DECLINE;
    protected commercepayments.paymentGatewayContext gatewayContext;

    public COMM_SL_AbstractTransactionService(commercepayments.paymentGatewayContext gatewayContext) {
        this.gatewayContext = gatewayContext;
    }

    /**
     * @description Abstract function to build request for a Transaction
     *              Creates a new request and set request body, authorization parameters and other related fields
     */
    public abstract HttpRequest buildRequest();

    /**
     * @description Abstract function to build gateway response for a Transaction
     *              The input is the response from gateway
     *              It creates and returns GatewayResponse from the HttpResponse
     */
    public abstract commercepayments.GatewayResponse buildResponse(HttpResponse response);

    /**
     * @description Function to process transaction requests
     *              Steps involved are:
     *              1. Build HttpRequest with the input Request from gateway context
     *              2. Send request and get the response from gateway
     *              3. Parse the response from gateway and return GatewayResponse
     * @return       Returns the GatewayResponse after processing the transaction request
     */
    public commercepayments.GatewayResponse execute() {
        HttpRequest req;
        try {
            //Building a new request
            req = buildRequest();
        } catch (COMM_SL_PayGateValidationException e) {
            COMM_GEN_Utility.logError(e, 'Error building PayGate request', 'COMM_SL_AbstractTransactionService.execute()');
            return getValidationExceptionError(e);
        }
        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpResponse res = null;
        try {
            //Sending the request
            res = http.send(req);
        } catch (CalloutException ce) {
            COMM_GEN_Utility.logError(ce, 'Error calling PayGate API', 'COMM_SL_AbstractTransactionService.execute()');
            return getCalloutExceptionError(ce);
        }
        try {
            //Parsing the response from gateway
            return buildResponse(res);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error parsing PayGate API response', 'COMM_SL_AbstractTransactionService.execute()');
            return getParseExceptionError(e);
        }
    }

    /**
     * @description Function to get Salesforce Result Code Info
     *
     * @see https://help.salesforce.com/articleView?id=custommetadatatypes_about.htm
     * @see SalesforceResultCodeInfo
     * @see CustomMetadataTypeInfo
     * @see SalesforceResultCode
     *
     * The managed package must create and maintain a Custom Metadata Type with the mappings of Gateway Result Codes and Salesforce Result Codes.
     * This adapter implementation does not use custom metadata and returns hardcoded salesforceResultCodeInfo
     * see getSalesforceResultCodeInfo(AbstractTransactionAdapter.apex) in PayeezyAdapter_CustomMetadata
     *
     */
    protected commercepayments.SalesforceResultCodeInfo getSalesforceResultCodeInfo(String resultCode) {
        if (resultCode == SUCCESS_SALESFORCE_RESULT_CODE.name()) {
            return new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success);
        } else {
            return new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Decline);
        }
    }
    /**
     * @description Function to get error response for Validation Exception
     * @param e - Exception thrown creating request for PayGate API
     * @return commercepayments.GatewayErrorResponse
     */
    private commercepayments.GatewayErrorResponse getValidationExceptionError(Exception e) {
        return new commercepayments.GatewayErrorResponse('400', e.getMessage());
    }

    /**
     * @description Function to get error response for Parse Exception
     * @param e - Exception thrown calling PayGate API
     * @return commercepayments.GatewayErrorResponse
     */
    private commercepayments.GatewayErrorResponse getParseExceptionError(Exception e) {
        return new commercepayments.GatewayErrorResponse('400', 'Something went wrong in the Gateway Adapter : ' + e.getMessage());
    }

    /**
     * @description Function to get error response for Callout Exception
     * @param e - Exception thrown parsing the response from PayGate API
     * @return commercepayments.GatewayErrorResponse
     */
    private commercepayments.GatewayErrorResponse getCalloutExceptionError(CalloutException ce) {
        return new commercepayments.GatewayErrorResponse('500', ce.getMessage());
    }
}