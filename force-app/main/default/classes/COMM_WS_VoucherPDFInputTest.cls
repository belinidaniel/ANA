/**
 * @author Diogo Gonçalves
 * @description COMM_WS_VoucherPDFInput Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves  02/07/2024    100           ECOMM-1557: Original version
 * */
@isTest
private class COMM_WS_VoucherPDFInputTest {
    @isTest
    static void testGetErrors() {
        COMM_WS_VoucherPDFInput testInput = new COMM_WS_VoucherPDFInput();
        testInput.accountId = '';
        testInput.orderNumber = '';

        List<String> errors = testInput.getErrors();

        Assert.areNotEqual(null, errors, 'Errors should not be null');
        Assert.areEqual(2, errors.size(), 'There should be 2 errors');
        Assert.areEqual(COMM_WS_VoucherPDF.INVALID_USER, errors[0], 'Incorrect error message');
        Assert.areEqual(COMM_WS_VoucherPDF.BLANK_ORDER_NUMBER, errors[1], 'Incorrect error message');
    }
}