/**
 * @author Diogo Gonçalves
 * @description Voucher PDF webservice input model
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      01/07/2024       Original version
 **/
public with sharing class COMM_SL_WS_VoucherPDF {
    /**
     * @description Get the Voucher PDF base64 file
     * @param {COMM_WS_VoucherPDFInput} input - Input object
     * @return {COMM_WS_VoucherPDFOutput} Output object
     */
    public static COMM_WS_VoucherPDFOutput getVoucherPDF(COMM_WS_VoucherPDFInput input) {
        List<String> inputErrors = input.getErrors();
        if (!inputErrors.isEmpty()) {
            throw new COMM_WS_VoucherPDF.COMM_SL_WS_VoucherPDFException(inputErrors[0]);
        }
        OrderSummary orderSummary = getOrderSummary(input);
        Blob pdfBlob = getVoucherPDFBlob(orderSummary, input.orderProductSummaryId);
        return new COMM_WS_VoucherPDFOutput(pdfBlob);
    }

    /**
     * @description Get the Order Summary object
     * @param {COMM_WS_VoucherPDFInput} input - Input object
     * @return {OrderSummary} Order Summary object
     */
    private static OrderSummary getOrderSummary(COMM_WS_VoucherPDFInput input) {
        COMM_IREP_OrderSummary orderSummaryRepo = new COMM_REP_OrderSummary();
        List<OrderSummary> orderSummaries = orderSummaryRepo.getForVoucherPDFService(new List<String>{ input.orderNumber });
        if (orderSummaries.isEmpty()) {
            throw new COMM_WS_VoucherPDF.COMM_SL_WS_VoucherPDFException(COMM_WS_VoucherPDF.ORDER_NOT_FOUND);
        } else if (!isSameAccountOfOrder(orderSummaries[0], input)) {
            throw new COMM_WS_VoucherPDF.COMM_SL_WS_VoucherPDFException(COMM_WS_VoucherPDF.ACCOUNT_MISMATCH);
        }
        return orderSummaries[0];
    }

    /**
     * @description Function that returns a Boolean indicating if either
     *              the email or account Id is correct for the given order number
     * @param {OrderSummary} orderSummary - Order Summary Object
     * @param {COMM_WS_VoucherPDFInput} input - input object
     * @return {Boolean} Boolean value
     */
    private static Boolean isSameAccountOfOrder(OrderSummary orderSummary, COMM_WS_VoucherPDFInput input) {
        List<OrderDeliveryGroupSummary> orderDeliveryGroups = orderSummary.OrderDeliveryGroupSummaries;
        return (String.isNotBlank(input.accountId) && orderSummary.AccountId == input.accountId) ||
            (String.isNotBlank(input.email) &&
            !orderDeliveryGroups.isEmpty() &&
            orderDeliveryGroups[0].EmailAddress == input.email);
    }

    /**
     * @desciption Get the blob of the voucher PDF
     * @param {OrderSummary} orderSummary - Order Summary Object object
     * @return {Blob} Voucher PDF blob
     */
    private static Blob getVoucherPDFBlob(OrderSummary orderSummary, String orderItemSummaryId) {
        PageReference pdf = Page.COMM_VFP_VoucherPDF;
        pdf.getParameters().put('id', orderSummary.Id);
        if (orderItemSummaryId != null) {
            pdf.getParameters().put('orderItemSummaryId', orderItemSummaryId);
        }
        pdf.getParameters().put('lang', orderSummary.COMM_Language__c);
        if (Test.isRunningTest()) {
            return Blob.valueOf('Test');
        }
        return pdf.getContent();
    }
}