/**
 * @author         Rui Salgado
 * @description    COMM_Async_OMSFinancialDocRetry test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      17/05/2024      89             Original version
 **/
@isTest
private class COMM_Async_OMSFinancialDocRetryTest {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution jobExecutionRep = (FW_REP_JobExecution) mocks.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters parameterRep = (FW_REP_Parameters) mocks.mock(FW_REP_Parameters.class);
    private final static FW_IAsync asynHandler = (FW_AsyncHandler) mocks.mock(FW_AsyncHandler.class);
    private final static COMM_IREP_ProcessExceptions PE_REP = (COMM_REP_ProcessExceptions) mocks.mock(COMM_REP_ProcessExceptions.class);

    public class HttpResponseWithErrorsMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            // Prepare responseBody mock
            COMM_SL_SAPDocumentResponse sapResp = new COMM_SL_SAPDocumentResponse();
            sapResp.documentId = null;
            sapResp.resultCode = 'FAIL';
            sapResp.resultDesc = 'Failed to process request';
            String responseBody = JSON.serialize(sapResp);

            // set response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    private static void executeSuccessTestNightMode() {
        // Initialize framework
        //Create Batch_Definition
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'OMS SAP Financial Doc Retry',
                Class_Name__c = 'COMM_Async_OMSFinancialDocRetry',
                Job_Size__c = 10,
                SObject_API_Name__c = 'ProcessException'
            )
        };

        //Create Parameters
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = 'Mode', Value__c = 'Night')
        };

        //Create JobExecution
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        List<Job_Execution__c> jobExecutionList2 = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_SCHEDULED
            )
        };
        List<ProcessException> listProcessException = createData();

        mocks.startStubbing();
        mocks.when(jobExecutionRep.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(jobExecutionRep.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(parameterRep.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        mocks.when(PE_REP.getInvoiceCreditMemo(fflib_match.anyString(), (List<String>) fflib_match.anyList())).thenReturn(listProcessException);
        mocks.stopStubbing();

        Test.setMock(HttpCalloutMock.class, new HttpResponseWithErrorsMock());
        COMM_Async_OMSFinancialDocRetry newBatchRun = new COMM_Async_OMSFinancialDocRetry(PE_REP, jobExecutionRep, parameterRep);

        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);

        ((FW_IREP_JobExecution) mocks.verify(jobExecutionRep, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_IREP_Parameters) mocks.verify(parameterRep, 1)).getParametersByParentId((Set<Id>) fflib_match.anyObject());
    }

    @isTest
    private static void executeSuccessTestCyclicMode() {
        // Initialize framework
        //Create Batch_Definition
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'OMS SAP Financial Doc Retry',
                Class_Name__c = 'COMM_Async_OMSFinancialDocRetry',
                Job_Size__c = 10,
                SObject_API_Name__c = 'ProcessException'
            )
        };

        //Create Parameters
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = 'Mode', Value__c = null)
        };

        //Create JobExecution
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        List<Job_Execution__c> jobExecutionList2 = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList.get(0).id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_SCHEDULED
            )
        };

        List<ProcessException> listProcessException = createData();

        mocks.startStubbing();
        mocks.when(jobExecutionRep.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(jobExecutionRep.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        mocks.when(parameterRep.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        mocks.when(PE_REP.getInvoiceCreditMemo(fflib_match.anyString(), (List<String>) fflib_match.anyList())).thenReturn(listProcessException);
        mocks.stopStubbing();

        Test.setMock(HttpCalloutMock.class, new HttpResponseWithErrorsMock());
        COMM_Async_OMSFinancialDocRetry newBatchRun = new COMM_Async_OMSFinancialDocRetry(PE_REP, jobExecutionRep, parameterRep);

        Database.executeBatch(newBatchRun);
        newBatchRun.setAsyncApexJobId(null);

        ((FW_IREP_JobExecution) mocks.verify(jobExecutionRep, 1)).getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject());
        ((FW_IREP_Parameters) mocks.verify(parameterRep, 1)).getParametersByParentId((Set<Id>) fflib_match.anyObject());
    }

    private static List<ProcessException> createData() {
        Invoice inv = (Invoice) fflib_ApexMocksUtils.setReadOnlyFields(
            new Invoice(),
            Invoice.class,
            new Map<SObjectField, Object>{
                Invoice.Id => fflib_IDGenerator.generate(Invoice.sObjectType),
                Invoice.COMM_SAPCount__c => 0,
                Invoice.COMM_SAPDocumentId__c => '',
                Invoice.Status => 'Posted',
                Invoice.DueDate => '2024-05-17',
                Invoice.InvoiceDate => '2024-05-17',
                Invoice.DocumentNumber => 'Test-00001',
                Invoice.Balance => 0.00
            }
        );

        CreditMemo cm = (CreditMemo) fflib_ApexMocksUtils.setReadOnlyFields(
            new CreditMemo(),
            CreditMemo.class,
            new Map<SObjectField, Object>{
                CreditMemo.Id => fflib_IDGenerator.generate(CreditMemo.sObjectType),
                CreditMemo.COMM_SAPCount__c => 0,
                CreditMemo.COMM_SAPDocumentId__c => '',
                CreditMemo.Status => 'Posted',
                CreditMemo.CreditDate => '2024-05-17',
                CreditMemo.DocumentNumber => 'Test-00001',
                CreditMemo.Balance => 0.00
            }
        );

        ProcessException mockedPEInvoice = (ProcessException) fflib_ApexMocksUtils.setReadOnlyFields(
            new ProcessException(),
            ProcessException.class,
            new Map<SObjectField, Object>{
                ProcessException.Id => fflib_IDGenerator.generate(ProcessException.SObjectType),
                ProcessException.Category => COMM_DO_ProcessExceptions.SAP_CATEGORY,
                ProcessException.Severity => COMM_DO_ProcessExceptions.SEV_HIGH,
                ProcessException.Priority => COMM_DO_ProcessExceptions.PRIO_HIGH,
                ProcessException.AttachedToId => inv.Id,
                ProcessException.Message => 'Test error',
                ProcessException.Description => 'Test description',
                ProcessException.Status => COMM_DO_ProcessExceptions.NEW_S
            }
        );

        ProcessException mockedPECreditMemo = (ProcessException) fflib_ApexMocksUtils.setReadOnlyFields(
            new ProcessException(),
            ProcessException.class,
            new Map<SObjectField, Object>{
                ProcessException.Id => fflib_IDGenerator.generate(ProcessException.SObjectType),
                ProcessException.Category => COMM_DO_ProcessExceptions.SAP_CATEGORY,
                ProcessException.Severity => COMM_DO_ProcessExceptions.SEV_HIGH,
                ProcessException.Priority => COMM_DO_ProcessExceptions.PRIO_HIGH,
                ProcessException.AttachedToId => cm.Id,
                ProcessException.Message => 'Test error',
                ProcessException.Description => 'Test description',
                ProcessException.Status => COMM_DO_ProcessExceptions.NEW_S
            }
        );

        // credit memo Process exception twice to check for  duplicates
        return new List<ProcessException>{ mockedPEInvoice, mockedPECreditMemo, mockedPECreditMemo };
    }
}