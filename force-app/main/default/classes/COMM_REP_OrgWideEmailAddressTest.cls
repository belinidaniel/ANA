/**
 * @author Daniel Lascas
 * @description COMM_REP_OrgWideEmailAddress test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/03/2024      100            Original version
 **/
@isTest
private class COMM_REP_OrgWideEmailAddressTest {
    private final static COMM_REP_OrgWideEmailAddress ORGWIDE_REP = new COMM_REP_OrgWideEmailAddress();

    @isTest
    static void getDefaultNoReplyAddressTest() {
        //Expected: Retrieved the No-Reply Org Wide Addresses Available
        //NOTE: OrgWideEmailAddress can't be created in a test class
        List<OrgWideEmailAddress> expectedList = [SELECT Id FROM OrgWideEmailAddress WHERE Purpose = 'DefaultNoreply'];

        Test.startTest();
        List<OrgWideEmailAddress> actualList = ORGWIDE_REP.getDefaultNoReplyAddress();
        Test.stopTest();

        Assert.areEqual(expectedList.size(), actualList.size(), 'number of retrieved Org Wide Addresses does not match expected');
    }
}