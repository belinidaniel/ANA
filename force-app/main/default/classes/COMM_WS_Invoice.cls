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
        try 
        {
        	String requestBody = RestContext.request.requestBody.toString();
            requestBody = requestBody.replaceAll('""', 'null');
            COMM_WS_EditInvoiceInput inputRequest = COMM_WS_EditInvoiceInput.parse(requestBody);
            
            COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
            List<OrderSummary> orderSummaryList = orderSummaryRep.getOrderSummaryByOrderNumber(inputRequest.orderNumber);
            
            COMM_SL_OMS_SAPHandler handler = new COMM_SL_OMS_SAPHandler();
            if (orderSummaryList.size() > 0) {
            	handler.createCreditMemo(orderSummaryList[0], inputRequest);
            }

        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_Invoice');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
        
    }
}