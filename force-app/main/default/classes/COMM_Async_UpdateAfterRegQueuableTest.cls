/**
 * @author         Miguel Freire
 * @description    COMM_Async_UpdateAfterRegisterQueuable test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire     21/03/2024      90            Original version
 **/
@isTest
public class COMM_Async_UpdateAfterRegQueuableTest {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);

    @isTest
    private static void COMM_Async_UpdateAfterRegQueuableTest() {
        //Scenario: The class tries to update a user and send an email
        //Expected: Updates the user

        //Mock expected Contact Record
        List<Contact> contactRecords = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'LastName' => 'Contact', 'FirstName' => 'Portal' }
        );

        //Mock expected User Record
        COMM_IREP_Profile profileRep = new COMM_REP_PROFILE();
        List<User> userRecords = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser2@ana.pt.test' + UserInfo.getOrganizationId(),
                'Email' => 'test2@email.com',
                'LastName' => 'Test2',
                'FirstName' => 'User2',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => (profileRep.getProfilesByName(new Set<String>{ 'Standard User' }, false)[0]).Id
            }
        );

        //resetUrl input
        String resetUrl = 'testURL';

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        String errorMessage = '';
        try {
            COMM_Async_UpdateAfterRegisterQueuable newQueuableRun = new COMM_Async_UpdateAfterRegisterQueuable(
                userRecords[0],
                resetUrl,
                COMM_DO_Email.EMAIL_TEMPLATE_EMAIL_VALIDATION
            );
            newQueuableRun.execute(null);
        } catch (Exception e) {
            errorOccured = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        //Verify Results
        Assert.isFalse(errorOccured, errorMessage);
    }

    @isTest
    private static void COMM_Async_UpdateAfterRegQueuableTestError() {
        //Scenario: The class tries to update a user and send an email
        //Expected: Updates the user

        //Mock expected Contact Record
        List<Contact> contactRecords = (List<Contact>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'LastName' => 'Contact', 'FirstName' => 'Portal' }
        );

        //Mock expected User Record
        COMM_IREP_Profile profileRep = new COMM_REP_PROFILE();
        List<User> userRecords = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser2@ana.pt.test' + UserInfo.getOrganizationId(),
                'Email' => 'test2@email.com',
                'LastName' => 'Test2',
                'FirstName' => 'User2',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => (profileRep.getProfilesByName(new Set<String>{ 'Standard User' }, false)[0]).Id
            }
        );

        //resetUrl input
        String resetUrl = 'testURL';

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;

        try {
            COMM_Async_UpdateAfterRegisterQueuable newQueuableRun = new COMM_Async_UpdateAfterRegisterQueuable(
                userRecords[0],
                resetUrl,
                COMM_DO_Email.EMAIL_TEMPLATE_EMAIL_VALIDATION
            );
            newQueuableRun.execute(null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        Assert.isTrue(errorOccured, 'User Updated and email sent');
    }
}