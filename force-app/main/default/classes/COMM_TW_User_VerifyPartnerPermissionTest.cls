/**
 * @author Daniel Lascas
 * @description COMM_TW_User_VerifyPartnerPermission test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024      100            ECOMM-700: Original version
 **/
@isTest
private class COMM_TW_User_VerifyPartnerPermissionTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_PermissionSetAssignment PERMISSION_SET_ASSIGNMENT_REP = (COMM_REP_PermissionSetAssignment) MOCKS.mock(
        COMM_REP_PermissionSetAssignment.class
    );
    private final static COMM_IDO_ProfilePermissionSetAssignment PROFILE_PERMISSION_ASSIGNMENT_DO = (COMM_DO_ProfilePermissionSetAssignment) MOCKS.mock(
        COMM_DO_ProfilePermissionSetAssignment.class
    );

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

        //Generate a mocked Permission Set
        PermissionSet partnerAdminPermissionSet = (PermissionSet) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PermissionSet',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(PermissionSet.sobjectType),
                'Name' => COMM_DO_PermissionSet.PARTNER_ADMIN_PERMISSION_SET
            }
        )[0];

        //Generate Mocked Metadata Assignment Map
        Map<Id, Set<Id>> assignmentMap = new Map<Id, Set<Id>>{ partnerAdminProfile.Id => new Set<Id>{ partnerAdminPermissionSet.Id } };

        //Expected Assignment to Insert
        PermissionSetAssignment expectedResult = new PermissionSetAssignment();
        expectedResult.AssigneeId = userRecord.Id;
        expectedResult.PermissionSetId = partnerAdminPermissionSet.Id;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_PERMISSION_ASSIGNMENT_DO.getAssignmentMap()).thenReturn(assignmentMap);
        MOCKS.when(
                PERMISSION_SET_ASSIGNMENT_REP.getAssignmentsByUserIdAndPermissionId(
                    (Set<Id>) fflib_Match.anyObject(),
                    (Set<Id>) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<PermissionSetAssignment>());
        MOCKS.when(PERMISSION_SET_ASSIGNMENT_REP.insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_TW_User_VerifyPartnerPermission worker = new COMM_TW_User_VerifyPartnerPermission();
            worker = new COMM_TW_User_VerifyPartnerPermission(PERMISSION_SET_ASSIGNMENT_REP, PROFILE_PERMISSION_ASSIGNMENT_DO);
            worker.execute(new List<User>{ userRecord }, false);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 0))
            .getAssignmentsByUserIdAndPermissionId((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 1))
            .insertSObjects(new List<PermissionSetAssignment>{ expectedResult });
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void nonPartnerAdminInsertTest() {
        //Scenario: A non-Partner Admin user is created
        //Expected: No Permission Set is assigned

        //Generate a mocked Partner Admin Profile
        Profile partnerAdminProfile = (Profile) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Profile',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Profile.sobjectType), 'Name' => COMM_DO_Profile.PROFILE_NAME_PARTNER_ADMIN }
        )[0];

        //Generate a mocked User Record with another Profile
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
                'ProfileId' => fflib_IdGenerator.generate(Profile.sobjectType)
            }
        )[0];

        //Generate a mocked Permission Set
        PermissionSet partnerAdminPermissionSet = (PermissionSet) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PermissionSet',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(PermissionSet.sobjectType),
                'Name' => COMM_DO_PermissionSet.PARTNER_ADMIN_PERMISSION_SET
            }
        )[0];

        //Generate Mocked Metadata Assignment Map
        Map<Id, Set<Id>> assignmentMap = new Map<Id, Set<Id>>{ partnerAdminProfile.Id => new Set<Id>{ partnerAdminPermissionSet.Id } };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_PERMISSION_ASSIGNMENT_DO.getAssignmentMap()).thenReturn(assignmentMap);
        MOCKS.when(
                PERMISSION_SET_ASSIGNMENT_REP.getAssignmentsByUserIdAndPermissionId(
                    (Set<Id>) fflib_Match.anyObject(),
                    (Set<Id>) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<PermissionSetAssignment>());
        MOCKS.when(PERMISSION_SET_ASSIGNMENT_REP.insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_TW_User_VerifyPartnerPermission worker = new COMM_TW_User_VerifyPartnerPermission();
            worker = new COMM_TW_User_VerifyPartnerPermission(PERMISSION_SET_ASSIGNMENT_REP, PROFILE_PERMISSION_ASSIGNMENT_DO);
            worker.execute(new List<User>{ userRecord }, false);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 0))
            .getAssignmentsByUserIdAndPermissionId((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 0))
            .insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList());
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void partnerAdminUpdateAssigmentTest() {
        //Scenario: Partner Admin is updated. Permission Set wasn't assigned before update.
        //Expected: Permission Set is assigned.

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

        //Generate a mocked Permission Set
        PermissionSet partnerAdminPermissionSet = (PermissionSet) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PermissionSet',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(PermissionSet.sobjectType),
                'Name' => COMM_DO_PermissionSet.PARTNER_ADMIN_PERMISSION_SET
            }
        )[0];

        //Generate Mocked Metadata Assignment Map
        Map<Id, Set<Id>> assignmentMap = new Map<Id, Set<Id>>{ partnerAdminProfile.Id => new Set<Id>{ partnerAdminPermissionSet.Id } };

        //Expected Assignment to Insert
        PermissionSetAssignment expectedResult = new PermissionSetAssignment();
        expectedResult.AssigneeId = userRecord.Id;
        expectedResult.PermissionSetId = partnerAdminPermissionSet.Id;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_PERMISSION_ASSIGNMENT_DO.getAssignmentMap()).thenReturn(assignmentMap);
        MOCKS.when(
                PERMISSION_SET_ASSIGNMENT_REP.getAssignmentsByUserIdAndPermissionId(
                    (Set<Id>) fflib_Match.anyObject(),
                    (Set<Id>) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<PermissionSetAssignment>());
        MOCKS.when(PERMISSION_SET_ASSIGNMENT_REP.insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_TW_User_VerifyPartnerPermission worker = new COMM_TW_User_VerifyPartnerPermission();
            worker = new COMM_TW_User_VerifyPartnerPermission(PERMISSION_SET_ASSIGNMENT_REP, PROFILE_PERMISSION_ASSIGNMENT_DO);
            worker.execute(new List<User>{ userRecord }, true);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 1))
            .getAssignmentsByUserIdAndPermissionId(new Set<Id>{ userRecord.Id }, new Set<Id>{ partnerAdminPermissionSet.Id });
        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 1))
            .insertSObjects(new List<PermissionSetAssignment>{ expectedResult });
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }

    @isTest
    static void partnerAdminUpdateHasAssigmentTest() {
        //Scenario: Partner Admin is updated. Permission Set was assigned before update.
        //Expected: Permission Set is not assigned.

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

        //Generate a mocked Permission Set
        PermissionSet partnerAdminPermissionSet = (PermissionSet) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'PermissionSet',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(PermissionSet.sobjectType),
                'Name' => COMM_DO_PermissionSet.PARTNER_ADMIN_PERMISSION_SET
            }
        )[0];

        //Generate a mocked Permission Set Assignment
        PermissionSetAssignment partnerAssignment = (PermissionSetAssignment) COMM_TestDataFactory.setField(
            new PermissionSetAssignment(),
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(PermissionSetAssignment.sobjectType),
                'AssigneeId' => userRecord.Id,
                'PermissionSetId' => partnerAdminPermissionSet.Id
            }
        );

        //Generate Mocked Metadata Assignment Map
        Map<Id, Set<Id>> assignmentMap = new Map<Id, Set<Id>>{ partnerAdminProfile.Id => new Set<Id>{ partnerAdminPermissionSet.Id } };

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(PROFILE_PERMISSION_ASSIGNMENT_DO.getAssignmentMap()).thenReturn(assignmentMap);
        MOCKS.when(
                PERMISSION_SET_ASSIGNMENT_REP.getAssignmentsByUserIdAndPermissionId(
                    (Set<Id>) fflib_Match.anyObject(),
                    (Set<Id>) fflib_Match.anyObject()
                )
            )
            .thenReturn(new List<PermissionSetAssignment>{ partnerAssignment });
        MOCKS.when(PERMISSION_SET_ASSIGNMENT_REP.insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_TW_User_VerifyPartnerPermission worker = new COMM_TW_User_VerifyPartnerPermission();
            worker = new COMM_TW_User_VerifyPartnerPermission(PERMISSION_SET_ASSIGNMENT_REP, PROFILE_PERMISSION_ASSIGNMENT_DO);
            worker.execute(new List<User>{ userRecord }, true);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 1))
            .getAssignmentsByUserIdAndPermissionId((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject());
        ((COMM_IREP_PermissionSetAssignment) mocks.verify(PERMISSION_SET_ASSIGNMENT_REP, 0))
            .insertSObjects((List<PermissionSetAssignment>) fflib_Match.anyList());
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}