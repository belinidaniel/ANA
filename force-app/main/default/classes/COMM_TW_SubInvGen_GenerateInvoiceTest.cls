/**
 * @author Daniel Lascas
 * @description COMM_TW_SubInvGen_GenerateInvoice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    01/04/2024      100            ECOMM-194: Original version
 * Daniel Reto      03/05/2024		100            ECOMM-1027
 **/
@isTest
private class COMM_TW_SubInvGen_GenerateInvoiceTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_Case CASE_REP = (COMM_REP_Case) MOCKS.mock(COMM_REP_Case.class);
    private final static COMM_IREP_Subscription SUBSCRIPTION_REP = (COMM_REP_Subscription) MOCKS.mock(COMM_REP_Subscription.class);
    private final static COMM_IREP_SubscriptionInvoice SUBSCRIPTION_INVOICE_REP = (COMM_REP_SubscriptionInvoice) MOCKS.mock(
        COMM_REP_SubscriptionInvoice.class
    );
    private final static Id CASE_NEW_SUB_RT = SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get(COMM_DO_Case.SUBSCRIPTION_REQUEST_RT)
        .getRecordTypeId();

    @isTest
    static void invoiceGenerationSuccessWithCaseIdTest() {
        //Scenario: A Case to start a new Subscription was concluded.
        //Expected: A Subscription Invoice Record is generated.

        //Mock Case
        List<Case> caseList = (List<Case>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Case.sObjectType),
                'AccountId' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.sObjectType),
                'COMM_Subscription__c' => fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType),
                'ProductId' => fflib_IDGenerator.generate(Product2.sObjectType),
                'COMM_NewCardRequest__c' => true,
                'COMM_CardPrice__c' => 5.00,
                'COMM_SubscriptionPrice__c' => 100.00,
                'RecordTypeId' => CASE_NEW_SUB_RT
            }
        );
        caseList[0].RecordType = new RecordType(Id = CASE_NEW_SUB_RT, DeveloperName = COMM_DO_Case.SUBSCRIPTION_REQUEST_RT);

        caseList[0].COMM_Subscription__r = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{ 'Id' => caseList[0].COMM_Subscription__c, 'COMM_Price__c' => 100.00 }
        )[0];

        //Mock Platform Event that started logic
        List<COMM_SubscriptionInvoiceGenerator__e> pEventList = (List<COMM_SubscriptionInvoiceGenerator__e>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_SubscriptionInvoiceGenerator__e',
            new Map<String, Object>{ 'COMM_CaseId__c' => caseList[0].Id }
        );

        //Expected invoice to be generated
        COMM_SubscriptionInvoice__c expectedInvoice = new COMM_SubscriptionInvoice__c();
        expectedInvoice.COMM_Status__c = COMM_DO_SubscriptionInvoice.PENDING_STATUS;
        expectedInvoice.COMM_SubscriptonRequest__c = caseList[0].Id;
        expectedInvoice.COMM_Account__c = caseList[0].AccountId;
        expectedInvoice.COMM_CardProduct__c = caseList[0].COMM_Card__c;
        expectedInvoice.COMM_Subscripton__c = caseList[0].COMM_Subscription__c;
        expectedInvoice.COMM_SubscriptonProduct__c = caseList[0].ProductId;
        expectedInvoice.COMM_SubscriptionAmount__c = caseList[0].COMM_SubscriptionPrice__c;
        expectedInvoice.COMM_CardAmount__c = caseList[0].COMM_CardPrice__c;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(CASE_REP.getSubscriptionCaseByIds((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(caseList);
        MOCKS.when(SUBSCRIPTION_INVOICE_REP.insertSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_SubInvGen_GenerateInvoice worker = new COMM_TW_SubInvGen_GenerateInvoice();
        worker = new COMM_TW_SubInvGen_GenerateInvoice(CASE_REP, SUBSCRIPTION_REP, SUBSCRIPTION_INVOICE_REP);
        worker.execute(pEventList);
        Test.stopTest();

        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];

        //Verify Results
        ((COMM_IREP_SubscriptionInvoice) mocks.verify(SUBSCRIPTION_INVOICE_REP, 1))
            .insertSObjects(new List<COMM_SubscriptionInvoice__c>{ expectedInvoice });
        Assert.isTrue(errorList.isEmpty(), 'expected no error logs to have been created');
    }

    @isTest
    static void invoiceGenerationSuccessWithSubscriptionIdTest() {
        //Scenario: A automatic renewal Subscription was renewed.
        //Expected: A Subscription Invoice Record is generated.

        //Subscription for Mocking Test
        List<COMM_Subscription__c> subscriptionRecordList = (List<COMM_Subscription__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.SObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.SObjectType),
                'COMM_Active__c' => true,
                'COMM_AutomaticRenewal__c' => true,
                'COMM_CancellationDate__c' => Date.today(),
                'COMM_CarBrand__c' => 'Mazda',
                'COMM_CarModel__c' => 'Standard 2.0',
                'COMM_Card__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'COMM_Contact__c' => fflib_IDGenerator.generate(Contact.SObjectType),
                'COMM_Email__c' => 'test@test.com.invalid',
                'COMM_EndDate__c' => Date.today().addYears(1),
                'COMM_FirstName__c' => 'Test',
                'COMM_InitialSubscriptionMonth__c' => 'December',
                'COMM_LastName__c' => 'Subscription',
                'COMM_LicensePlate__c' => 'AS.54.AS',
                'COMM_OCIEndDate__c' => Date.today().addYears(1),
                'COMM_Periodicity__c' => COMM_DO_Subscription.PERIODICITY_YEARLY,
                'COMM_PhoneNumber__c' => '+351911911911',
                'COMM_Price__c' => 100,
                'COMM_Product__c' => fflib_IDGenerator.generate(Product2.SObjectType),
                'RecordTypeId' => Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
                    .get(COMM_DO_Subscription.RECORDTYPE_PARTNER)
                    .RecordTypeId,
                'COMM_StartDate__c' => Date.newInstance(Date.today().year(), 12, Date.today().day()).addYears(-1),
                'COMM_Status__c' => COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED,
                'COMM_SubscriptionNumber__c' => '522200',
                'COMM_VATNumber__c' => '321654321'
            }
        );

        //Mock Platform Event that started logic
        List<COMM_SubscriptionInvoiceGenerator__e> pEventList = (List<COMM_SubscriptionInvoiceGenerator__e>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_SubscriptionInvoiceGenerator__e',
            new Map<String, Object>{ 'COMM_SubscriptionId__c' => subscriptionRecordList[0].Id }
        );

        //Expected invoice to be generated
        COMM_SubscriptionInvoice__c expectedInvoice = new COMM_SubscriptionInvoice__c();
        expectedInvoice.COMM_Status__c = COMM_DO_SubscriptionInvoice.PENDING_STATUS;
        expectedInvoice.COMM_Account__c = subscriptionRecordList[0].COMM_Account__c;
        expectedInvoice.COMM_Subscripton__c = subscriptionRecordList[0].Id;
        expectedInvoice.COMM_SubscriptonProduct__c = subscriptionRecordList[0].COMM_Product__c;
        expectedInvoice.COMM_SubscriptionAmount__c = subscriptionRecordList[0].COMM_Price__c;

        //Mocks Queries
        MOCKS.startStubbing();
        MOCKS.when(SUBSCRIPTION_REP.getSubscriptionsByIds((Set<Id>) fflib_Match.anyObject())).thenReturn(subscriptionRecordList);
        MOCKS.when(SUBSCRIPTION_INVOICE_REP.insertSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        Test.startTest();
        COMM_TW_SubInvGen_GenerateInvoice worker = new COMM_TW_SubInvGen_GenerateInvoice();
        worker = new COMM_TW_SubInvGen_GenerateInvoice(CASE_REP, SUBSCRIPTION_REP, SUBSCRIPTION_INVOICE_REP);
        worker.execute(pEventList);
        Test.stopTest();

        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];

        //Verify Results
        ((COMM_IREP_SubscriptionInvoice) mocks.verify(SUBSCRIPTION_INVOICE_REP, 1))
            .insertSObjects(new List<COMM_SubscriptionInvoice__c>{ expectedInvoice });
        Assert.isTrue(errorList.isEmpty(), 'expected no error logs to have been created');
    }
}