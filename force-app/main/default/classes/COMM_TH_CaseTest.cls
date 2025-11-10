/**
 * @author Daniel Lascas
 * @description COMM_TH_Case test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024      100            Original version
 * Daniel Lascas    08/04/2024      100            ECOMM-194: Added update test
 **/
@isTest
private class COMM_TH_CaseTest {
    @isTest
    static void insertTest() {
        Case caseRecord = (Case) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'Description' => 'TestCase',
                'SuppliedEmail' => 'test@test.invalid',
                'Type' => COMM_DO_Case.INDIVIDUAL_STAFF_TYPE,
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Case.sObjectType, 'COMM_ContactUs')
            }
        )[0];

        Test.startTest();
        insert caseRecord;
        Test.stopTest();

        Assert.isNotNull(caseRecord.Id, 'case record was not inserted');
    }

    @isTest
    static void updateTest() {
        Case caseRecord = (Case) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Case',
            new Map<String, Object>{
                'Description' => 'TestCase',
                'SuppliedEmail' => 'test@test.invalid',
                'Type' => COMM_DO_Case.INDIVIDUAL_STAFF_TYPE,
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Case.sObjectType, 'COMM_ContactUs')
            }
        )[0];

        Test.startTest();
        caseRecord.Description = 'TestCase2';
        update caseRecord;
        Test.stopTest();

        Case actualRecord = [SELECT Id, Description FROM Case WHERE Id = :caseRecord.Id];

        Assert.areEqual(caseRecord.Description, actualRecord.Description, 'case record was not updated');
    }
}