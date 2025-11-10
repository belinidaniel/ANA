/**
 * @author           Jose Passos
 * @description      COMM_WS_AvailabilityInput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 * Jose Passos      29/04/2024      100            Changed to support SFCC before you go Page requirements
 **/
@isTest
public class COMM_WS_AvailabilityInputTest {
    @isTest
    static void testParse() {
        String json =
            '{' +
            '    \"products\": [' +
            '        {' +
            '            \"productId\": \"string\",' +
            '            \"startDate\": \"2024-01-01T03:00:00\",' +
            '            \"endDate\": \"2024-01-01T03:00:00\",' +
            '            \"available\": 0' +
            '        }' +
            '    ]' +
            '}';
        COMM_WS_AvailabilityInput obj = COMM_WS_AvailabilityInput.parse(json);
        Assert.isNotNull(obj, 'Objects should not be null.');
    }
}