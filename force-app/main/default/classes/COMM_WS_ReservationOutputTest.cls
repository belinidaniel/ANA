/**
 * @author           Jose Passos
 * @description      COMM_WS_ReservationOutput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 **/
@IsTest
public class COMM_WS_ReservationOutputTest {
    @isTest
    static void testParse() {
        String json =
            '[' +
            '    {' +
            '        \"actionRequestId\": \"string\",' +
            '        \"productId\": \"string\",' +
            '        \"price\": 0.23,' +
            '        \"startDate\": \"2024-01-01T23:00:00.000Z\",' +
            '        \"endDate\": \"2024-01-01T23:00:00.000Z\"' +
            '    },' +
            '    {' +
            '        \"actionRequestId\": \"string\",' +
            '        \"productId\": \"string\",' +
            '        \"price\": 0.01,' +
            '        \"startDate\": \"2024-01-01T23:00:00.000Z\",' +
            '        \"endDate\": \"2024-01-01T23:00:00.000Z\"' +
            '    }' +
            ']';
        List<COMM_WS_ReservationOutput> obj = COMM_WS_ReservationOutput.parse(json);
        List<COMM_WS_ReservationOutput> objExpected = (List<COMM_WS_ReservationOutput>) System.JSON.deserialize(
            json,
            List<COMM_WS_ReservationOutput>.class
        );
        Assert.areEqual(obj.size(), objExpected.size(), 'Objects should have the same size.');
    }
}