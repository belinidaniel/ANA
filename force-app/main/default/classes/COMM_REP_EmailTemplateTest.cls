/**
 * @author Daniel Lascas
 * @description COMM_REP_EmailTemplate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/03/2024      100            Original version
 * Diogo Gonçalves  17/04/2024      100            ECOMM-105: Added method getEmailTemplateLanguageVersionsTest
 **/
@isTest
private class COMM_REP_EmailTemplateTest {
    private final static COMM_REP_EmailTemplate TEMPLATE_REP = new COMM_REP_EmailTemplate();

    @isTest
    static void getEmailTemplateByUniqueNamesTest() {
        //Scenario: One Email Template Exists
        //Expected: Retrieved the existing Email Template by it's Developer Name
        List<EmailTemplate> expectedList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Test.startTest();
        List<EmailTemplate> actualList = TEMPLATE_REP.getEmailTemplateByUniqueNames(new Set<String>{ expectedList[0].DeveloperName });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'retrieved email template does not match expected');
    }

    @isTest
    static void getEmailTemplateByNamesTest() {
        //Scenario: One Email Template Exists
        //Expected: Retrieved the existing Email Template by it's Name
        List<EmailTemplate> expectedList = [SELECT Id, Name FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];

        Test.startTest();
        List<EmailTemplate> actualList = TEMPLATE_REP.getEmailTemplateByNames(new Set<String>{ expectedList[0].Name });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'retrieved email template does not match expected');
    }

    @isTest
    static void getEmailTemplateLanguageVersionsTest() {
        String languageCode = '_en_US';
        List<EmailTemplate> expectedList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE IsActive = TRUE LIMIT 1];
        update new EmailTemplate(Id = expectedList[0].Id, DeveloperName = expectedList[0].DeveloperName + languageCode);

        Test.startTest();
        List<EmailTemplate> actualList = TEMPLATE_REP.getEmailTemplateLanguageVersions(expectedList[0].DeveloperName);
        Test.stopTest();

        Assert.areEqual(
            expectedList[0].DeveloperName + languageCode,
            actualList[0].DeveloperName,
            'retrieved email template does not match expected'
        );
    }
}