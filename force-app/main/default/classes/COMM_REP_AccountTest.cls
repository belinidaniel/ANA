/**
 * @author Daniel Lascas
 * @description COMM_REP_Account test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    26/02/2024      100            Original version
 * Daniel Lascas    12/03/2024      100            Added getAccountByIdsTest
 * Daniel Reto      18/06/2024      100            New test method
 * Daniel Reto      04/11/2024      100            ECOMM-327
 **/
@isTest
private class COMM_REP_AccountTest {
    private final static COMM_REP_Account ACCOUNT_REP = new COMM_REP_Account();

    @TestSetup
    static void makeData() {
        Schema.RecordTypeInfo recTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE);
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Tester',
                'PersonEmail' => 'test@tester.invalid',
                'RecordTypeId' => recTypeInfo.recordtypeid
            }
        );

        //Insert a test Partner Accountd
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Name' => 'Partner Account',
                'Type' => COMM_DO_Account.TYPE_PARTNER,
                'COMM_IsPartner__c' => true,
                'COMM_Airport__c' => 'LIS',
                'COMM_PartnerCategory__c' => 'Travel Agencies',
                'COMM_PaymentMethod__c' => 'Credit',
                'COMM_Email__c' => 'test@tester.invalid',
                'COMM_VATNumber__c' => '012012324',
                'BillingCountryCode' => 'ES',
                'BillingCity' => 'Test',
                'BillingStreet' => 'Test Avenue',
                'BillingPostalCode' => '2478'
            }
        );

        //Insert a test Reseller Account
        COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'Name' => 'Reseller Account', 'COMM_IsReseller__c' => true, 'COMM_ResellerId__c' => '123456789' });

        //Insert a test Affiliate Account
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Account',
            new Map<String, Object>{
                'Name' => 'Affiliate Account',
                'COMM_IsAffiliate__c' => true,
                'COMM_Airport__c' => 'LIS',
                'COMM_AffiliateCategory__c' => 'Travel Agencies',
                'COMM_PaymentMethod__c' => 'Credit',
                'COMM_Email__c' => 'test@tester.invalid',
                'COMM_VATNumber__c' => '012012325',
                'BillingCountryCode' => 'ES',
                'BillingCity' => 'Test',
                'BillingStreet' => 'Test Avenue',
                'BillingPostalCode' => '2478'
            }
        );
    }

    @isTest
    static void getPersonAccountByIdSetTest() {
        List<Account> expectedList = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getPersonAccountsByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }

    @isTest
    static void getAccountByIdsTest() {
        List<Account> expectedList = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAccountByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }

    @isTest
    static void getPartnerAccountsAndInvoicesByDateLiteralTest() {
        List<Account> expectedList = [
            SELECT Id, (SELECT Id FROM SubscriptionInvoices__r WHERE CreatedDate = THIS_MONTH)
            FROM Account
            WHERE Type = :COMM_DO_Account.TYPE_PARTNER
            LIMIT 1
        ];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getPartnerAccountsAndInvoicesByDateLiteral(
            new Set<String>{ expectedList[0].Id },
            'CreatedDate = THIS_MONTH'
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
        Assert.areEqual(
            expectedList[0].SubscriptionInvoices__r.size(),
            actualList[0].SubscriptionInvoices__r.size(),
            'number of invoices does not match expected'
        );
    }

    @isTest
    static void getAccountsAndInvoicesByIdsAndDateLiteralTest() {
        List<Account> expectedList = [
            SELECT Id, (SELECT Id FROM SubscriptionInvoices__r WHERE CreatedDate = THIS_MONTH)
            FROM Account
            WHERE Type = :COMM_DO_Account.TYPE_PARTNER
            LIMIT 1
        ];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAccountsAndInvoicesByIdsAndDateLiteral(
            new Set<Id>{ expectedList[0].Id },
            'CreatedDate = THIS_MONTH'
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
        Assert.areEqual(
            expectedList[0].SubscriptionInvoices__r.size(),
            actualList[0].SubscriptionInvoices__r.size(),
            'number of invoices does not match expected'
        );
    }

    /**
     * @description Test COMM_REP_Account.getAccountsByIdsWithInvoicesAndCreditMemos.
     */
    @isTest
    static void getAccountsByIdsWithInvoicesAndCreditMemosTest() {
        List<Account> expectedList = [
            SELECT Id, (SELECT Id FROM Invoices WHERE CreatedDate = THIS_MONTH), (SELECT Id FROM CreditMemos WHERE CreatedDate = THIS_MONTH)
            FROM Account
            WHERE COMM_IsAffiliate__c = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAccountsByIdsWithInvoicesAndCreditMemos(
            new Set<Id>{ expectedList[0].Id },
            'CreatedDate = THIS_MONTH'
        );
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
        Assert.areEqual(expectedList[0].Invoices.size(), actualList[0].Invoices.size(), 'number of invoices does not match expected');
        Assert.areEqual(expectedList[0].CreditMemos.size(), actualList[0].CreditMemos.size(), 'number of Credit Memos does not match expected');
    }

    /**
     * @description Test COMM_REP_Account.getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteral.
     */
    @IsTest
    @suppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    static void getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteralTest() {
        List<Account> expectedList = [
            SELECT Id, (SELECT Id FROM SubscriptionInvoices__r WHERE CreatedDate = THIS_MONTH)
            FROM Account
            WHERE COMM_IsAffiliate__c = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteral('THIS_MONTH');
        Test.stopTest();
        System.assertEquals(actualList.size(), expectedList.size(), 'Number of Accounts should be ' + expectedList.size());
        System.assert(expectedList.size() > 0, 'Number of Accounts should be greater than 0');
    }

    @isTest
    static void getAccountWithRequestFieldsByIdsTest() {
        List<Account> expectedList = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAccountWithRequestFieldsByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }

    @isTest
    static void getResellerAccountProductsTest() {
        List<Account> expectedList = [
            SELECT Id, COMM_ResellerId__c
            FROM Account
            WHERE COMM_IsReseller__c = TRUE
            LIMIT 1
        ];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getResellerAccountProducts(expectedList[0].COMM_ResellerId__c, 'LIS', 'Parking');
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }

    @isTest
    static void getAccountsAndOrdersByIdsTest() {
        List<Account> expectedList = [SELECT Id, (SELECT Id FROM Orders) FROM Account LIMIT 1];

        Test.startTest();
        List<Account> actualList = ACCOUNT_REP.getAccountsAndOrdersByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Orders.size(), actualList[0].Orders.size(), 'obtained account\'s order number does not match expected');
    }
}