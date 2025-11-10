/**
 * @author Miguel Freire
 * @description COMM_TW_User_VerifyPartnerPermission test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel freire    02/04/2024      100            Original version
 **/
@isTest
private class COMM_TW_User_AddToPublicGroupTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_REP_Profile PROFILE_REP = (COMM_REP_Profile) MOCKS.mock(COMM_REP_Profile.class);
    private final static COMM_REP_Group GROUP_REP = (COMM_REP_Group) MOCKS.mock(COMM_REP_Group.class);
    private final static COMM_REP_GroupMember GROUP_MEMBER_REP = (COMM_REP_GroupMember) MOCKS.mock(COMM_REP_GroupMember.class);

    @isTest
    static void partnerAdminInsertTest() {
        //Generate a mocked Profile
        Profile partnerAdminProfile = (Profile) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Profile',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Profile.sobjectType), 'Name' => COMM_DO_Profile.PROFILE_NAME_PARTNER_ADMIN }
        )[0];

        //Generate a mocked User Record
        User userRecord = (User) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(User.sobjectType),
                'IsActive' => true,
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'ProfileId' => partnerAdminProfile.Id
            }
        )[0];

        //Generate a mocked Group
        Group partnerAdminGroup = (Group) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Group',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(gROUP.sobjectType), 'Name' => COMM_DO_Group.GROUP_NAME_PARTNER_ADMIN }
        )[0];

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_REP.getProfilesByName((Set<String>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyObject()))
            .thenReturn(new List<Profile>{ partnerAdminProfile });
        MOCKS.when(GROUP_REP.getGroupsByName((Set<String>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyObject()))
            .thenReturn(new List<Group>{ partnerAdminGroup });
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_TW_User_AddToPublicGroup worker = new COMM_TW_User_AddToPublicGroup();
            worker = new COMM_TW_User_AddToPublicGroup(PROFILE_REP, GROUP_REP, GROUP_MEMBER_REP);
            worker.execute(new List<User>{ userRecord });
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}