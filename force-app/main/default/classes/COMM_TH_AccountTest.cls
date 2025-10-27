/**
 * @author Daniel Lascas
 * @description COMM_TH_Account test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_TH_AccountTest {
    @isTest
    static void insertTest() {
        Account accountRecord = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'test',
                'LastName' => 'client',
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Account.sObjectType, COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE)
            }
        )[0];

        Test.startTest();
        insert accountRecord;
        Test.stopTest();

        Assert.isNotNull(accountRecord.Id, 'account record was not inserted');
    }

    @isTest
    static void updateTest() {
        Account accountRecord = (Account) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Description' => 'TestAccount',
                'FirstName' => 'test',
                'LastName' => 'client',
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Account.sObjectType, COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE)
            }
        )[0];

        Test.startTest();
        accountRecord.Description = 'TestAccount2';
        update accountRecord;
        Test.stopTest();

        Account actualRecord = [SELECT Id, Description FROM Account WHERE Id = :accountRecord.Id];

        Assert.areEqual(accountRecord.Description, actualRecord.Description, 'account record was not updated');
    }
}