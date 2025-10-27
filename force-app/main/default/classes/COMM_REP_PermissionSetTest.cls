/**
 * @author Daniel Lascas
 * @description COMM_REP_PermissionSet test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024      100            ECOMM-700: Original version
 **/
@isTest
private class COMM_REP_PermissionSetTest {
    private final static COMM_REP_PermissionSet PERMISSION_REP = new COMM_REP_PermissionSet();

    @isTest
    static void getPermissionSetsByNameTest() {
        List<PermissionSet> expectedList = [SELECT Id, Name FROM PermissionSet LIMIT 1];

        Test.startTest();
        List<PermissionSet> withSecurityList = PERMISSION_REP.getPermissionSetsByName(new Set<String>{ expectedList[0].Name }, true);
        List<PermissionSet> withoutSecurityList = PERMISSION_REP.getPermissionSetsByName(new Set<String>{ expectedList[0].Name }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, withSecurityList[0].Id, 'the permission set found does not match expected');
        Assert.areEqual(expectedList[0].Id, withoutSecurityList[0].Id, 'the permission set found does not match expected');
    }
}