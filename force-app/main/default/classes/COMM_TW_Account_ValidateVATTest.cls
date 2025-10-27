/**
 * @author Daniel Lascas
 * @description COMM_TW_Account_ValidateVAT test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_TW_Account_ValidateVATTest {
    @isTest
    static void validationSuccessPortugueseVatTest() {
        //Scenario: A B2B Account is inserted with a valid Portuguese VAT Number
        //Expected: No error message is added to record

        //Generate mocked B2B Account
        Account newAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{ 'COMM_VATNumber__c' => '500700834', 'BillingCountryCode' => 'PT' }
        )[0];
        newAccount = (Account) COMM_TestDataFactory.setField(newAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        List<Account> newAccountList = new List<Account>{ newAccount };

        Test.startTest();
        COMM_TW_Account_ValidateVAT worker = new COMM_TW_Account_ValidateVAT();
        worker.execute(newAccountList, null);
        Test.stopTest();

        Assert.isTrue(newAccount.getErrors().isEmpty(), 'expected no errors to have been added to account');
    }

    @isTest
    static void validationFailedPortugueseVatTest() {
        //Scenario: A B2B Account's Billing Country is updated to Portugal and
        //has an invalid Portuguese VAT Number
        //Expected: Invalid Portuguese VAT error message is added to record

        //Generate mocked B2B Account with initial VAT and Country as Belgium
        Account oldAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_VATNumber__c' => '1234567890',
                'BillingCountryCode' => 'BE',
                'COMM_CompanyVATNumber__c' => '1234567890',
                'COMM_CompanyBillingAddress__CountryCode__s' => 'BE'
            }
        )[0];
        oldAccount = (Account) COMM_TestDataFactory.setField(oldAccount, new Map<String, Object>{ 'IsPersonAccount' => true });

        //Mocked Update where country is set to Portugal
        Account newAccount = oldAccount.clone(true);
        newAccount.BillingCountryCode = 'PT';
        newAccount.COMM_CompanyBillingAddress__CountryCode__s = 'PT';

        Map<Id, Account> oldAccountMap = new Map<Id, Account>{ oldAccount.Id => oldAccount };
        List<Account> newAccountList = new List<Account>{ newAccount };

        Test.startTest();
        COMM_TW_Account_ValidateVAT worker = new COMM_TW_Account_ValidateVAT();
        worker.execute(newAccountList, oldAccountMap);
        Test.stopTest();

        Assert.isFalse(newAccount.getErrors().isEmpty(), 'expected an error to have been added to account');
        Assert.areEqual(System.Label.COMM_ACCOUNT_INVALID_VAT_ERROR, newAccount.getErrors()[0].getMessage(), 'Expected invalid vat error message');
    }
}