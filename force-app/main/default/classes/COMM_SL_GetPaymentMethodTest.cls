/**
 * @author Carlos Fusco
 * @description COMM_SL_GetPaymentMethod test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer           Date            Coverage(%)          Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco      10/05/2024           100              Original version
 **/
@isTest
private class COMM_SL_GetPaymentMethodTest {
    @isTest
    static void getValuesFromPaymentMethodMultiPicklistTest() {
        List<List<COMM_SL_FlowChoice>> paymentMethodList = new List<List<COMM_SL_FlowChoice>>();
        List<String> pickListValues = new List<String>{ 'Courtesy;Credit' };

        Test.startTest();
        paymentMethodList = COMM_SL_GetPaymentMethod.getValuesFromPaymentMethodMultiPicklist(pickListValues);
        Test.stopTest();

        Assert.isFalse(paymentMethodList.isEmpty(), 'List of payment methods should not be empty');
    }
}