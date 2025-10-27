/**
 * @author Daniel Lascas
 * @description COMM_Async_SAPSendSubInvoice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_Async_SAPSendSubInvoiceTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);
    private final static COMM_IREP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_IREP_SubscriptionInvoice INVOICE_REP = (COMM_REP_SubscriptionInvoice) MOCKS.mock(COMM_REP_SubscriptionInvoice.class);
    private final static COMM_IREP_MonthlyFiscalDocumentControl FISCAL_CONTROL_REP = (COMM_REP_MonthlyFiscalDocumentControl) MOCKS.mock(
        COMM_REP_MonthlyFiscalDocumentControl.class
    );
    private final static COMM_SL_SAPFinancialDocument DOCUMENT_SL = (COMM_SL_SAPFinancialDocument) MOCKS.mock(COMM_SL_SAPFinancialDocument.class);

    @isTest
    static void generateInvoiceBatchStartTest() {
        //Scenario: Batch to generate invoice in SAP for current month is initiated. Mock is used for DML insert.
        //Expected: A Control Record is inserted. Since Mock is used execute method is skipped (tested in another).

        //Create Mocked Records for Framework Batch Execution Logic
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'SendSAPSubscriptionInvoice',
                Class_Name__c = 'COMM_Async_SAPSendSubInvoice',
                Job_Size__c = 1,
                SObject_API_Name__c = 'Account'
            )
        };
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Generate mocked Business Account
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'Name' => 'Test Client',
                'COMM_Email__c' => 'testclient@test.invalid'
            }
        )[0];
        testAccount = (Account) COMM_TestDataFactory.setField(testAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SAPSendSubInvoice.PARAMETER_DATECLAUSE,
                Value__c = 'CreatedDate = LAST_MONTH'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SAPSendSubInvoice.PARAMETER_MAXRETRIES,
                Value__c = '5'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SAPSendSubInvoice.PARAMETER_RETRY_ONLY,
                Value__c = 'false'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SAPSendSubInvoice.PARAMETER_PAYMENT_DAYS,
                Value__c = '23'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_SAPSendSubInvoice.PARAMETER_ACCOUNT_LIST,
                Value__c = testAccount.Id
            )
        };

        //Generate mocked Subscription Invoice set to a month ago
        COMM_SubscriptionInvoice__c mockedInvoice = new COMM_SubscriptionInvoice__c(
            Id = fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.SObjectType)
        );
        mockedInvoice = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            mockedInvoice,
            new Map<String, Object>{ 'CreatedDate' => System.now().addMonths(-1) }
        );

        //Generate Mocked Subscription Invoice Records and create relation with mocked business account
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ testAccount },
            COMM_SubscriptionInvoice__c.COMM_Account__c,
            new List<List<COMM_SubscriptionInvoice__c>>{ new List<COMM_SubscriptionInvoice__c>{ mockedInvoice } }
        );

        //Expected Fiscal Control Insert Call
        List<COMM_MonthlyFiscalDocumentControl__c> expectedInsertList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        COMM_MonthlyFiscalDocumentControl__c controlRecord = new COMM_MonthlyFiscalDocumentControl__c();
        controlRecord.COMM_Account__c = accountList[0].Id;
        controlRecord.COMM_Type__c = COMM_DO_MonthlyFiscalDocumentControl.SUBSCRIPTION_TYPE;
        controlRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS;
        controlRecord.COMM_RetryCounter__c = 0;
        controlRecord.COMM_DocumentMonth__c = System.now().addMonths(-1).month();
        controlRecord.COMM_DocumentYear__c = System.now().addMonths(-1).year();
        expectedInsertList.add(controlRecord);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getPartnerAccountsAndInvoicesByDateLiteral((Set<String>) fflib_match.anyObject(), fflib_match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(FISCAL_CONTROL_REP.insertSObjects((List<COMM_MonthlyFiscalDocumentControl__c>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.when(INVOICE_REP.updateSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        COMM_Async_SAPSendSubInvoice newBatchRun = new COMM_Async_SAPSendSubInvoice();
        newBatchRun = new COMM_Async_SAPSendSubInvoice(JOB_EXECUTION_REP, PARAMETERS_REP, ACCOUNT_REP, INVOICE_REP, FISCAL_CONTROL_REP, DOCUMENT_SL);
        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);
        Test.stopTest();

        //Check for created Error Logs
        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];

        //Verify Results
        ((COMM_IREP_Account) mocks.verify(ACCOUNT_REP, 1))
            .getPartnerAccountsAndInvoicesByDateLiteral(new Set<String>{ testAccount.Id }, parametersList[1].Value__c);
        ((COMM_IREP_MonthlyFiscalDocumentControl) mocks.verify(FISCAL_CONTROL_REP, 1)).insertSObjects(expectedInsertList);
        Assert.isTrue(errorList.isEmpty(), 'expected no errors to have been logged');
    }

    @isTest
    private static void generateInvoiceBatchExecuteTest() {
        //Scenario: Batch to generate invoice in SAP for current month is initiated. SAP responds with success.
        //Expected: Invoice are updated with Number obtained from SAP (mocked) and control record with success status.

        //Generate mocked Business Account
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'Name' => 'Test Client',
                'COMM_Email__c' => 'testclient@test.invalid'
            }
        )[0];
        testAccount = (Account) COMM_TestDataFactory.setField(testAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        //Generate mocked Subscription Invoice set to a month ago
        COMM_SubscriptionInvoice__c mockedInvoice = new COMM_SubscriptionInvoice__c(
            Id = fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.SObjectType)
        );
        mockedInvoice = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            mockedInvoice,
            new Map<String, Object>{ 'CreatedDate' => System.now().addMonths(-1), 'COMM_ExemptPayment__c' => false }
        );

        //Generate Mocked Subscription Invoice Records and create relation with mocked business account
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ testAccount },
            COMM_SubscriptionInvoice__c.COMM_Account__c,
            new List<List<COMM_SubscriptionInvoice__c>>{ new List<COMM_SubscriptionInvoice__c>{ mockedInvoice } }
        );

        //Mocked Existing Fiscal Control Records
        List<COMM_MonthlyFiscalDocumentControl__c> controllerList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        COMM_MonthlyFiscalDocumentControl__c mockControlRecord = new COMM_MonthlyFiscalDocumentControl__c();
        mockControlRecord.Id = fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.SObjectType);
        mockControlRecord.COMM_Account__c = accountList[0].Id;
        mockControlRecord.COMM_Type__c = COMM_DO_MonthlyFiscalDocumentControl.SUBSCRIPTION_TYPE;
        mockControlRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS;
        mockControlRecord.COMM_RetryCounter__c = 0;
        mockControlRecord.COMM_DocumentMonth__c = Date.today().addMonths(-1).toStartOfMonth().month();
        mockControlRecord.COMM_DocumentYear__c = Date.today().addMonths(-1).toStartOfMonth().year();
        controllerList.add(mockControlRecord);

        //Mocked SAP response
        COMM_SL_SAPDocumentResponse sapResponse = new COMM_SL_SAPDocumentResponse();
        sapResponse.documentId = '124987000';
        sapResponse.resultCode = '200';
        sapResponse.resultDesc = 'Doc Generated';

        //Expected Invoice Update Call
        List<COMM_SubscriptionInvoice__c> expectedUpdateList = new List<COMM_SubscriptionInvoice__c>();
        COMM_SubscriptionInvoice__c invoiceUpdate = new COMM_SubscriptionInvoice__c();
        invoiceUpdate.Id = accountList[0].SubscriptionInvoices__r[0].Id;
        invoiceUpdate.COMM_IssuanceDate__c = System.today();
        invoiceUpdate.COMM_SAPNumber__c = sapResponse.documentId;
        invoiceUpdate.COMM_Status__c = COMM_DO_SubscriptionInvoice.GENERATED_STATUS;
        invoiceUpdate.COMM_ExemptPayment__c = false;
        expectedUpdateList.add(invoiceUpdate);

        //Expected Fiscal Control Update Call
        List<COMM_MonthlyFiscalDocumentControl__c> expectedControlUpdateList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        COMM_MonthlyFiscalDocumentControl__c controlRecord = mockControlRecord.clone(true);
        controlRecord.COMM_SAPDocumentId__c = sapResponse.documentId;
        controlRecord.COMM_StatusMessage__c = sapResponse.resultCode + ': ' + sapResponse.resultDesc;
        controlRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.PROCESSED_STATUS;
        controlRecord.COMM_RetryCounter__c = 0;
        expectedControlUpdateList.add(controlRecord);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getAccountsAndInvoicesByIdsAndDateLiteral((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(
                DOCUMENT_SL.createFinancialDocument(
                    fflib_Match.anyString(),
                    (COMM_MonthlyFiscalDocumentControl__c) fflib_Match.anySObject(),
                    (Account) fflib_Match.anySObject(),
                    fflib_Match.anyDate(),
                    fflib_Match.anyInteger(),
                    (List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList()
                )
            )
            .thenReturn(sapResponse);
        MOCKS.when(INVOICE_REP.updateSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(FISCAL_CONTROL_REP.updateSObjects((List<COMM_MonthlyFiscalDocumentControl__c>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        COMM_Async_SAPSendSubInvoice newBatchRun = new COMM_Async_SAPSendSubInvoice();
        newBatchRun = new COMM_Async_SAPSendSubInvoice(JOB_EXECUTION_REP, PARAMETERS_REP, ACCOUNT_REP, INVOICE_REP, FISCAL_CONTROL_REP, DOCUMENT_SL);
        newBatchRun.paymentDays = 23;
        newBatchRun.execute(null, controllerList);
        Test.stopTest();

        //Check for created Error Logs
        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];

        //Verify Results
        ((COMM_IREP_SubscriptionInvoice) mocks.verify(INVOICE_REP, 1)).updateSObjects(expectedUpdateList);
        ((COMM_IREP_MonthlyFiscalDocumentControl) mocks.verify(FISCAL_CONTROL_REP, 1)).updateSObjects(expectedControlUpdateList);
        Assert.isTrue(errorList.isEmpty(), 'expected no errors to have been logged');
    }

    @isTest
    private static void generateInvoiceSAPErrorTest() {
        //Scenario: Batch to generate invoice in SAP for current month is initiated. SAP returns an error.
        //Expected: No invoices are updated. Controller is updated to error status with sap error message.

        //Generate mocked Business Account
        Account testAccount = (Account) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Account',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Account.sObjectType),
                'Name' => 'Test Client',
                'COMM_Email__c' => 'testclient@test.invalid'
            }
        )[0];
        testAccount = (Account) COMM_TestDataFactory.setField(testAccount, new Map<String, Object>{ 'IsPersonAccount' => false });

        //Generate mocked Subscription Invoice set to a month ago
        COMM_SubscriptionInvoice__c mockedInvoice = new COMM_SubscriptionInvoice__c(
            Id = fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.SObjectType)
        );
        mockedInvoice = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            mockedInvoice,
            new Map<String, Object>{ 'CreatedDate' => System.now().addMonths(-1) }
        );

        //Generate Mocked Subscription Invoice Records and create relation with mocked business account
        List<Account> accountList = (List<Account>) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ testAccount },
            COMM_SubscriptionInvoice__c.COMM_Account__c,
            new List<List<COMM_SubscriptionInvoice__c>>{ new List<COMM_SubscriptionInvoice__c>{ mockedInvoice } }
        );

        //Mocked Existing Fiscal Control Records
        List<COMM_MonthlyFiscalDocumentControl__c> controllerList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        COMM_MonthlyFiscalDocumentControl__c mockControlRecord = new COMM_MonthlyFiscalDocumentControl__c();
        mockControlRecord.Id = fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.SObjectType);
        mockControlRecord.COMM_Account__c = accountList[0].Id;
        mockControlRecord.COMM_Type__c = COMM_DO_MonthlyFiscalDocumentControl.SUBSCRIPTION_TYPE;
        mockControlRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS;
        mockControlRecord.COMM_RetryCounter__c = 0;
        mockControlRecord.COMM_DocumentMonth__c = Date.today().addMonths(-1).toStartOfMonth().month();
        mockControlRecord.COMM_DocumentYear__c = Date.today().addMonths(-1).toStartOfMonth().year();
        controllerList.add(mockControlRecord);

        //Mocked SAP response
        COMM_SL_SAPDocumentResponse sapResponse = new COMM_SL_SAPDocumentResponse();
        sapResponse.documentId = null;
        sapResponse.resultCode = '400';
        sapResponse.resultDesc = 'Bad Request';

        //Expected Fiscal Control Update Call
        List<COMM_MonthlyFiscalDocumentControl__c> expectedControlUpdateList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        COMM_MonthlyFiscalDocumentControl__c controlRecord = mockControlRecord.clone(true);
        controlRecord.COMM_SAPDocumentId__c = sapResponse.documentId;
        controlRecord.COMM_StatusMessage__c = sapResponse.resultCode + ': ' + sapResponse.resultDesc;
        controlRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS;
        controlRecord.COMM_RetryCounter__c = 1;
        expectedControlUpdateList.add(controlRecord);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ACCOUNT_REP.getAccountsAndInvoicesByIdsAndDateLiteral((Set<Id>) fflib_Match.anyObject(), fflib_Match.anyString()))
            .thenReturn(accountList);
        MOCKS.when(
                DOCUMENT_SL.createFinancialDocument(
                    fflib_Match.anyString(),
                    (COMM_MonthlyFiscalDocumentControl__c) fflib_Match.anySObject(),
                    (Account) fflib_Match.anySObject(),
                    fflib_Match.anyDate(),
                    fflib_Match.anyInteger(),
                    (List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList()
                )
            )
            .thenReturn(sapResponse);
        MOCKS.when(INVOICE_REP.updateSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(FISCAL_CONTROL_REP.updateSObjects((List<COMM_MonthlyFiscalDocumentControl__c>) fflib_Match.anyList()))
            .thenReturn(new List<Database.SaveResult>());
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        COMM_Async_SAPSendSubInvoice newBatchRun = new COMM_Async_SAPSendSubInvoice();
        newBatchRun = new COMM_Async_SAPSendSubInvoice(JOB_EXECUTION_REP, PARAMETERS_REP, ACCOUNT_REP, INVOICE_REP, FISCAL_CONTROL_REP, DOCUMENT_SL);
        newBatchRun.paymentDays = 23;
        newBatchRun.execute(null, controllerList);
        Test.stopTest();

        //Check for created Error Logs
        List<Error_Log__c> errorList = [SELECT Id FROM Error_Log__c];

        //Verify Results
        ((COMM_IREP_SubscriptionInvoice) mocks.verify(INVOICE_REP, 0)).updateSObjects((List<COMM_SubscriptionInvoice__c>) fflib_Match.anyList());
        ((COMM_IREP_MonthlyFiscalDocumentControl) mocks.verify(FISCAL_CONTROL_REP, 1)).updateSObjects(expectedControlUpdateList);
        Assert.isTrue(errorList.isEmpty(), 'expected no errors to have been logged');
    }
}