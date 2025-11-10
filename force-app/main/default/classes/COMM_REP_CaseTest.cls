/**
 * @author           Daniel Lascas
 * @description      COMM_REP_Case test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/03/2024      100            ECOMM-368: Original version
 **/
@isTest
private class COMM_REP_CaseTest {
    private final static COMM_REP_Case CASE_REP = new COMM_REP_Case();

    @TestSetup
    static void makeData() {
        //Create Test Account to associate with Test Case
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Tester',
                'PersonEmail' => 'test@tester.invalid',
                'RecordTypeId' => recTypeInfo.recordtypeid
            }
        )[0];
        //Create Test Case with Individual Staff Request Record Type
        recTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT);
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Case',
            new Map<String, Object>{
                'Status' => COMM_DO_Case.IN_APPROVAL_STATUS,
                'AccountId' => testAccount.Id,
                'RecordTypeId' => recTypeInfo.recordtypeid,
                'Type' => COMM_DO_Case.INDIVIDUAL_STAFF_TYPE,
                'COMM_FirstName__c' => 'test',
                'COMM_LastName__c' => 'client',
                'COMM_PhoneNumber__c' => '+351 930123456',
                'COMM_VATNumber__c' => 'PT290765432',
                'SuppliedEmail' => 'test@client.invalid',
                'COMM_JobRole__c' => 'Manager',
                'COMM_LicensePlate__c' => '00-AA-01',
                'COMM_VehicleBrand__c' => 'FIAT',
                'COMM_VehicleModel__c' => 'Punto',
                'COMM_Address__Street__s' => 'Avenida Teste',
                'COMM_Address__City__s' => 'Lisbon',
                'COMM_Address__PostalCode__s' => '1500',
                'COMM_Address__CountryCode__s' => 'PT'
            }
        );
    }

    @isTest
    static void getIndividualStaffRequestPendingByAccountIdTest() {
        List<Case> expectedList = [
            SELECT Id, AccountId
            FROM Case
            WHERE RecordType.DeveloperName = :COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT
            LIMIT 1
        ];

        Test.startTest();
        List<Case> actualList = CASE_REP.getIndividualStaffRequestPendingByAccountId(new Set<Id>{ expectedList[0].AccountId }, true);
        List<Case> actualListWithoutSecurity = CASE_REP.getIndividualStaffRequestPendingByAccountId(new Set<Id>{ expectedList[0].AccountId }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'retrieved case does not match expected');
        Assert.areEqual(expectedList[0].Id, actualListWithoutSecurity[0].Id, 'retrieved case without security does not match expected');
    }

    @isTest
    static void getSubscriptionCaseByIdsTest() {
        List<Case> expectedList = [
            SELECT Id
            FROM Case
            LIMIT 1
        ];

        Test.startTest();
        List<Case> actualList = CASE_REP.getSubscriptionCaseByIds(new Set<Id>{ expectedList[0].Id }, true);
        List<Case> actualNoSecurityList = CASE_REP.getSubscriptionCaseByIds(new Set<Id>{ expectedList[0].Id }, false);
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'retrieved case does not match expected');
        Assert.areEqual(expectedList[0].Id, actualNoSecurityList[0].Id, 'retrieved case with no security does not match expected');
    }
}