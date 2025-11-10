/**
 * @author Tiago Santos
 * @description Web Service to Invoice.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Tiago Santos      25/07/2025       Original version
 **/
@RestResource(urlMapping='/invoice/*')
global without sharing class COMM_WS_Invoice {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();
    @HttpPut
    global static void updateInvocie() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        Integer statusCode = 200;
        try 
        {
        	String requestBody = RestContext.request.requestBody.toString();
            requestBody = requestBody.replaceAll('""', 'null');
            COMM_SL_OMS_SAPHandler.createCreditMemoFuture(requestBody);
            
            res.statusCode = statusCode;
            res.responseBody = Blob.valueOf(JSON.serialize(new COMM_WS_EditInvoiceOutput()));

        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_Invoice');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp.message));
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(errorResp));
        }
        
    }
}