/**
 * @author           Daniel Lascas
 * @description      COMM_TW_Contact_AirportUpdate test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024      97             ECOMM-1602: Original version
 **/
@isTest
private class COMM_TW_Contact_AirportUpdateTest {
    @isTest
    static void updateFieldTest() {
        //Scenario:	Contact's Airport was Updated.
        //Expected: Airport Text Field is updated

        //Generate mocked Contact
        Contact oldContact = (Contact) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Contact',
            new Map<String, Object>{ 'Id' => fflib_IdGenerator.generate(Contact.sObjectType), 'COMM_Airport__c' => 'LIS' }
        )[0];

        //Mocked Update where Airport is changed
        Contact newContact = oldContact.clone(true);
        newContact.COMM_Airport__c = 'LIS;OPO';

        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{ oldContact.Id => oldContact };
        List<Contact> newContactList = new List<Contact>{ newContact };

        Test.startTest();
        COMM_TW_Contact_AirportUpdate worker = new COMM_TW_Contact_AirportUpdate();
        worker.execute(newContactList, oldContactMap);
        Test.stopTest();

        Assert.areEqual(
            newContact.COMM_Airport__c,
            newContact.COMM_AirportTextList__c,
            'expected text airport field to be updated with multi-picklist airport fields value'
        );
    }
}