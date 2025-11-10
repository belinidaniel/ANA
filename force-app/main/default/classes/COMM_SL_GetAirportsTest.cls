/**
 * @author Carlos Fusco
 * @description COMM_SL_GetAirports test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer           Date            Coverage(%)          Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco      25/03/2024           100              Original version
 **/
@isTest
private class COMM_SL_GetAirportsTest {
    @isTest
    static void getValuesFromAirportsMultiPicklistTest() {
        List<List<COMM_SL_FlowChoice>> airportList = new List<List<COMM_SL_FlowChoice>>();
        List<String> pickListValues = new List<String>{ 'LIS;OPO' };

        Test.startTest();
        airportList = COMM_SL_GetAirports.getValuesFromAirportsMultiPicklist(pickListValues);
        Test.stopTest();

        Assert.isFalse(airportList.isEmpty(), 'List of airports should not be empty');
    }
}