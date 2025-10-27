/**
 * @author           Miguel Freire
 * @description      COMM_SL_SelfRegisterHandler Test Class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)        Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    21/03/2024      93                 Original version
 **/
@isTest
private class COMM_SL_SelfRegisterHandlerTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_REP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_DO_User USER_DO = (COMM_DO_User) MOCKS.mock(COMM_DO_User.class);
    private final static COMM_REP_Contact CONTACT_REP = (COMM_REP_Contact) MOCKS.mock(COMM_REP_Contact.class);
    private final static COMM_DO_Email EMAIL_DO = (COMM_DO_Email) MOCKS.mock(COMM_DO_Email.class);

    @isTest
    static void interfaceTest() {
        //Scenario: This is just for coverage.
        //The interface methods are static and cannot be tested using the mock framework.
        //The actual testing is done below using the mock framework.
        Boolean errorOccured = false;
        try {
            COMM_SL_SelfRegisterHandler.registerUser(null, null, null, null, null, null, null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void testExceptionOnRegisterUser() {
        //Scenario: A user tries to register but an user already exists with that email and login type
        //Expected: Exception is trown

        //Mock expected User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@email.com',
                'LastName' => 'Test',
                'FirstName' => 'User',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => 'portaluser',
                'Alias' => 'portalUs',
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => fflib_IDGenerator.generate(Profile.SObjectType)
            }
        )[0];

        //Password Input
        String password = 'Usertest1!';

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    (Boolean) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<User>{ userRecord });
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_SL_SelfRegisterHandler worker = new COMM_SL_SelfRegisterHandler();
            worker = new COMM_SL_SelfRegisterHandler(USER_REP, USER_DO, CONTACT_REP, EMAIL_DO);
            worker.handleRegisterUser(
                userRecord.firstName,
                userRecord.lastName,
                userRecord.email,
                password,
                userRecord.languagelocalekey,
                null,
                false
            );
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Results
        Assert.isTrue(errorOccured, 'error trown because a User already exists with that email and login type');
    }
    @isTest
    static void testSuccessOnRegisterUser() {
        //Scenario: A user tries to register and it is successful
        //Expected: No exception trown

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
                'Username' => 'testuser2@ana.pt.test',
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
        //Password Input
        String password = 'Usertest1!';

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(
                USER_REP.getUserByEmailAndLoginType(
                    (Set<String>) fflib_Match.anyObject(),
                    (Set<String>) fflib_Match.anyObject(),
                    (Boolean) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<User>{ userRecords[0] });
        MOCKS.when(
                USER_DO.instantiateUser(
                    (String) fflib_Match.anyObject(),
                    (String) fflib_Match.anyObject(),
                    (String) fflib_Match.anyObject(),
                    (String) fflib_Match.anyObject()
                )
            )
            .thenReturn(userRecords[0]);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_SL_SelfRegisterHandler worker = new COMM_SL_SelfRegisterHandler();
            worker = new COMM_SL_SelfRegisterHandler(USER_REP, USER_DO, CONTACT_REP, EMAIL_DO);
            worker.handleRegisterUser(
                userRecords[0].firstName,
                userRecords[0].lastName,
                userRecords[0].email,
                password,
                userRecords[0].languagelocalekey,
                'testParameter',
                false
            );
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        //Verify Resultsy
        Assert.isFalse(errorOccured, 'User registrated');
    }
}