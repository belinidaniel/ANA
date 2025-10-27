/**
 * @author Daniel Lascas
 * @description COMM_DO_ProfilePermissionSetAssignment test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024      100            ECOMM-700: Original version
 **/
@isTest
private class COMM_DO_ProfilePermissionSetAssignTest {
    @isTest
    static void getMapTest() {
        Test.startTest();
        Map<Id, Set<Id>> resultMap = new COMM_DO_ProfilePermissionSetAssignment().getAssignmentMap();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected map with values');
    }
}