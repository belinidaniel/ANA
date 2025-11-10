/**
 * @author           Daniel Lascas
 * @description      COMM_DO_User test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/02/2024      100            Original version
 **/
@isTest
private class COMM_DO_UserTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Profile PROFILE_REP = (COMM_REP_Profile) MOCKS.mock(COMM_REP_Profile.class);

    @isTest
    static void instantiateUserTest() {
        String firstName = 'Test';
        String lastName = 'Tester';
        String personEmail = 'test@tester.com';

        List<Profile> mockedProfileList = (List<Profile>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Profile',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Profile.sobjectType) }
        );

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_REP.getProfilesByName((Set<String>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(mockedProfileList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_DO_User worker = new COMM_DO_User();
        worker = new COMM_DO_User(PROFILE_REP);
        User userResult = worker.instantiateUser(firstName, lastName, personEmail, COMM_DO_User.NORMAL_LOGIN_IDENTIFIER);
        Test.stopTest();

        //Verify Results
        ((COMM_IREP_Profile) mocks.verify(PROFILE_REP, 1)).getProfilesByName(new Set<String>{ COMM_DO_Profile.PROFILE_NAME_IDENTITY_USER }, false);
        Assert.areEqual(firstName, userResult.FirstName, 'created user does not have expected First Name');
        Assert.areEqual(lastName, userResult.LastName, 'created user does not have expected Last Name');
        Assert.areEqual(personEmail, userResult.Email, 'created user does not have expected Email');
        Assert.areEqual(mockedProfileList[0].Id, userResult.ProfileId, 'created user does not have expected Profile');
    }
}