/**
 * @author           Jose Passos
 * @description      COMM_WS_ReservationInput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 **/
@IsTest
public class COMM_WS_ReservationInputTest {
    @isTest
    static void testParse() {
        String json =
            '{' +
            '    \"reservationID\": \"String\",' +
            '    \"expirationSeconds\": 30,' +
            '    \"extend\": true,' +
            '    \"product\": [' +
            '        {' +
            '            \"actionRequestId\": \"string\",' +
            '            \"productId\": \"string\",' +
            '            \"startDate\": \"2024-01-01T03:00:00\",' +
            '            \"endDate\": \"2024-01-01T03:00:00\"' +
            '        },' +
            '        {' +
            '            \"actionRequestId\": \"string\",' +
            '            \"productId\": \"string\",' +
            '            \"startDate\": \"2024-01-01T03:00:00\",' +
            '            \"endDate\": \"2024-01-01T03:00:00\"' +
            '        }' +
            '    ]' +
            '}';
        COMM_WS_ReservationInput obj = COMM_WS_ReservationInput.parse(json);
        Assert.isNotNull(obj, 'Object should not be null.');
    }
}