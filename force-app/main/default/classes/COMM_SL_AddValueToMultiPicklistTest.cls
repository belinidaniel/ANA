/**
 * @author Daniel Lascas
 * @description COMM_SL_AddValueToMultiPicklist test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/04/2024      100            ECOMM-369: Original version
 **/
@isTest
private class COMM_SL_AddValueToMultiPicklistTest {
    @isTest
    static void addValueToMultiTest() {
        List<COMM_SL_AddValueToMultiPicklist.InputWrapper> wrapperList = new List<COMM_SL_AddValueToMultiPicklist.InputWrapper>{
            new COMM_SL_AddValueToMultiPicklist.InputWrapper()
        };
        wrapperList[0].multiPicklistValue = 'test1;test2';
        wrapperList[0].valueToAdd = 'test3';
        Test.startTest();
        List<String> result = COMM_SL_AddValueToMultiPicklist.addValueToMultiPicklist(wrapperList);
        Test.stopTest();

        Assert.areEqual(wrapperList[0].multiPicklistValue + ';' + wrapperList[0].valueToAdd, result[0], 'resulting string does not match expected');
    }

    @isTest
    static void addValueToMultiNoValueTest() {
        List<COMM_SL_AddValueToMultiPicklist.InputWrapper> wrapperList = new List<COMM_SL_AddValueToMultiPicklist.InputWrapper>{};
        Test.startTest();
        List<String> result = COMM_SL_AddValueToMultiPicklist.addValueToMultiPicklist(wrapperList);
        Test.stopTest();

        Assert.areEqual('', result[0], 'resulting string does not match expected');
    }
}