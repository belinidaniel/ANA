/**
 * @author Daniel Lascas
 * @description COMM_LCC_LanguageSelector test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/06/2024      100            ECOMM-1256: Original version
 **/
@isTest
private class COMM_LCC_LanguageSelectorTest {
    @TestSetup
    static void makeData() {
        //Create Customer User
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);

        Account personAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Customer',
                'PersonEmail' => 'test.customer@ana.pt.invalid',
                'RecordTypeId' => recTypeInfo.recordtypeid
            }
        )[0];
        Id contactId = [SELECT PersonContactId FROM Account WHERE Id = :personAccount.Id].PersonContactId;

        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_IDENTITY_USER];

        Long suffix = DateTime.now().getTime();
        String nickname = 'testcustomer' + suffix;

        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => nickname + '@ana.pt.invalid',
                'Email' => personAccount.PersonEmail,
                'LastName' => personAccount.LastName,
                'FirstName' => personAccount.FirstName,
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => nickname,
                'Alias' => 'testCust',
                'LanguageLocaleKey' => 'pt_PT',
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id,
                'ContactId' => contactId
            }
        );
    }

    @isTest
    static void updateUserLanguageTest() {
        //Scenario: User changed site language from PT to EN
        //Expected: User language updated
        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];
        Test.startTest();
        System.runAs(customerUser) {
            COMM_LCC_LanguageSelector.updateUserLanguage('en_US');
        }
        Test.stopTest();
        User resultUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = :customerUser.Id];
        Assert.areEqual('en_US', resultUser.LanguageLocaleKey, 'expected user language to have been updated');
    }

    @isTest
    static void verifyUserLanguageTest() {
        //Scenario: User was sent to Community from Commerce with language set to English but his language is PT
        //Expected: Boolean True is returned and User language updated
        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];
        Boolean result;
        Test.startTest();
        System.runAs(customerUser) {
            result = COMM_LCC_LanguageSelector.verifyUserLanguage('en_US');
        }
        Test.stopTest();
        User resultUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = :customerUser.Id];
        Assert.isTrue(result, 'expected result to indicate user language was updated');
        Assert.areEqual('en_US', resultUser.LanguageLocaleKey, 'expected user language to have been updated');
    }

    @isTest
    static void verifyUserLanguageFailureTest() {
        //Scenario: Verify call is made but user language is null
        //Expected: Boolean False is returned
        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];
        Boolean result;
        Test.startTest();
        System.runAs(customerUser) {
            result = COMM_LCC_LanguageSelector.verifyUserLanguage(null);
        }
        Test.stopTest();
        Assert.isFalse(result, 'expected result to indicate user language wasn\'t updated');
    }

    @isTest
    static void updateUserLanguageFailureTest() {
        //Scenario: Update call is made but user language is null.
        //Expected: Exception is throwed and error log record is created.
        User customerUser = [SELECT Id FROM User WHERE Name = 'Test Customer' LIMIT 1];
        Boolean errorOccured = false;
        Test.startTest();
        try {
            System.runAs(customerUser) {
                COMM_LCC_LanguageSelector.updateUserLanguage(null);
            }
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        Assert.isTrue(errorOccured, 'expected an error to occur');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log record to have been created');
    }
}