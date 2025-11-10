/**
 * @author Daniel Reto
 * @description COMM_Async_OCIStockAlarmistic test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)   Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      09/05/2024      98            ECOMM-281: Original version
 **/
@isTest
private class COMM_Async_OCIStockAlarmisticTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IREP_ProductLocationStock PRODUCTLOCATIONSTOCK_REP = (COMM_REP_ProductLocationStock) MOCKS.mock(
        COMM_REP_ProductLocationStock.class
    );
    private final static COMM_IREP_EmailTemplate EMAILTEMPLATE_REP = (COMM_REP_EmailTemplate) MOCKS.mock(COMM_REP_EmailTemplate.class);
    private final static COMM_IREP_OrgWideEmailAddress ORGWIDEADDRESSNOREPLY_REP = (COMM_REP_OrgWideEmailAddress) MOCKS.mock(
        COMM_REP_OrgWideEmailAddress.class
    );
    private final static FW_IREP_JobExecution JOB_EXECUTION_REP = (FW_REP_JobExecution) MOCKS.mock(FW_REP_JobExecution.class);
    private final static FW_IREP_Parameters PARAMETERS_REP = (FW_REP_Parameters) MOCKS.mock(FW_REP_Parameters.class);

    @isTest
    private static void executeSuccessTest() {
        Date endDateValue = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));

        //Create Mocked Batch_Definition Record
        List<Batch_Definition__c> batchDefinitionList = new List<Batch_Definition__c>{
            new Batch_Definition__c(
                Id = fflib_IDGenerator.generate(Batch_Definition__c.sObjectType),
                Batch_Name__c = 'OCI Stock Alarmistic',
                Class_Name__c = 'COMM_Async_OCIStockAlarmistic',
                Job_Size__c = 100,
                SObject_API_Name__c = 'COMM_Capacity__c'
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
                Name = COMM_Async_OCIStockAlarmistic.PARAMETER_NUMBER_OF_DAYS_TO_CHECK_PRIOR,
                Value__c = '0'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OCIStockAlarmistic.PARAMETER_NUMBER_OF_DAYS_TO_CHECK_AFTER,
                Value__c = '5'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OCIStockAlarmistic.PARAMETER_EMAILTEMPLATE,
                Value__c = 'COMM_Internal_CapacityAlarmistic_pt_PT'
            ),
            new Parameters__c(
                Id = fflib_IDGenerator.generate(Parameters__c.sObjectType),
                Name = COMM_Async_OCIStockAlarmistic.PARAMETER_QUEUE,
                Value__c = 'COMM_SubscriptionRequestANAAdmin'
            )
        };

        //Products for Mocking Test
        List<Product2> productRecordList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'T-0',
                'ProductCode' => 'T-0',
                'description' => 'T-0',
                'Family' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'isActive' => false,
                'COMM_Airport__c' => 'OPO',
                'COMM_Alarmistic__c' => 25,
                'COMM_ClosingOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_OpeningOperatingHours__c' => Time.newInstance(0, 0, 0, 0),
                'COMM_ValidFrom__c' => DateTime.now().addDays(1),
                'COMM_ValidTo__c' => DateTime.now().addDays(2),
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_Park__c' => 'P3',
                'COMM_Periodicity__c' => null,
                'COMM_Tax__c' => 'Continent',
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );

        //Capacity for Mocking Test
        List<COMM_Capacity__c> capacityRecordList = (List<COMM_Capacity__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_Capacity__c',
            new Map<String, Object>{
                'COMM_Product__c' => productRecordList[0].Id,
                'COMM_IsDefaultCapacity__c' => true,
                'COMM_ProcessStatus__c' => COMM_DO_Capacity.PROCESS_STATUS_COMPLETED,
                'RecordTypeId' => Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId,
                'COMM_ValidFrom__c' => Datetime.now().addDays(1),
                'COMM_ValidTo__c' => endDateValue.addYears(2),
                'COMM_Capacity__c' => 150
            }
        );
        capacityRecordList[0].COMM_Product__r = productRecordList[0];

        Product2 product = productRecordList[0];
        product.isActive = true;
        upsert product;

        //Expected Records for Mocking Test
        List<EmailTemplate> expectedEmailTemplateRecord = [
            SELECT Id, Name, DeveloperName, Subject, Body
            FROM EmailTemplate
            WHERE Name = 'COMM_Internal_CapacityAlarmistic_pt_PT'
        ];

        List<OrgWideEmailAddress> expectedOrgWideEmailAddressRecord = [SELECT Id FROM OrgWideEmailAddress WHERE Purpose = 'DefaultNoreply'];

        List<COMM_ProductLocationStock__c> expectedProductLocationStockRecordList = (List<COMM_ProductLocationStock__c>) COMM_TestDataFactory.insertRecords(
            5,
            false,
            'COMM_ProductLocationStock__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_ProductLocationStock__c.SObjectType),
                'COMM_Product__c' => productRecordList[0].Id,
                'COMM_ReservedStock__c' => 50,
                'COMM_StockOnHand__c' => 100,
                'COMM_Location__c' => COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION
            }
        );
        Integer count = 0;
        for (COMM_ProductLocationStock__c productLocationStockRecord : expectedProductLocationStockRecordList) {
            if (count == 5) {
                break;
            }
            String dateString = String.valueOf(System.now().addDays(count).formatGMT(COMM_OCI_Constants.DATE_FORMAT));
            productLocationStockRecord.COMM_ProductLocation__c =
                productRecordList[0].ProductCode +
                '_' +
                dateString +
                COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION;
            productLocationStockRecord.COMM_StockDate__c = Date.valueOf(
                dateString.subString(0, 4) + '-' + dateString.subString(4, 6) + '-' + dateString.subString(6, 8)
            );
            count++;
        }
        Formula.recalculateFormulas(expectedProductLocationStockRecordList);

        //Mock Queries
        MOCKS.startStubbing();
        MOCKS.when(PRODUCTLOCATIONSTOCK_REP.getProductLocationStockToErase()).thenReturn(expectedProductLocationStockRecordList);
        MOCKS.when(PRODUCTLOCATIONSTOCK_REP.getProductLocationStockToErase(new List<String>{ productRecordList[0].Id }, System.now().dateGMT()))
            .thenReturn(expectedProductLocationStockRecordList);
        MOCKS.when(ORGWIDEADDRESSNOREPLY_REP.getDefaultNoReplyAddress()).thenReturn(expectedOrgWideEmailAddressRecord);
        MOCKS.when(EMAILTEMPLATE_REP.getEmailTemplateByNames(new Set<String>{ 'COMM_Internal_CapacityAlarmistic_pt_PT' }))
            .thenReturn(expectedEmailTemplateRecord);
        MOCKS.when(PRODUCTLOCATIONSTOCK_REP.deleteSObjects(new List<COMM_ProductLocationStock__c>())).thenReturn(new List<Database.DeleteResult>());
        MOCKS.when(
                PRODUCTLOCATIONSTOCK_REP.upsertSObjects(expectedProductLocationStockRecordList, COMM_ProductLocationStock__c.COMM_ProductLocation__c)
            )
            .thenReturn(new List<Database.UpsertResult>());
        MOCKS.when(JOB_EXECUTION_REP.getJobExecWithBatchDefinitionsByIdSet((Set<Id>) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(JOB_EXECUTION_REP.getJobExecutionByAsyncApexJobIdSet((Id) fflib_match.anyObject())).thenReturn(jobExecutionList);
        MOCKS.when(PARAMETERS_REP.getParametersByParentId((Set<Id>) fflib_match.anyObject())).thenReturn(parametersList);
        MOCKS.stopStubbing();

        //Start Test
        Test.startTest();
        Boolean errorOccured = false;
        try {
            COMM_Async_OCIStockAlarmistic newBatchRun = new COMM_Async_OCIStockAlarmistic();
            newBatchRun = new COMM_Async_OCIStockAlarmistic(
                PRODUCTLOCATIONSTOCK_REP,
                EMAILTEMPLATE_REP,
                ORGWIDEADDRESSNOREPLY_REP,
                JOB_EXECUTION_REP,
                PARAMETERS_REP
            );
            Database.executeBatch(newBatchRun);
            newBatchRun.setAsyncApexJobId(null);
            newBatchRun.execute(null, capacityRecordList);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isFalse(errorOccured, 'expected no errors to occur');
    }
}