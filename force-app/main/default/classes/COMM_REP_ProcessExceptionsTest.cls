/**
 * @author Rui Salgado
 * @description COMM_REP_ProcessExceptionsTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100           Original version
 * Diogo Gonçalves  01/04/2024    100           ECOMM-133: Added methods getByOrderSummary and getByAttached
 **/
@isTest
private class COMM_REP_ProcessExceptionsTest {
    @testSetup
    static void setup() {
        List<Object> account = COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'Name' => 'full name' });
        List<Object> order = COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Order',
            new Map<String, Object>{
                'Status' => 'Draft',
                'Name' => 'full name',
                'EffectiveDate' => Date.today(),
                'OrderedDate' => Date.today(),
                'AccountId' => [SELECT Id FROM Account LIMIT 1]
                .Id
            }
        );
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void shouldUpdate() {
        Order order = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        ProcessException processException = COMM_DO_ProcessExceptions.createProcessException(
            order.Id,
            null,
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_LOW,
            'Test error',
            'Test description',
            COMM_DO_ProcessExceptions.NEW_S
        );
        insert processException;

        COMM_IREP_ProcessExceptions processExceptionRep = new COMM_REP_ProcessExceptions();

        List<ProcessException> processExceptions = processExceptionRep.getByCategoryAttachedStatus(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            order.Id,
            null,
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        List<ProcessException> processExceptionsNotFound = processExceptionRep.getByCategoryAttachedStatus(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            order.Id,
            null,
            new List<String>{ COMM_DO_ProcessExceptions.VOIDED }
        );

        Test.stopTest();

        Set<Id> resultIds = (new Map<Id, SObject>(processExceptions)).keySet();
        System.assert(resultIds.contains(processException.Id), 'No process exception record(s) found');
        System.assertEquals(processExceptionsNotFound.size(), 0, 'Process exception record(s) found');
    }

    @isTest
    static void testGetByOrderSummary() {
        COMM_IREP_ProcessExceptions processExceptionRepo = new COMM_REP_ProcessExceptions();
        OrderSummary orderSummary = [SELECT Id FROM OrderSummary LIMIT 1];

        Test.startTest();
        ProcessException processException = COMM_DO_ProcessExceptions.createProcessException(
            orderSummary.Id,
            orderSummary.Id,
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_LOW,
            'Test error',
            'Test description',
            COMM_DO_ProcessExceptions.NEW_S
        );
        insert processException;

        List<ProcessException> processExceptionsByOrderSumId = processExceptionRepo.getByOrderSummary(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            new List<String>{ orderSummary.Id },
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        List<ProcessException> processExceptionsByAttachedId = processExceptionRepo.getByAttatched(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            new List<String>{ orderSummary.Id },
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        Set<Id> byOrderSumIds = (new Map<Id, SObject>(processExceptionsByOrderSumId)).keySet();
        Set<Id> byAttatchedIds = (new Map<Id, SObject>(processExceptionsByAttachedId)).keySet();
        System.assert(byOrderSumIds.contains(processException.Id), 'No process exception record(s) found');
        System.assert(byAttatchedIds.contains(processException.Id), 'No process exception record(s) found');
    }

    @isTest
    static void testGetInvoiceCreditMemo() {
        COMM_IREP_ProcessExceptions processExceptionRepo = new COMM_REP_ProcessExceptions();
        OrderSummary orderSummary = [SELECT Id FROM OrderSummary LIMIT 1];

        Test.startTest();
        ProcessException processException = COMM_DO_ProcessExceptions.createProcessException(
            orderSummary.Id,
            orderSummary.Id,
            COMM_DO_ProcessExceptions.SAP_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_LOW,
            'Test error',
            'Test description',
            COMM_DO_ProcessExceptions.NEW_S
        );
        insert processException;

        List<ProcessException> processExceptionsByCategory = processExceptionRepo.getInvoiceCreditMemo(
            COMM_DO_ProcessExceptions.SAP_CATEGORY,
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        Set<Id> byCategoryIds = (new Map<Id, SObject>(processExceptionsByCategory)).keySet();
        System.assert(byCategoryIds.contains(processException.Id), 'No process exception record(s) found');
    }
}