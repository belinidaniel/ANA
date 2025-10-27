/**
 * @author Carlos Fusco
 * @description COMM_SL_UserCreation test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date            Coverage(%)         Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco       05/02/2024           100            Original version
 **/
@isTest
private class COMM_SL_UserCreationTest {
    @TestSetup
    static void makeData() {
        COMM_IREP_Profile profileRep = new COMM_REP_PROFILE();
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'Test@ana.pt.test',
                'Email' => 'Test@ana.pt.test',
                'LastName' => 'TestUser',
                'FirstName' => 'Test',
                'CommunityNickname' => 'Test',
                'Alias' => 'TestTest',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => (profileRep.getProfilesByName(new Set<String>{ COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN }, false)[0]).Id,
                'userRoleId' => [SELECT Id FROM UserRole WHERE DeveloperName = 'COMM_ANA_Admin' LIMIT 1]
                .Id
            }
        );
    }

    @isTest
    static void createUserFromContactTest() {
        //Scenario: User is set for Creation
        //Expected: User Record Created
        Id userId = [SELECT Id FROM User WHERE Username = 'Test@ana.pt.test' LIMIT 1].Id;
        List<Account> accountRecordList = (List<Account>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Description' => 'TestAccount',
                'Name' => 'client',
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(
                    Account.sObjectType,
                    COMM_DO_Account.COLLECTIVEPARTNER_ACCOUNT_RECORD_TYPE
                ),
                'OwnerId' => userId
            }
        );

        List<Contact> contactRecordList = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{ 'LastName' => 'Contact', 'FirstName' => 'Test', 'AccountId' => accountRecordList[0].Id }
        );

        COMM_SL_UserCreation.InputWrapper testInputWrapper = new COMM_SL_UserCreation.InputWrapper();
        testInputWrapper.firstName = 'TestFirstName';
        testInputWrapper.lastName = 'TestLastName';
        testInputWrapper.email = 'test@mail.com';
        testInputWrapper.contactId = contactRecordList.get(0).Id;
        testInputWrapper.language = UserInfo.getLanguage();

        Test.startTest();
        COMM_SL_UserCreation.createUserFromContact(new List<COMM_SL_UserCreation.InputWrapper>{ testInputWrapper });
        Test.stopTest();

        List<User> userCreatedList = [
            SELECT Id
            FROM User
            WHERE FirstName = 'TestFirstName' AND LastName = 'TestLastName' AND Email = 'test@mail.com'
        ];
        Assert.areEqual(userCreatedList.size(), 1, 'User not created!');
    }

    @isTest
    static void createUserFailureTest() {
        //Scenario: User is set for Creation but Last Name wasn't provided
        //Expected: User isn't created and a Error Log is generated
        Id userId = [SELECT Id FROM User WHERE Username = 'Test@ana.pt.test' LIMIT 1].Id;
        List<Account> accountRecordList = (List<Account>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Description' => 'TestAccount',
                'Name' => 'client',
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(
                    Account.sObjectType,
                    COMM_DO_Account.COLLECTIVEPARTNER_ACCOUNT_RECORD_TYPE
                ),
                'OwnerId' => userId
            }
        );

        List<Contact> contactRecordList = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Contact',
            new Map<String, Object>{ 'LastName' => 'Contact', 'FirstName' => 'Test', 'AccountId' => accountRecordList[0].Id }
        );

        COMM_SL_UserCreation.InputWrapper testInputWrapper = new COMM_SL_UserCreation.InputWrapper();
        testInputWrapper.firstName = 'TestFirstName';
        testInputWrapper.email = 'test@mail.com';
        testInputWrapper.contactId = contactRecordList.get(0).Id;
        testInputWrapper.language = UserInfo.getLanguage();

        Test.startTest();
        COMM_SL_UserCreation.createUserFromContact(new List<COMM_SL_UserCreation.InputWrapper>{ testInputWrapper });
        Test.stopTest();

        List<User> userCreatedList = [
            SELECT Id
            FROM User
            WHERE FirstName = 'TestFirstName' AND Email = 'test@mail.com'
        ];
        Assert.areEqual(0, userCreatedList.size(), 'User was created!');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected error log to have been generated');
    }
}