/**
 * @author           Jose Passos
 * @description      COMM_WS_ErrorOutput test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      26/02/2024      100            Original version
 **/
@IsTest
public class COMM_WS_ErrorOutputTest {
    @isTest
    static void testParse() {
        String json =
            '[' +
            '    {' +
            '        "errorCode": "ERROR_FOUND",' +
            '        "message": "Some Error Message"' +
            '    },' +
            '    {' +
            '        "errorCode": "ERROR_FOUND_2",' +
            '        "message": "Some Error Message 2"' +
            '    }' +
            ']';
        List<COMM_WS_ErrorOutput> obj = COMM_WS_ErrorOutput.parse(json);
        List<COMM_WS_ErrorOutput> objExpected = (List<COMM_WS_ErrorOutput>) System.JSON.deserialize(json, List<COMM_WS_ErrorOutput>.class);
        Assert.areEqual(obj.size(), objExpected.size(), 'Objects should have the same size.');
    }
}