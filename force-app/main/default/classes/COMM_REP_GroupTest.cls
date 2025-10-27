/**
 * @author           Carlos Fusco
 * @description      COMM_REP_Group test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)                 Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco   09/04/2024            85                    Original version
 * Miguel Freire  19/04/2024            92                    Added tests getGroupByNameWithSecurityEnforcedTest and getGroupByNameWithoutSecurityEnforcedTest
 **/
@isTest
private class COMM_REP_GroupTest {
    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void getQueueIdByDeveloperName() {
        String queueDeveloperName = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' LIMIT 1].DeveloperName;

        Test.startTest();
        COMM_REP_Group groupRep = new COMM_REP_Group();
        List<Group> groups = groupRep.getQueueIdByDeveloperName(queueDeveloperName, false);
        Test.stopTest();

        Assert.isFalse(groups.isEmpty(), 'expected to have group retrieved');
    }

    @isTest
    static void getGroupByNameWithSecurityEnforcedTest() {
        COMM_REP_Group groupRep = new COMM_REP_Group();
        List<Group> expectedList = [SELECT Id, Name FROM Group WHERE Name = :COMM_DO_Group.GROUP_NAME_PARTNER_ADMIN];
        Test.startTest();
        List<Group> actualList = groupRep.getGroupsByName(new Set<String>{ expectedList[0].Name }, true);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'group does not match expected');
    }

    @isTest
    static void getGroupByNameWithoutSecurityEnforcedTest() {
        COMM_REP_Group groupRep = new COMM_REP_Group();
        List<Group> expectedList = [SELECT Id, Name FROM Group WHERE Name = :COMM_DO_Group.GROUP_NAME_PARTNER_ADMIN];

        Test.startTest();
        List<Group> actualList = groupRep.getGroupsByName(new Set<String>{ expectedList[0].Name }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'group does not match expected');
    }
}