/**
 * @author Daniel Reto
 * @description COMM_Async_OrdItemSumOCICreateStock test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)     Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      18/07/2024      95             Original version
 **/
@isTest
private class COMM_Async_OrdItemSumOCICreateStockTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_OrderItemSummary ORDERITEMSUMMARY_REP = (COMM_REP_OrderItemSummary) MOCKS.mock(COMM_REP_OrderItemSummary.class);
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void executeSuccessTest() {
        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'OrderItemSummary Create Stock On New Environment',
                Class_Name__c = 'COMM_Async_OrdItemSumOCICreateStock',
                Job_Size__c = 100,
                SObject_API_Name__c = 'OrderItemSummary'
            )
        };

        //Products for Mocking Test
        Id parentProductId = fflib_IDGenerator.generate(Product2.SObjectType);
        Id childProductId = fflib_IDGenerator.generate(Product2.SObjectType);
        List<Product2> productRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => childProductId,
                'COMM_ParentProduct__c' => parentProductId,
                'ProductCode' => 'T-0-12',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );
        List<Product2> parentProductRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => parentProductId,
                'ProductCode' => 'T-0',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        //OrderItemSummary for Mocking Test
        Id orderItemSummaryId = fflib_IDGenerator.generate(OrderItemSummary.SObjectType);
        List<OrderItemSummary> orderItemSummaryRecordList = (List<OrderItemSummary>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'OrderItemSummary',
            new Map<String, Object>{
                'Id' => orderItemSummaryId,
                'COMM_ReservationEnd__c' => Datetime.now().addDays(1),
                'COMM_ReservationStart__c' => Datetime.now(),
                'COMM_SetupInitialStock__c' => 'TO PROCESS'
            }
        );
        orderItemSummaryRecordList[0].Product2 = productRecordList[0];

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
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER)
        };

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(ORDERITEMSUMMARY_REP.updateSObjects(orderItemSummaryRecordList)).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_OrdItemSumOCICreateStock newBatchRun = new COMM_Async_OrdItemSumOCICreateStock();
            newBatchRun = new COMM_Async_OrdItemSumOCICreateStock(ORDERITEMSUMMARY_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, orderItemSummaryRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();
        ((COMM_IREP_OrderItemSummary) mocks.verify(ORDERITEMSUMMARY_REP, 1)).updateSObjects(orderItemSummaryRecordList);
        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}