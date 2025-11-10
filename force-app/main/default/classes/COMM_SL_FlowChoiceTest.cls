/**
 * @author Carlos Fusco
 * @description COMM_SL_FlowChoice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer           Date            Coverage(%)          Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco      25/03/2024           100              Original version
 **/
@isTest
private class COMM_SL_FlowChoiceTest {
    @isTest
    static void labelValueConstructorTest() {
        List<String> pickListValues = new List<String>{ 'LIS;OPO' };
        List<COMM_SL_FlowChoice> pickListFlowChoices = new List<COMM_SL_FlowChoice>();
        Map<String, String> picklistLabelByValue = COMM_GEN_Utility.getPicklistMap(Schema.Account.COMM_Airport__c, false);

        Test.startTest();
        for (String value : pickListValues.get(0).split(';')) {
            pickListFlowChoices.add(new COMM_SL_FlowChoice(picklistLabelByValue.get(value), value));
        }
        Test.stopTest();

        Assert.isFalse(pickListFlowChoices.isEmpty(), 'List of choices must be initialized by 2 parameter constructor');
    }

    @isTest
    static void multiArgumentConstructorTest() {
        List<COMM_SL_FlowChoice> flowChoices = new List<COMM_SL_FlowChoice>();

        Test.startTest();
        flowChoices.add(
            new COMM_SL_FlowChoice(
                (String) fflib_IDGenerator.generate(Product2.sObjectType),
                'Parking P1',
                50.0,
                'Montlhy',
                'Continent',
                'LIS_P1_premium_1',
                500
            )
        );
        Test.stopTest();

        Assert.isFalse(flowChoices.isEmpty(), 'List of choices must be initialized by multiple parameter constructor');
    }

    @isTest
    static void multiArgumentConstructor2Test() {
        List<COMM_SL_FlowChoice> flowChoices = new List<COMM_SL_FlowChoice>();

        Test.startTest();
        flowChoices.add(
            new COMM_SL_FlowChoice(
                (String) fflib_IDGenerator.generate(Product2.sObjectType),
                'Parking P1',
                50.0,
                'Montlhy',
                'Montlhy'
            )
        );
        Test.stopTest();

        Assert.isFalse(flowChoices.isEmpty(), 'List of choices must be initialized by multiple parameter constructor');
    }
}