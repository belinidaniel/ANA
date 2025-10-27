/**
 * @author           Daniel Reto
 * @description      COMM_WS_CancelOrdersInput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      03/07/2024      100            Original version
 **/
@isTest
public class COMM_WS_CancelOrdersInputTest {
    @isTest
    static void testParse() {
        String json =
            '{' +
            '    \"accountId\": \"\",' +
            '    \"email\": \"test.test@ana.pt.invalid\",' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"orderSummaryId\": \"\",' +
            '    \"partial\": false,' +
            '    \"orderProductSummaryIds\": [\"123\", \"456\", \"789\"]' +
            '}';
        COMM_WS_CancelOrdersInput obj = COMM_WS_CancelOrdersInput.parse(json);
        Assert.isNotNull(obj, 'Objects should not be null.');
    }
}