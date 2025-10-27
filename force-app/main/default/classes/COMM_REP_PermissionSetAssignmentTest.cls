/**
 * @author Daniel Lascas
 * @description COMM_REP_PermissionSetAssignmentTest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024      100            ECOMM-700: Original version
 **/
@isTest
private class COMM_REP_PermissionSetAssignmentTest {
    private final static COMM_REP_PermissionSetAssignment PERMISSION_REP = new COMM_REP_PermissionSetAssignment();

    @isTest
    static void getAssignmentsByUserIdAndPermissionNameTest() {
        List<PermissionSetAssignment> expectedList = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment LIMIT 1];

        Test.startTest();
        List<PermissionSetAssignment> actualList = PERMISSION_REP.getAssignmentsByUserIdAndPermissionId(
            new Set<Id>{ expectedList[0].AssigneeId },
            new Set<Id>{ expectedList[0].PermissionSetId }
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'the permission set assignmennt found does not match expected');
    }
}