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
public with sharing class COMM_WS_VoucherPDFInput {
    public String accountId;
    public String email;
    public String orderNumber;
    public String orderProductSummaryId;

    public List<String> getErrors() {
        List<String> errors = new List<String>();
        if (String.isBlank(accountId) && String.isBlank(email)) {
            errors.add(COMM_WS_VoucherPDF.INVALID_USER);
        }
        if (String.isBlank(orderNumber)) {
            errors.add(COMM_WS_VoucherPDF.BLANK_ORDER_NUMBER);
        }
        return errors;
    }
}