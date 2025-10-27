/**
 * @author Diogo Gonçalves
 * @description Web Service get the Voucher PDF base64 file
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  27/06/2024       Original version
 **/
@RestResource(urlMapping='/orders/voucher')
global with sharing class COMM_WS_VoucherPDF {
    public class COMM_SL_WS_VoucherPDFException extends Exception {
    }

    public static final String ERROR_FOUND = 'ANA-PDF-00001';
    public static final String INVALID_USER = 'ANA-PDF-00002';
    public static final String ORDER_NOT_FOUND = 'ANA-PDF-00003';
    public static final String BLANK_ORDER_NUMBER = 'ANA-PDF-00004';
    public static final String ACCOUNT_MISMATCH = 'ANA-PDF-00005';

    public static final Map<String, String> ERROR_MESSAGES = new Map<String, String>{
        ERROR_FOUND => 'An unknown error occurred',
        INVALID_USER => 'Either accountId or email must be filled',
        ORDER_NOT_FOUND => 'No order found with the given Order Number',
        BLANK_ORDER_NUMBER => 'orderNumber is mandatory',
        ACCOUNT_MISMATCH => 'accountId or email provided is not the owner of the order number'
    };

    /**
     * @description Method to get the Voucher PDF base64 file
     */
    @HttpPost
    global static void getVoucherPDF() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        COMM_WS_VoucherPDFOutput output;
        COMM_WS_VoucherPDFInput input = (COMM_WS_VoucherPDFInput) JSON.deserialize(req.requestBody.toString(), COMM_WS_VoucherPDFInput.class);
        Integer statusCode = 200;
        try {
            output = COMM_SL_WS_VoucherPDF.getVoucherPDF(input);
        } catch (COMM_SL_WS_VoucherPDFException e) {
            statusCode = 400;
            String errorMsg = ERROR_MESSAGES.get(e.getMessage());
            output = new COMM_WS_VoucherPDFOutput(e.getMessage(), errorMsg);
            COMM_GEN_Utility.logError(e, output.errorMsg, 'COMM_WS_VoucherPDF');
        } catch (Exception e) {
            statusCode = 500;
            String errorMsg = ERROR_MESSAGES.get(ERROR_FOUND);
            output = new COMM_WS_VoucherPDFOutput(ERROR_FOUND, errorMsg);
            COMM_GEN_Utility.logError(e, e.getMessage(), 'COMM_WS_VoucherPDF');
        }

        res.addHeader('Content-Type', 'application/json');
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(output));
    }
}