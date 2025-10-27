/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Contact_UpdateEffectiveAccount test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/10/2024      100            ECOMM-1813 - Original version
 **/
@isTest
private class COMM_TW_Contact_UpdateEffectiveAccTest {
    @isTest
    static void effectiveAccountUpdatedTest() {
        //Scenario: Contact is Created
        //Expected: Contact's Effective Account is set with Contact's Account

        //Generate mocked Contact
        Contact newContact = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'AccountId' => fflib_IDGenerator.generate(Account.sObjectType), 'FirstName' => 'test', 'LastName' => 'client' }
        )[0];

        Test.startTest();
        COMM_TW_Contact_UpdateEffectiveAccount worker = new COMM_TW_Contact_UpdateEffectiveAccount();
        worker.execute(new List<Contact>{ newContact });
        Test.stopTest();

        Assert.areEqual(newContact.AccountId, newContact.COMM_EffectiveAccountId__c, 'expected effective account to be contact\'s account');
    }

    @isTest
    static void effectiveAccountNotUpdatedTest() {
        //Scenario: Contact is Created but with a different Account set as effective
        //Expected: Contact's Effective Account isn't changed

        //Generate mocked Contact
        Contact newContact = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{
                'AccountId' => fflib_IDGenerator.generate(Account.sObjectType),
                'FirstName' => 'test',
                'LastName' => 'client',
                'COMM_EffectiveAccountId__c' => fflib_IDGenerator.generate(Account.sObjectType)
            }
        )[0];

        Test.startTest();
        COMM_TW_Contact_UpdateEffectiveAccount worker = new COMM_TW_Contact_UpdateEffectiveAccount();
        worker.execute(new List<Contact>{ newContact });
        Test.stopTest();

        Assert.isNotNull(newContact.COMM_EffectiveAccountId__c, 'expected effective account to have value');
        Assert.areNotEqual(
            newContact.AccountId,
            newContact.COMM_EffectiveAccountId__c,
            'expected effective account to be different from contact\'s account'
        );
    }
}