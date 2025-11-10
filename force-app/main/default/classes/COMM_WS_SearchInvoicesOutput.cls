/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      26/05/2025      Original version
 **/

global class COMM_WS_SearchInvoicesOutput {
    global class InvoiceSummaryLine {
        global String invoiceLineNumber;
    }

    global class InvoiceSummary {
        global String invoiceNumber;
        global String status;
        global String orderNumber;
        global Date invoiceDate;
        global String currencyCode;
        global Decimal totalAmountWithTax;
        global Date dueDate;
        global String billingAccountEmail;
        global String billingAccountName;
        global String sapDocumentId;
        global List<String> airports;
        global List<String> affiliateNumbers;
        global List<InvoiceSummaryLine> invoiceLines;
    }

    global Integer count;
    global Integer pageSize;
    global Integer page;
    global List<InvoiceSummary> data;

    public static COMM_WS_SearchInvoicesOutput parse(String json) {
        return (COMM_WS_SearchInvoicesOutput) System.JSON.deserialize(json, COMM_WS_SearchInvoicesOutput.class);
    }

    /**
     * @description Build Output request.
     * @param  COMM_WS_SearchInvoicesInput inputRequest - Input request received
     * @param  COMM_WS_SearchInvoicesOutput outputRequest - Output request to be build
     * @param  List<Invoice> invoiceList - List of Invoice Records used to build the Output request
     */
    public static void buildOutputRequest(
        COMM_WS_SearchInvoicesInput inputRequest,
        COMM_WS_SearchInvoicesOutput outputRequest,
        List<Invoice> invoiceList
    ) {
        outputRequest.data = new List<COMM_WS_SearchInvoicesOutput.InvoiceSummary>();
        Integer startIndex =
            ((inputRequest.page != null) ? inputRequest.page : 0) * ((inputRequest.pageSize != null) ? inputRequest.pageSize : invoiceList.size());
        Integer endIndex = Math.min(startIndex + inputRequest.pageSize - 1, invoiceList.size());
        Integer index = 0;
        Set<String> invoiceAirportValues;
        Set<String> affiliateNumbers;

        for (Invoice invoiceRecord : invoiceList) {
            if (index >= startIndex && index <= endIndex) {
                List<COMM_WS_SearchInvoicesOutput.InvoiceSummaryLine> invoiceSummaryLines = new List<COMM_WS_SearchInvoicesOutput.InvoiceSummaryLine>();
                COMM_WS_SearchInvoicesOutput.InvoiceSummary invoiceRecordOnRequest = new COMM_WS_SearchInvoicesOutput.InvoiceSummary();
                OrderSummary orderSummary = (OrderSummary) invoiceRecord.ReferenceEntity;
                OrderItemSummary orderItemSummary;
                invoiceAirportValues = new Set<String>();
                affiliateNumbers = new Set<String>();
                invoiceRecordOnRequest.invoiceNumber = invoiceRecord.DocumentNumber;
                invoiceRecordOnRequest.status = invoiceRecord.Status;
                invoiceRecordOnRequest.orderNumber = orderSummary.OrderNumber;
                invoiceRecordOnRequest.invoiceDate = invoiceRecord.InvoiceDate;
                invoiceRecordOnRequest.currencyCode = 'EUR';
                invoiceRecordOnRequest.totalAmountWithTax = invoiceRecord.TotalAmountWithTax;
                invoiceRecordOnRequest.dueDate = invoiceRecord.DueDate;
                invoiceRecordOnRequest.billingAccountEmail = invoiceRecord.BillingAccount.PersonEmail;
                invoiceRecordOnRequest.billingAccountName = invoiceRecord.BillingAccount.Name;
                invoiceRecordOnRequest.sapDocumentId = invoiceRecord.COMM_SAPDocumentId__c;
                for (InvoiceLine line : invoiceRecord.invoiceLines) {
                    COMM_WS_SearchInvoicesOutput.InvoiceSummaryLine invoiceLine = new COMM_WS_SearchInvoicesOutput.InvoiceSummaryLine();
                    orderItemSummary = (OrderItemSummary) line.ReferenceEntityItem;
                    invoiceLine.invoiceLineNumber = line.Name;
                    invoiceSummaryLines.add(invoiceLine);
                    if (line.Product2 != null && String.isNotBlank(line.Product2.COMM_Airport__c)) {
                        invoiceAirportValues.add(line.Product2.COMM_Airport__c);
                    }
                    if (orderItemSummary != null && String.isNotBlank(orderItemSummary.COMM_AffiliateNumber__c)) {
                        affiliateNumbers.add(orderItemSummary.COMM_AffiliateNumber__c);
                    }
                }
                invoiceRecordOnRequest.invoiceLines = invoiceSummaryLines;
                invoiceRecordOnRequest.airports = new List<String>(invoiceAirportValues);
                invoiceRecordOnRequest.affiliateNumbers = new List<String>(affiliateNumbers);
                outputRequest.data.add(invoiceRecordOnRequest);
            }
            index++;
        }

        outputRequest.count = invoiceList.size();
        outputRequest.pageSize = inputRequest.pageSize;
        outputRequest.page = inputRequest.page;
    }
}