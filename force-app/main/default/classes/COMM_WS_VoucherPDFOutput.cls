/**
 * @author Diogo Gonçalves
 * @description Voucher PDF webservice output model
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      01/07/2024       Original version
 **/
public with sharing class COMM_WS_VoucherPDFOutput {
    public String errorMsg;
    public String errorCode;
    public Boolean success;
    public Blob data;

    public COMM_WS_VoucherPDFOutput(Boolean success) {
        this.success = success;
    }

    public COMM_WS_VoucherPDFOutput(String errorCode, String errorMsg) {
        this.success = false;
        this.errorCode = errorCode;
        this.errorMsg = errorMsg;
    }

    public COMM_WS_VoucherPDFOutput(Blob data) {
        this.data = data;
        this.success = true;
    }
}