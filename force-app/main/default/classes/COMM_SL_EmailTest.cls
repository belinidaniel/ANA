/**
 * @author Daniel Lascas
 * @description COMM_SL_Email test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024      100            Original version
 **/
@isTest
private class COMM_SL_EmailTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_EmailTemplate TEMPLATE_REP = (COMM_REP_EmailTemplate) MOCKS.mock(COMM_REP_EmailTemplate.class);

    @isTest
    static void getEmailTemplateListWithEnglishOnlyTest() {
        //Scenario: Existing Email Template in Portuguese language for two templates are requested. Only English Template exists.
        //Expected: English Template is returned for both Templates

        String templateDevName = 'COMM_TestTemplate';
        String templateDevName2 = 'COMM_AlternativeTestTemplate';
        String portugueseCode = 'pt_PT';

        EmailTemplate testTemplate = new EmailTemplate();
        testTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        testTemplate.Name = 'COMM: Test Template (EN)';
        testTemplate.DeveloperName = templateDevName + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        EmailTemplate testTemplate2 = new EmailTemplate();
        testTemplate2.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        testTemplate2.Name = 'COMM: Alternative Test Template (EN)';
        testTemplate2.DeveloperName = templateDevName2 + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>{ testTemplate, testTemplate2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(TEMPLATE_REP.getEmailTemplateByUniqueNames((Set<String>) fflib_Match.anyObject())).thenReturn(emailTemplateList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_Email worker = new COMM_SL_Email();
        worker = new COMM_SL_Email(TEMPLATE_REP);
        List<EmailTemplate> actualTemplateList = worker.getEmailTemplates(
            new List<String>{ templateDevName, templateDevName2 },
            portugueseCode,
            true
        );
        Test.stopTest();

        ((COMM_IREP_EmailTemplate) mocks.verify(TEMPLATE_REP, 1))
            .getEmailTemplateByUniqueNames(
                new Set<String>{
                    templateDevName +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName +
                    '_' +
                    portugueseCode,
                    templateDevName2 +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName2 +
                    '_' +
                    portugueseCode
                }
            );
        Assert.areEqual(emailTemplateList, actualTemplateList, 'expected template list wasn\'t returned');
    }

    @isTest
    static void getEmailTemplateListWhenNoneExistTest() {
        //Scenario: Existing Email Template i English language for two templates are requested. Only one Template exists for one of them.
        //Expected: Error is throwed

        String templateDevName = 'COMM_TestTemplate';
        String templateDevName2 = 'COMM_AlternativeTestTemplate';
        String englishCode = 'en_US';

        EmailTemplate testTemplate = new EmailTemplate();
        testTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        testTemplate.Name = 'COMM: Test Template (EN)';
        testTemplate.DeveloperName = templateDevName + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(TEMPLATE_REP.getEmailTemplateByNames((Set<String>) fflib_Match.anyObject())).thenReturn(new List<EmailTemplate>{ testTemplate });
        MOCKS.stopStubbing();

        String errorMessage;

        Test.startTest();
        try {
            COMM_SL_Email worker = new COMM_SL_Email();
            worker = new COMM_SL_Email(TEMPLATE_REP);
            List<EmailTemplate> actualTemplateList = worker.getEmailTemplates(
                new List<String>{ templateDevName, templateDevName2 },
                englishCode,
                false
            );
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        ((COMM_IREP_EmailTemplate) mocks.verify(TEMPLATE_REP, 1))
            .getEmailTemplateByNames(
                new Set<String>{
                    templateDevName +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName +
                    '_' +
                    englishCode,
                    templateDevName2 +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName2 +
                    '_' +
                    englishCode
                }
            );
        Assert.areNotEqual(System.Label.COMM_EMAIL_TEMPLATE_NOT_FOUND, errorMessage, 'expected error messsage wasn\'t returned');
    }

    @isTest
    static void getEmailTemplatListeWithLanguageTest() {
        //Scenario: Existing Email Template in Portuguese language for two templates are requested. Both English and Portuguese Template exists for both templates.
        //Expected: List of Portuguese Template are returned

        String templateDevName = 'COMM_TestTemplate';
        String templateDevName2 = 'COMM_AlternativeTestTemplate';
        String portugueseCode = 'pt_PT';

        EmailTemplate englishTemplate = new EmailTemplate();
        englishTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        englishTemplate.Name = 'COMM: Test Template (EN)';
        englishTemplate.DeveloperName = templateDevName + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        EmailTemplate portugueseTemplate = new EmailTemplate();
        portugueseTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        portugueseTemplate.Name = 'COMM: Test Template (PT)';
        portugueseTemplate.DeveloperName = templateDevName + '_' + portugueseCode;

        EmailTemplate englishTemplate2 = new EmailTemplate();
        englishTemplate2.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        englishTemplate2.Name = 'COMM: Alternative Test Template (EN)';
        englishTemplate2.DeveloperName = templateDevName2 + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        EmailTemplate portugueseTemplate2 = new EmailTemplate();
        portugueseTemplate2.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        portugueseTemplate2.Name = 'COMM: Alternative Test Template (PT)';
        portugueseTemplate2.DeveloperName = templateDevName2 + '_' + portugueseCode;

        List<EmailTemplate> expectedList = new List<EmailTemplate>{ portugueseTemplate, portugueseTemplate2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(TEMPLATE_REP.getEmailTemplateByUniqueNames((Set<String>) fflib_Match.anyObject()))
            .thenReturn(new List<EmailTemplate>{ englishTemplate, portugueseTemplate, englishTemplate2, portugueseTemplate2 });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_Email worker = new COMM_SL_Email();
        worker = new COMM_SL_Email(TEMPLATE_REP);
        List<EmailTemplate> actualTemplateList = worker.getEmailTemplates(
            new List<String>{ templateDevName, templateDevName2 },
            portugueseCode,
            true
        );
        Test.stopTest();

        ((COMM_IREP_EmailTemplate) mocks.verify(TEMPLATE_REP, 1))
            .getEmailTemplateByUniqueNames(
                new Set<String>{
                    templateDevName +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName +
                    '_' +
                    portugueseCode,
                    templateDevName2 +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName2 +
                    '_' +
                    portugueseCode
                }
            );
        Assert.areEqual(expectedList, actualTemplateList, 'expected template list wasn\'t returned');
    }

    @isTest
    static void getEmailTemplatListeWithLanguageMisssingTest() {
        //Scenario: Existing Email Template in Portuguese language for two templates are requested. English and Portuguese Template exists for one template, the other only has English.
        //Expected: List of Template with the Portuguese for one template and English for the other are returned

        String templateDevName = 'COMM_TestTemplate';
        String templateDevName2 = 'COMM_AlternativeTestTemplate';
        String portugueseCode = 'pt_PT';

        EmailTemplate englishTemplate = new EmailTemplate();
        englishTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        englishTemplate.Name = 'COMM: Test Template (EN)';
        englishTemplate.DeveloperName = templateDevName + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        EmailTemplate portugueseTemplate = new EmailTemplate();
        portugueseTemplate.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        portugueseTemplate.Name = 'COMM: Test Template (PT)';
        portugueseTemplate.DeveloperName = templateDevName + '_' + portugueseCode;

        EmailTemplate englishTemplate2 = new EmailTemplate();
        englishTemplate2.Id = fflib_IDGenerator.generate(EmailTemplate.sobjectType);
        englishTemplate2.Name = 'COMM: Alternative Test Template (EN)';
        englishTemplate2.DeveloperName = templateDevName2 + '_' + COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE;

        List<EmailTemplate> expectedList = new List<EmailTemplate>{ portugueseTemplate, englishTemplate2 };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(TEMPLATE_REP.getEmailTemplateByUniqueNames((Set<String>) fflib_Match.anyObject()))
            .thenReturn(new List<EmailTemplate>{ englishTemplate, portugueseTemplate, englishTemplate2 });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_SL_Email worker = new COMM_SL_Email();
        worker = new COMM_SL_Email(TEMPLATE_REP);
        List<EmailTemplate> actualTemplateList = worker.getEmailTemplates(
            new List<String>{ templateDevName, templateDevName2 },
            portugueseCode,
            true
        );
        Test.stopTest();

        ((COMM_IREP_EmailTemplate) mocks.verify(TEMPLATE_REP, 1))
            .getEmailTemplateByUniqueNames(
                new Set<String>{
                    templateDevName +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName +
                    '_' +
                    portugueseCode,
                    templateDevName2 +
                    '_' +
                    COMM_DO_Email.DEFAULT_EMAIL_LANGUAGE,
                    templateDevName2 +
                    '_' +
                    portugueseCode
                }
            );
        Assert.areEqual(expectedList, actualTemplateList, 'expected template list wasn\'t returned');
    }
}