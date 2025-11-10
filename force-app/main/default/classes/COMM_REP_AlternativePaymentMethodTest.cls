/**
 * @author Diogo Gonçalves
 * @description COMM_REP_AlternativePaymentMethod test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  08/05/2024      100             Original version
 **/
@isTest
private class COMM_REP_AlternativePaymentMethodTest {
    @TestSetup
    static void makeData() {
        AlternativePaymentMethod paymentMethod = (AlternativePaymentMethod) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'AlternativePaymentMethod',
            new Map<String, Object>{ 'Status' => 'Active', 'ProcessingMode' => 'External' }
        )[0];
    }

    @isTest
    static void testGetById() {
        List<AlternativePaymentMethod> paymentMethods = [SELECT Id, GatewayToken FROM AlternativePaymentMethod WITH USER_MODE LIMIT 1];
        Set<Id> paymentMethodIds = new Set<Id>();
        for (AlternativePaymentMethod paymentMethod : paymentMethods) {
            paymentMethodIds.add(paymentMethod.Id);
        }

        // Call the method being tested
        COMM_REP_AlternativePaymentMethod controller = new COMM_REP_AlternativePaymentMethod();
        List<AlternativePaymentMethod> result = controller.getById(paymentMethodIds);

        // Assert the expected results
        Assert.areEqual(paymentMethods, result, 'The returned records should match the test records');
    }
}