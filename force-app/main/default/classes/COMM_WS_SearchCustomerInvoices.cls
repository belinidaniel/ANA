/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      30/05/2025      Original version
 **/

@RestResource(urlMapping='/invoices/customer/*')
global with sharing class COMM_WS_SearchCustomerInvoices {
    private static COMM_WS_ErrorOutput errorResp = new COMM_WS_ErrorOutput();

    /**
     * @description HTTP Method to search for Customer Invoices
     */
    @HttpPost
    global static void searchCustomerInvoices() {
        RestResponse res = RestContext.response;

        try {
            // adjust date fields with empty string
            String requestBody = RestContext.request.requestBody.toString();
            requestBody = requestBody.replaceAll('""', 'null');
            // Parse payload request.
            COMM_WS_SearchInvoicesInput inputRequest = COMM_WS_SearchInvoicesInput.parse(requestBody);
            // List of Customer Invoices.
            COMM_SL_WS_SearchCustomerInvoices searchInvoicesService = new COMM_SL_WS_SearchCustomerInvoices();
            COMM_WS_SearchInvoicesOutput output = searchInvoicesService.checkCustomerInvoiceExistence(inputRequest);

            COMM_OCI_Utils.setResponse(res, 200, JSON.serialize(output));
        } catch (Exception e) {
            errorResp.errorCode = 'ERROR_FOUND';
            errorResp.message = e.getMessage();
            COMM_GEN_Utility.logError(e, errorResp.message, 'COMM_WS_SearchCustomerInvoices');
            COMM_OCI_Utils.setResponse(res, 500, JSON.serialize(errorResp));
        }
    }
}