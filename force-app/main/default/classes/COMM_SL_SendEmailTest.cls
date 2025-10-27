/**
 * @author           Daniel Lascas
 * @description      COMM_SL_SendEmail test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    05/02/2024      100            Original version
 * Daniel Reto      20/05/2024      98             ECOMM-1163 - Update email link redirects
 **/
@isTest
private class COMM_SL_SendEmailTest {
    @TestSetup
    static void makeData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create Custom Setting record
            COMM_EmailTemplatesEncryptionSettings__c customSettingEmailTemplatesEncrypt = new COMM_EmailTemplatesEncryptionSettings__c();
            customSettingEmailTemplatesEncrypt.Name = 'Test Setting';
            customSettingEmailTemplatesEncrypt.COMM_SubscriptionKey__c = 'asdfghjklpoiuytr';
            insert customSettingEmailTemplatesEncrypt;

            // Insert Email Template
            COMM_TestDataFactory.insertRecords(
                1,
                true,
                'EmailTemplate',
                new Map<String, Object>{
                    'Name' => 'COMM_EndUser_SubscriptionChangeSubscriptionInfo_Test',
                    'DeveloperName' => 'COMM_EndUser_SubscriptionChangeSubscriptionInfo_Test',
                    'FolderId' => UserInfo.getUserId(),
                    'TemplateType' => 'custom',
                    'HtmlValue' => '<html style="overflow-y: auto;"><head><meta><meta name="viewport" content="width=device-width, initial-scale=1.0"></head><body style="margin: 0 auto; max-width: 800px"><table border="0" cellspacing="0" cellpadding="0" align="center" style="margin-bottom: 30px"><tr><td bgcolor="#004489" height="60" style="background: linear-gradient(90deg, #004489 0%, #7aa1c8 100%); border-radius: 100px; text-align: center; padding-left: 25px; padding-right: 25px;"><a href="###CurrentOrganizationURL###subscription-form?###TokenToEncrypt###=###CaseRecordId###" style="color: white; font-weight: 400; font-size: 20px; line-height: 24px; text-decoration: none; display: inline-block; width: 100%; text-align: center;"type="button">Complete information<img alt="Illustration" src="https://anaaeroportos--uat.sandbox.file.force.com/servlet/servlet.ImageServer?id=0155t000001hWPw&amp;oid=00D5t0000008hvU" style="vertical-align: middle; margin-left: 10px;"/> </a></td></tr></table></body></html>'
                }
            );
            // Insert Case
            COMM_TestDataFactory.insertRecords(
                1,
                true,
                'Case',
                new Map<String, Object>{
                    'COMM_FirstName__c' => 'FirstCase',
                    'SuppliedEmail' => 'test@test.com.invalid',
                    'Description' => 'blablabla'
                }
            );
            // Insert User
            COMM_TestDataFactory.insertRecords(
                1,
                true,
                'User',
                new Map<String, Object>{
                    'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]
                    .Id,
                    'Username' => 'testuser001@example.com' + UserInfo.getOrganizationId(),
                    'LastName' => 'Test',
                    'Email' => 'testuser@example.com',
                    'Alias' => 'tuser',
                    'TimeZoneSidKey' => 'America/New_York',
                    'LocaleSidKey' => 'en_US',
                    'EmailEncodingKey' => 'UTF-8',
                    'LanguageLocaleKey' => 'en_US'
                }
            );
        }
    }
    @isTest
    static void sendEmailToAddressTest() {
        //Scenario: Email is to be sent to an Email Address that doesn't have a Contact Record in Salesforce
        //Expected: Email is sent without error
        // Insert Email Template
        EmailTemplate templateToUse = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'COMM_EndUser_SubscriptionChangeSubscriptionInfo_Test'];

        // Insert Case
        List<Case> caseList = [
            SELECT Id
            FROM Case
            WHERE COMM_FirstName__c = 'FirstCase'
            LIMIT 1
        ];

        // Insert OrgWideEmailAddress
        OrgWideEmailAddress orgWideRecord = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        COMM_SL_SendEmail.InputWrapper testInput = new COMM_SL_SendEmail.InputWrapper();
        testInput.templateId = templateToUse.Id;
        testInput.recipientEmail = new List<String>{ 'test@test.com.invalid' };
        testInput.whatId = caseList[0].Id;
        testInput.orgWideId = orgWideRecord.Id;

        Boolean errorOccurred = false;
        try {
            COMM_SL_SendEmail.sendEmailWithoutRecipientId(new List<COMM_SL_SendEmail.InputWrapper>{ testInput });
        } catch (Exception e) {
            errorOccurred = true;
        }

        System.assert(!errorOccurred, 'expected no error to occur');
    }

    @isTest
    static void sendEmailToUserTest() {
        //Scenario: Email is to be sent to a External identity User
        //Expected: Email is sent without error
        // Insert Email Template
        EmailTemplate templateToUse = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'COMM_EndUser_SubscriptionChangeSubscriptionInfo_Test'];

        // Insert Case
        List<Case> caseList = [
            SELECT Id
            FROM Case
            WHERE COMM_FirstName__c = 'FirstCase'
            LIMIT 1
        ];

        // Insert OrgWideEmailAddress
        OrgWideEmailAddress orgWideRecord = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        // Insert User
        List<User> userList = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator')
            LIMIT 1
        ];

        COMM_SL_SendEmail.InputWrapper testInput = new COMM_SL_SendEmail.InputWrapper();
        testInput.templateId = templateToUse.Id;
        testInput.targetId = userList[0].Id;
        testInput.whatId = caseList[0].Id;
        testInput.orgWideId = orgWideRecord.Id;

        Boolean errorOccurred = false;
        try {
            COMM_SL_SendEmail.sendEmailWithoutRecipientId(new List<COMM_SL_SendEmail.InputWrapper>{ testInput });
        } catch (Exception e) {
            errorOccurred = true;
        }

        System.assert(!errorOccurred, 'expected no error to occur');
    }
}