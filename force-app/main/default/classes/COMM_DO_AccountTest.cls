/**
 * @author           Daniel Lascas
 * @description      COMM_DO_Account test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/02/2024      100            Original version
 **/
@isTest
private class COMM_DO_AccountTest {
    @isTest
    static void instantiatePersonAccountTest() {
        String firstName = 'Test';
        String lastName = 'Tester';
        String personEmail = 'test@tester.com';

        Test.startTest();
        Account accountResult = COMM_DO_Account.instantiatePersonAccount(firstName, lastName, personEmail);
        Test.stopTest();

        Assert.areEqual(firstName, accountResult.FirstName, 'created account does not have expected First Name');
        Assert.areEqual(lastName, accountResult.LastName, 'created account does not have expected Last Name');
        Assert.areEqual(personEmail, accountResult.PersonEmail, 'created account does not have expected Email');
    }

    @isTest
    static void validationSuccessPortugueseVatTest() {
        //Scenario: A B2B Account is to be inserted with a valid Portuguese VAT Number
        //Expected: No error message is added to record

        //Generate mocked B2B Account
        Account newAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'COMM_VATNumber__c' => '500700834', 'BillingCountryCode' => 'PT' }
        )[0];
        newAccount = (Account) COMM_TestDataFactory.setField(newAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        Test.startTest();
        Boolean result = COMM_DO_Account.verifyInvalidVAT(newAccount, null, true);
        Test.stopTest();

        Assert.isFalse(result, 'expected invalid check to return false');
    }

    @isTest
    static void validationFailedPortugueseVatTest() {
        //Scenario: A B2C Account's Company Billing Country is to be updated to Portugal
        //but has an VAT Number that is an invalid Portuguese VAT
        //Expected: Invalid Verification returns VAT as invalid (Result = True)

        //Generate mocked B2C Account with initial VAT and Country as Belgium
        Account oldAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_CompanyVATNumber__c' => '1234567890',
                'COMM_CompanyBillingAddress__CountryCode__s' => 'BE'
            }
        )[0];
        oldAccount = (Account) COMM_TestDataFactory.setField(oldAccount, new Map<String, Object>{ 'IsPersonAccount' => true });

        //Mocked Update where country is set to Portugal
        Account newAccount = oldAccount.clone(true);
        newAccount.COMM_CompanyBillingAddress__CountryCode__s = 'PT';

        Test.startTest();
        Boolean result = COMM_DO_Account.verifyInvalidVAT(newAccount, oldAccount, false);
        Test.stopTest();

        Assert.isTrue(result, 'expected invalid check to return true');
    }
}