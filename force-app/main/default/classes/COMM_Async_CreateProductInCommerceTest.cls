/**
 * @author Carlos Fusco
 * @description COMM_Async_CreateProductInCommerce test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Coverage(%)             Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/02/2024           100                 Original version
 **/
@isTest
private class COMM_Async_CreateProductInCommerceTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_ISObjectRep SOBJECT_REP = (FW_SObjectRep) MOCKS.mock(FW_SObjectRep.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);
    private final static String PRODUCT_AVAILABLE_IN_COMMERCE = 'eCommerce';

    /**
     * @description Mock class for HTTP Callouts
     */
    public class RestServiceResponseMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('Success');
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    private static void createProductInCommerceBatchExecuteTest() {
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'AsyncCreateProductInCommerce',
                Class_Name__c = 'COMM_Async_CreateProductInCommerce',
                Job_Size__c = 100,
                SObject_API_Name__c = 'Product2'
            )
        };

        Map<String, Object> integrationRequestBody = new Map<String, Object>{ 'id' => 'PARK-LC-00001', 'name' => 'Low Cost Parking' };

        Product2 newProduct = new Product2();
        newProduct.Id = fflib_IDGenerator.generate(Product2.sobjectType);
        newProduct.isActive = true;
        newProduct.COMM_WhereProductAvailable__c = PRODUCT_AVAILABLE_IN_COMMERCE;
        newProduct.Name = 'Low Cost Parking';
        newProduct.ProductCode = 'PARK-LC-00001';
        newProduct.COMM_IntegrationRequestBody__c = JSON.serialize(integrationRequestBody);

        List<Job_Execution__c> jobExecutionList = new List<Job_Execution__c>{
            new Job_Execution__c(
                Id = fflib_IDGenerator.generate(Job_Execution__c.sObjectType),
                Batch_Definition__c = batchDefinitionList[0].id,
                Run_With_Defaults__c = true,
                Status__c = FW_DO_JobExecution.JOB_EXEC_STATUS_NEW
            )
        };

        List<Parameters__c> parametersList = new List<Parameters__c>{
            new Parameters__c(Id = fflib_IDGenerator.generate(Parameters__c.sObjectType), Name = FW_AsyncHandler.DEFAULT_PARAMETER),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_CreateProductInCommerce.PARAMETER_AVAILABILITY,
                Value__c = 'Availability'
            )
        };

        MOCKS.startStubbing();
        MOCKS.when(SOBJECT_REP.updateSObjects((List<SObject>) fflib_Match.anyList())).thenReturn(new List<Database.SaveResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        Boolean errorOccured = false;

        try {
            Test.setMock(HttpCalloutMock.class, new RestServiceResponseMock());

            COMM_Async_CreateProductInCommerce newBatchRun = new COMM_Async_CreateProductInCommerce();
            newBatchRun = new COMM_Async_CreateProductInCommerce(SOBJECT_REP, JOB_EXECUTION_REP, PARAMETERS_REP);
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);

            Test.startTest();
            newBatchRun.execute(null, new List<Product2>{ newProduct });
            Test.stopTest();
        } catch (Exception e) {
            errorOccured = true;
        }

        ((FW_IREP_JobExecution) mocks.verify(JOB_EXECUTION_REP, 1)).getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject());
        ((FW_ISObjectRep) mocks.verify(SOBJECT_REP, 1)).updateSObjects(new List<Product2>());
        Assert.isFalse(errorOccured, 'No error expected');
    }
}