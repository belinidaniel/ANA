/**
 * @author Diogo Gonçalves
 * @description COMM_WS_VoucherPDFOutput Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves  02/07/2024    100           ECOMM-1557: Original version
 **/
@isTest
private class COMM_WS_VoucherPDFOutputTest {
    @isTest
    static void shouldInstantiate() {
        Blob testBlob = Blob.valueOf('Test');
        COMM_WS_VoucherPDFOutput successOutput = new COMM_WS_VoucherPDFOutput(Blob.valueOf('Test'));
        Assert.areEqual(testBlob, successOutput.data, 'data attribute does not have the correct blob');

        String errorCode = 'ERROR_CODE';
        String errorMsg = 'Error message';
        COMM_WS_VoucherPDFOutput errorOutput = new COMM_WS_VoucherPDFOutput(errorCode, errorMsg);
        Assert.areEqual(errorCode, errorOutput.errorCode, 'Unexpected error code');
        Assert.areEqual(errorMsg, errorOutput.errorMsg, 'Unexpected error message');

        Boolean isSuccess = true;
        COMM_WS_VoucherPDFOutput errorOutputNoMsg = new COMM_WS_VoucherPDFOutput(isSuccess);
        Assert.areEqual(isSuccess, errorOutputNoMsg.success, 'Success attribute should be ' + isSuccess);
    }
}