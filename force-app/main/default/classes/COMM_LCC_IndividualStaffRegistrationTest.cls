/**
 * @author Daniel Lascas
 * @description COMM_LCC_IndividualStaffRegistration test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/03/2024      100            ECOMM-368: Original version
 **/
@isTest
private class COMM_LCC_IndividualStaffRegistrationTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Case CASE_REP = (COMM_REP_Case) MOCKS.mock(COMM_REP_Case.class);
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);
    private final static COMM_IREP_Attachment ATTACHMENT_REP = (COMM_REP_Attachment) MOCKS.mock(COMM_REP_Attachment.class);

    @isTest
    static void interfaceTest() {
        //Scenario: This is just for coverage.
        //The interface methods are static and cannot be tested using the mock framework.
        //The actual testing is done below using the mock framework.
        Boolean errorOccured = false;
        try {
            COMM_LCC_IndividualStaffRegistration.submitCase(null, null, null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Assert.isTrue(errorOccured, 'no error has occured when submiting null data');
    }

    @isTest
    static void getCountryPicklistValuesTest() {
        //Retrieve Map with Country Values

        Test.startTest();
        Map<String, String> resultMap = COMM_LCC_IndividualStaffRegistration.getCountryPicklistValues();
        Test.stopTest();

        Assert.isFalse(resultMap.isEmpty(), 'expected a map with values');
        Assert.isTrue(resultMap.containsKey('PT'), 'expected map to contain Portugal');
    }

    @isTest
    static void validateVatTest() {
        //Call VAT Validation Test

        Test.startTest();
        Boolean validationResult = COMM_LCC_IndividualStaffRegistration.validateVAT('2191', 'PT');
        Test.stopTest();

        Assert.isFalse(validationResult, 'expected validation to fail');
    }

    @isTest
    static void verifyNoPendingCasesTest() {
        //Scenario: Verifies if User has pending cases
        //Expected: No Pending Cases

        Test.startTest();
        Boolean result = COMM_LCC_IndividualStaffRegistration.verifyPendingCases();
        Test.stopTest();

        Assert.isFalse(result, 'expected no pending cases found');
    }

    @isTest
    static void handleVerifyPendingCasesTest() {
        //Scenario: Verifies if User has pending cases
        //Expected: Pending Cases Exist

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(User.sObjectType), 'FirstName' => 'Test', 'LastName' => 'User' }
        );
        userList[0] = (User) COMM_TestDataFactory.setField(
            userList[0],
            new Map<String, Object>{ 'AccountId' => fflib_IdGenerator.generate(User.sObjectType) }
        );

        //Mock Pending Case
        List<Case> caseList = (List<Case>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Case.sObjectType),
                'Status' => COMM_DO_Case.WAITING_APPROVAL_STATUS,
                'AccountId' => userList[0].AccountId
            }
        );

        //Mock queries
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(caseList);
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_IndividualStaffRegistration worker = new COMM_LCC_IndividualStaffRegistration();
        worker = new COMM_LCC_IndividualStaffRegistration(CASE_REP, USER_REP, ATTACHMENT_REP);
        Boolean result = worker.handleVerifyPendingCases();
        Test.stopTest();

        Assert.isTrue(result, 'expected that pending cases exist');
    }

    @isTest
    static void handleSubmitCaseTest() {
        //Scenario: User fills form and submits it. There are no pending case in existence.
        //Expected: Case is created

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(User.sObjectType), 'FirstName' => 'Test', 'LastName' => 'User' }
        );
        userList[0] = (User) COMM_TestDataFactory.setField(
            userList[0],
            new Map<String, Object>{ 'AccountId' => fflib_IdGenerator.generate(User.sObjectType) }
        );

        Case caseRecord = (Case) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{ 'COMM_FirstName__c' => 'Test', 'COMM_LastName__c' => 'User' }
        )[0];
        String fileName = 'Test.pdf';
        Blob fileData = Blob.valueOf('Test File Mocked Data');

        String fileDataAsString = EncodingUtil.base64Encode(fileData);

        Attachment expectedAttachment = new Attachment();
        expectedAttachment.Body = fileData;
        expectedAttachment.Name = fileName;
        expectedAttachment.ParentId = caseRecord.Id;

        //Mock insert DML operations
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(new List<Case>());
        MOCKS.when(CASE_REP.insertSObjects((List<Case>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(ATTACHMENT_REP.insertSObjects((List<Attachment>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_LCC_IndividualStaffRegistration worker = new COMM_LCC_IndividualStaffRegistration();
        worker = new COMM_LCC_IndividualStaffRegistration(CASE_REP, USER_REP, ATTACHMENT_REP);
        worker.handleSubmitCase(caseRecord, fileName, fileDataAsString);
        Test.stopTest();

        ((COMM_IREP_Case) mocks.verify(CASE_REP, 1)).insertSObjects(new List<Case>{ caseRecord });
        ((COMM_IREP_Attachment) mocks.verify(ATTACHMENT_REP, 1)).insertSObjects(new List<Attachment>{ expectedAttachment });

        Assert.areEqual(
            COMM_GEN_Utility.getRecordTypeIdByDevName(Case.SObjectType, COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT),
            caseRecord.RecordTypeId,
            'case wasn\'t given the expected record type ID'
        );
    }

    @isTest
    static void handleSubmitCaseFailureTest() {
        //Scenario: User fills form and submits it. A pending case already exists.
        //Expected: An exception is throwed.

        //Mock User Record
        List<User> userList = (List<User>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'User',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(User.sObjectType), 'FirstName' => 'Test', 'LastName' => 'User' }
        );
        userList[0] = (User) COMM_TestDataFactory.setField(
            userList[0],
            new Map<String, Object>{ 'AccountId' => fflib_IdGenerator.generate(User.sObjectType) }
        );

        //Mock Pending Case
        List<Case> caseList = (List<Case>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'Id' => fflib_IdGenerator.generate(Case.sObjectType),
                'Status' => COMM_DO_Case.WAITING_APPROVAL_STATUS,
                'AccountId' => userList[0].AccountId
            }
        );

        Case caseRecord = (Case) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{ 'COMM_FirstName__c' => 'Test', 'COMM_LastName__c' => 'User' }
        )[0];
        String fileName = 'Test.pdf';
        Blob fileData = Blob.valueOf('Test File Mocked Data');

        String fileDataAsString = EncodingUtil.base64Encode(fileData);

        Attachment expectedAttachment = new Attachment();
        expectedAttachment.Body = fileData;
        expectedAttachment.Name = fileName;
        expectedAttachment.ParentId = caseRecord.Id;

        //Throws an Exception when method is called (to test failure)
        MOCKS.startStubbing();
        MOCKS.when(USER_REP.getUserAccountAndContactDataById((Set<Id>) fflib_Match.anyObject())).thenReturn(userList);
        MOCKS.when(CASE_REP.getIndividualStaffRequestPendingByAccountId((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
            .thenReturn(caseList);
        MOCKS.when(CASE_REP.insertSObjects((List<Case>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(ATTACHMENT_REP.insertSObjects((List<Attachment>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_IndividualStaffRegistration worker = new COMM_LCC_IndividualStaffRegistration();
            worker = new COMM_LCC_IndividualStaffRegistration(CASE_REP, USER_REP, ATTACHMENT_REP);
            worker.handleSubmitCase(caseRecord, fileName, fileDataAsString);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        ((COMM_IREP_Case) mocks.verify(CASE_REP, 0)).insertSObjects((List<Case>) fflib_Match.anyList());
        ((COMM_IREP_Attachment) mocks.verify(ATTACHMENT_REP, 0)).insertSObjects((List<Attachment>) fflib_Match.anyList());

        Assert.isTrue(errorOccured, 'no error occured when expected one');
    }
}