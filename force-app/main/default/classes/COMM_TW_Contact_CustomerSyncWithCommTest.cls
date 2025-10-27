/**
 * @author Daniel Lascas
 * @description COMM_TW_Contact_CustomerSyncWithCommerce test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    09/07/2024      100            ECOMM-1637: Original version
 **/
@isTest
private class COMM_TW_Contact_CustomerSyncWithCommTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IDO_CustomerSyncMapping CUSTOMER_SYNC_MAPPING_DO = (COMM_DO_CustomerSyncMapping) MOCKS.mock(
        COMM_DO_CustomerSyncMapping.class
    );

    @isTest
    static void withMappingTest() {
        //Scenario: Contact is updated and is set for Commerce Sync
        //Expected: Sync Logic is executed (request body field updated and queuable called)

        //Generate mocked Contact
        Contact oldContact = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Contact.sObjectType), 'FirstName' => 'test', 'LastName' => 'client' }
        )[0];
        oldContact = (Contact) COMM_TestDataFactory.setField(oldContact, new Map<String, Object>{ 'COMM_SetForCommerceIntegration__c' => true });

        //Mocked Update where country is set to Portugal
        Contact newContact = oldContact.clone(true);
        newContact.FirstName = 'tester';

        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{ oldContact.Id => oldContact };
        List<Contact> newContactList = new List<Contact>{ newContact };

        //Mock DO Calls
        MOCKS.startStubbing();
        MOCKS.when(CUSTOMER_SYNC_MAPPING_DO.getCoreFieldList(fflib_Match.anyString(), fflib_Match.anyBoolean()))
            .thenReturn(new Set<String>{ 'FirstName', 'LastName' });
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_Contact_CustomerSyncWithCommerce worker = new COMM_TW_Contact_CustomerSyncWithCommerce();
        worker = new COMM_TW_Contact_CustomerSyncWithCommerce(CUSTOMER_SYNC_MAPPING_DO);
        worker.execute(newContactList, oldContactMap);
        Integer dmlExecuted = Limits.getDMLStatements();
        Test.stopTest();

        Assert.isNotNull(newContact.COMM_IntegrationRequestBody__c, 'expected body field to be updated');
        Assert.areEqual(1, dmlExecuted, 'expected one Platform Event to be published');
    }

    @isTest
    static void noMappingTest() {
        //Scenario: Contact is updated but isn't set for Commerce Sync
        //Expected: Sync Logic isn't executed (request body field null and queuable not called)

        //Generate mocked Contact
        Contact oldContact = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Contact.sObjectType), 'FirstName' => 'test', 'LastName' => 'client' }
        )[0];
        oldContact = (Contact) COMM_TestDataFactory.setField(oldContact, new Map<String, Object>{ 'COMM_SetForCommerceIntegration__c' => false });

        //Mocked Update where country is set to Portugal
        Contact newContact = oldContact.clone(true);
        newContact.FirstName = 'tester';

        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{ oldContact.Id => oldContact };
        List<Contact> newContactList = new List<Contact>{ newContact };

        Test.startTest();
        COMM_TW_Contact_CustomerSyncWithCommerce worker = new COMM_TW_Contact_CustomerSyncWithCommerce();
        worker.execute(newContactList, oldContactMap);
        Integer dmlExecuted = Limits.getDMLStatements();
        Test.stopTest();

        Assert.isNull(newContact.COMM_IntegrationRequestBody__c, 'expected body field to not be updated');
        Assert.areEqual(0, dmlExecuted, 'expected no Platform Event to be published');
    }
}