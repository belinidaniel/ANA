/**
 * @author           Daniel Reto
 * @description      COMM_WS_SearchOrdersInput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      24/06/2024      100            Original version
 * Daniel Reto      24/07/2024      100            Original version
 **/
@isTest
public class COMM_WS_SearchOrdersInputTest {
    @isTest
    static void testParse() {
        String json =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": \"2024-06-05\",' +
            '    \"reservationStartDate\": null,' +
            '    \"reservationEndDate\": null,' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        COMM_WS_SearchOrdersInput obj = COMM_WS_SearchOrdersInput.parse(json);
        Assert.isNotNull(obj, 'Objects should not be null.');
    }

    @isTest
    static void checkInputRequestRulesOrderStartDateTest() {
        String json =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": null,' +
            '    \"reservationStartDate\": null,' +
            '    \"reservationEndDate\": null,' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        try {
            COMM_WS_SearchOrdersInput.checkInputRequestRules(COMM_WS_SearchOrdersInput.parse(json));
        } catch (Exception e) {
            Assert.areEqual('When \'orderStartDate\' or \'orderEndDate\' are set, both parameters are required!', e.getMessage(), 'Should have triggered an error!');
        }
    }

    @isTest
    static void checkInputRequestRulesOrderStartDateLowerThatEndDateTest() {
        String json =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": \"2024-06-01\",' +
            '    \"reservationStartDate\": null,' +
            '    \"reservationEndDate\": null,' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        try {
            COMM_WS_SearchOrdersInput.checkInputRequestRules(COMM_WS_SearchOrdersInput.parse(json));
        } catch (Exception e) {
            Assert.areEqual('\'orderStartDate\' must be equal or greater than \'orderEndDate\'!', e.getMessage(), 'Should have triggered an error!');
        }
    }

    @isTest
    static void checkInputRequestRulesReservationStartDateTest() {
        String json =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": \"2024-06-08\",' +
            '    \"reservationStartDate\": \"2024-06-05\",' +
            '    \"reservationEndDate\": null,' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        try {
            COMM_WS_SearchOrdersInput.checkInputRequestRules(COMM_WS_SearchOrdersInput.parse(json));
        } catch (Exception e) {
            Assert.areEqual('When \'reservationStartDate\' or \'reservationEndDate\' are set, both parameters are required!', e.getMessage(), 'Should have triggered an error!');
        }
    }

    @isTest
    static void checkInputRequestRulesReservationStartDateLowerThatEndDateTest() {
        String json =
            '{' +
            '    \"accountId\": \"0019b00000SAvyCAAT\",' +
            '    \"page\": 0,' +
            '    \"pageSize\": 10,' +
            '    \"orderStartDate\": \"2024-06-05\",' +
            '    \"orderEndDate\": \"2024-06-08\",' +
            '    \"reservationStartDate\": \"2024-06-05\",' +
            '    \"reservationEndDate\": \"2024-06-01\",' +
            '    \"orderNumber\": \"STU-100174\",' +
            '    \"licensePlate\": null,' +
            '    \"productTypes\": [\"PARKING\", \"FASTTRACK\", \"LOUNGE\", \"SUBSCRIPTION\"],' +
            '    \"airports\": [\"LIS\", \"OPO\", \"FNC\", \"FAO\", \"PDL\"],' +
            '    \"status\": [3]' +
            '}';
        try {
            COMM_WS_SearchOrdersInput.checkInputRequestRules(COMM_WS_SearchOrdersInput.parse(json));
        } catch (Exception e) {
            Assert.areEqual('\'reservationStartDate\' must be equal or greater than \'reservationEndDate\'!', e.getMessage(), 'Should have triggered an error!');
        }
    }
}