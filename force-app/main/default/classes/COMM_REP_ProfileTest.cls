/**
 * @author Daniel Lascas
 * @description COMM_REP_Profile test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    04/03/2024      100            Original version
 * Miguel Freire    11/04/2024      100            Refactored getProfileByNameTest, added getProfileByNameWithoutSecurityEnforcedTest
 **/
@isTest
private class COMM_REP_ProfileTest {
    private final static COMM_REP_Profile PROFILE_REP = new COMM_REP_Profile();

    @isTest
    static void getProfileByNameWithSecurityEnforcedTest() {
        List<Profile> expectedList = [SELECT Id, Name FROM Profile LIMIT 1];

        Test.startTest();
        List<Profile> actualList = PROFILE_REP.getProfilesByName(new Set<String>{ expectedList[0].Name }, true);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'profile does not match expected');
    }

    @isTest
    static void getProfileByNameWithoutSecurityEnforcedTest() {
        List<Profile> expectedList = [SELECT Id, Name FROM Profile LIMIT 1];

        Test.startTest();
        List<Profile> actualList = PROFILE_REP.getProfilesByName(new Set<String>{ expectedList[0].Name }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'profile does not match expected');
    }
}