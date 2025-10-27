/**
 * @author Daniel Lascas
 * @description COMM_LCC_EmailChange test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/06/2024      100            Original version
 **/
@isTest
private class COMM_LCC_EmailChangeTest {
    @isTest
    static void validateChangeEmailTest() {
        //This test is for code coverage. Test for Validate Change Email is present on the test class for COMM_SL_ChangeEmail.
        Boolean errorOccured = false;
        Test.startTest();
        try {
            COMM_LCC_EmailChange.validateEmailChange('invalidToken');
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected validation to fail');
    }
}