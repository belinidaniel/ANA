/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      28/05/2025      Original version
 **/

public inherited sharing class COMM_SL_WS_SearchCustomerInvoices {
    private static final String INVALID_ACCOUNTID_PARAMETER_ERROR = '\'accountId\' is a required parameter!';

    /**
     * @description Check if any Invoice record exists for the request filters.
     * @param COMM_WS_SearchInvoicesInput inputRequest - Set of Filters to apply on the Invoice search
     * @return COMM_WS_SearchInvoicesOutput output with list of Invoices with the respective requested data
     */
    public COMM_WS_SearchInvoicesOutput checkCustomerInvoiceExistence(COMM_WS_SearchInvoicesInput inputRequest) {
        COMM_WS_SearchInvoicesOutput outputRequest = new COMM_WS_SearchInvoicesOutput();

        //check input request field values
        if (inputRequest.accountId == null) {
            throw new COMM_SL_WS_SearchCustomerInvoicesException(INVALID_ACCOUNTID_PARAMETER_ERROR);
        }
        COMM_WS_SearchInvoicesInput.checkInputRequestRules(inputRequest);

        String invoiceExtraFilter = 'BillingAccountId = \'' + inputRequest.accountId + '\'';

        // generate query with oupput required fields
        COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();
        List<Invoice> invoiceList = invoiceRep.getForSearchInvoice(inputRequest, invoiceExtraFilter);

        COMM_WS_SearchInvoicesOutput.buildOutputRequest(inputRequest, outputRequest, invoiceList);

        return outputRequest;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_SearchCustomerInvoicesException extends Exception {
    }
}