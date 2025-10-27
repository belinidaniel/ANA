/**
 * @author Daniel Reto
 * @description COMM_Async_OrderVoucherIntegrRetry test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      30/10/2024    100           Original version - ECOMM-327
 **/
@isTest
private class COMM_Async_OrderVoucherIntegrRetryTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_OrderSummary ORDERSUMMARY_REP = (COMM_REP_OrderSummary) MOCKS.mock(COMM_REP_OrderSummary.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @testSetup
    static void setup() {
        Id orderId = COMM_OMS_TestDataFactory.createOrderAndRelated();


    }

    @isTest
    private static void executeSuccessTest() {
        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Reseller Order Voucher Integration',
                Class_Name__c = 'COMM_Async_OrderVoucherIntegrRetry',
                Job_Size__c = 100,
                SObject_API_Name__c = 'OrderSummary'
            )
        };

        //Create Mocked JobExecution Record
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].Id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Create Mocked Parameters Record
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OrderVoucherIntegrRetry.PARAMETER_MAX_ATTEMPTS,
                Value__c = '5'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OrderVoucherIntegrRetry.PARAMETER_RETRY_CYCLE,
                Value__c = '1'
            )
        };

        //OrderSummary for Mocking Test
        List<SObjectField> ACCOUNT_FIELDS = new List<SObjectField>{ Account.COMM_ResellerId__c };
        String queryOrderSummary = new FW_QueryBuilder(OrderSummary.sObjectType)
            .selectFields(COMM_REP_OrderSummary.ORDERSUMMARY_FIELDS)
            .selectParentFields(OrderSummary.AccountId, ACCOUNT_FIELDS)
            .getQuery();

        DateTime resellerVoucherStatusDate = Datetime.now().addHours(-1);
        List<OrderSummary> orderSummaryRecordList = (List<OrderSummary>) Database.query(queryOrderSummary);
        for(OrderSummary orderSummaryRecord : orderSummaryRecordList){
            orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.ERROR_RESELLER_VOUCHER_STATUS;
            orderSummaryRecord.COMM_ResellerVoucherStatusDate__c = resellerVoucherStatusDate;
        }

        //Expected OrderSummary for Mocking Test
        List<OrderSummary> expectedOrderSummaryRecordList = (List<OrderSummary>) Database.query(queryOrderSummary);
        for(OrderSummary orderSummaryRecord : orderSummaryRecordList){
            orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.SENT_RESELLER_VOUCHER_STATUS;
            orderSummaryRecord.COMM_ResellerVoucherStatusDate__c = resellerVoucherStatusDate;
        }

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ORDERSUMMARY_REP.updateSObjects(expectedOrderSummaryRecordList)).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_OrderVoucherIntegrRetry newBatchRun = new COMM_Async_OrderVoucherIntegrRetry();
            newBatchRun = new COMM_Async_OrderVoucherIntegrRetry(ORDERSUMMARY_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, orderSummaryRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'User Obfuscated and Account deleted');
    }

    @isTest
    private static void executeSuccessOutOfMaxTimeTest() {
        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'Reseller Order Voucher Integration',
                Class_Name__c = 'COMM_Async_OrderVoucherIntegrRetry',
                Job_Size__c = 100,
                SObject_API_Name__c = 'OrderSummary'
            )
        };

        //Create Mocked JobExecution Record
        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].Id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        //Create Mocked Parameters Record
        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OrderVoucherIntegrRetry.PARAMETER_MAX_ATTEMPTS,
                Value__c = '5'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OrderVoucherIntegrRetry.PARAMETER_RETRY_CYCLE,
                Value__c = '1'
            )
        };

        //OrderSummary for Mocking Test
        List<SObjectField> ACCOUNT_FIELDS = new List<SObjectField>{ Account.COMM_ResellerId__c };
        String queryOrderSummary = new FW_QueryBuilder(OrderSummary.sObjectType)
            .selectFields(COMM_REP_OrderSummary.ORDERSUMMARY_FIELDS)
            .selectParentFields(OrderSummary.AccountId, ACCOUNT_FIELDS)
            .getQuery();

        DateTime resellerVoucherStatusDate = Datetime.now().addHours(-10);
        List<OrderSummary> orderSummaryRecordList = (List<OrderSummary>) Database.query(queryOrderSummary);
        for(OrderSummary orderSummaryRecord : orderSummaryRecordList){
            orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.ERROR_RESELLER_VOUCHER_STATUS;
            orderSummaryRecord.COMM_ResellerVoucherStatusDate__c = resellerVoucherStatusDate;
        }

        //Expected OrderSummary for Mocking Test
        List<OrderSummary> expectedOrderSummaryRecordList = (List<OrderSummary>) Database.query(queryOrderSummary);
        for(OrderSummary orderSummaryRecord : orderSummaryRecordList){
            orderSummaryRecord.COMM_ResellerVoucherStatus__c = COMM_DO_OrderSummary.RETRY_EXHAUSTED_RESELLER_VOUCHER_STATUS;
            orderSummaryRecord.COMM_ResellerVoucherStatusDate__c = resellerVoucherStatusDate;
        }

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ORDERSUMMARY_REP.updateSObjects(expectedOrderSummaryRecordList)).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_OrderVoucherIntegrRetry newBatchRun = new COMM_Async_OrderVoucherIntegrRetry();
            newBatchRun = new COMM_Async_OrderVoucherIntegrRetry(ORDERSUMMARY_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, orderSummaryRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'User Obfuscated and Account deleted');
    }
}