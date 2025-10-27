/**
 * @author Daniel Lascas
 * @description COMM_DO_Email test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/03/2024      100            Original version
 **/
@isTest
private class COMM_DO_EmailTest {
    @isTest
    static void sendEmailSuccessTest() {
        //Email is Generated and Sent
        User userRecord = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];
        List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Test.startTest();
        Integer emailInvocationStart = Limits.getEmailInvocations();
        //NOTE: OrgWideEmailAddress can't be created in a test class so if non exist pass null value
        COMM_DO_Email.sendEmail(userRecord.Id, templateList[0].Id, oweaList.isEmpty() ? null : oweaList[0].Id);
        Boolean emailSent = Limits.getEmailInvocations() != emailInvocationStart;
        Test.stopTest();

        Assert.isTrue(emailSent, 'expected an email invocation to be called');
    }

    @isTest
    static void sendEmailFailureTest() {
        //Email is Generated but fails to send due to non-existing recipient
        Id userId = fflib_IDGenerator.generate(User.SOBjectType);
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_DO_Email.sendEmail(userId, templateList[0].Id, null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }
}