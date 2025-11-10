/**
 * @author Rui Salgado
 * @description COMM_DO_ProcessExceptionsTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    95            Original version
 * Diogo Gonçalves  10/05/2024    100            ECOMM-133: Added shouldResolveByOrderSummaries and shouldResolveByAttatched
 **/
@isTest
private class COMM_DO_ProcessExceptionsTest {
    @TestSetup
    static void makeData() {
        // Create account
        Date today = Date.today();
        COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'Name' => 'Test' });
        // Create order
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Order',
            new Map<String, Object>{
                'Status' => 'Draft',
                'Name' => 'Test',
                'EffectiveDate' => today,
                'OrderedDate' => today,
                'AccountId' => [SELECT Id FROM Account LIMIT 1]
                .Id
            }
        );

        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void shouldCreate() {
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
        Test.stopTest();
        List<ProcessException> processExceptions = [
            SELECT Id, category, severity, priority, message, description, attachedToId, OrderSummaryId, Status
            FROM ProcessException
        ];
        Set<Id> resultIds = (new Map<Id, SObject>(processExceptions)).keySet();
        System.assert(resultIds.contains(processException.Id), 'No process exception record(s) found');
        System.assertEquals(
            processExceptions[0].Status,
            COMM_DO_ProcessExceptions.NEW_S,
            'Process Exception status is not NEW=' + processExceptions[0].Status
        );
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

        List<ProcessException> processExceptions = COMM_DO_ProcessExceptions.updateStatus(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            order.Id,
            null,
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S },
            COMM_DO_ProcessExceptions.VOIDED
        );

        Test.stopTest();

        Set<Id> resultIds = (new Map<Id, SObject>(processExceptions)).keySet();
        System.assert(resultIds.contains(processException.Id), 'No process exception record(s) found');
        System.assertEquals(
            processExceptions[0].Status,
            COMM_DO_ProcessExceptions.VOIDED,
            'Process Exception status is not VOIDED =' + processExceptions[0].Status
        );
    }

    @isTest
    static void shouldResolveByOrderSummaries() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        OrderSummary orderSummary = [SELECT Id FROM OrderSummary LIMIT 1];

        Test.startTest();
        ProcessException processException = COMM_DO_ProcessExceptions.createProcessException(
            order.Id,
            orderSummary.Id,
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_LOW,
            'Test error',
            'Test description',
            COMM_DO_ProcessExceptions.NEW_S
        );
        insert processException;

        List<ProcessException> processExceptions = COMM_DO_ProcessExceptions.resolveByOrderSummaries(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            new List<Id>{ orderSummary.Id },
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        Test.stopTest();

        Set<Id> resultIds = (new Map<Id, SObject>(processExceptions)).keySet();
        Assert.isTrue(resultIds.contains(processException.Id), 'No process exception record(s) found');
        Assert.areEqual(
            processExceptions[0].Status,
            COMM_DO_ProcessExceptions.RESOLVED,
            'Process Exception status is not RESOLVED =' + processExceptions[0].Status
        );
    }

    @isTest
    static void shouldResolveByAttatched() {
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

        List<ProcessException> processExceptions = COMM_DO_ProcessExceptions.resolveByAttached(
            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
            new List<Id>{ order.Id },
            new List<String>{ COMM_DO_ProcessExceptions.NEW_S }
        );

        Test.stopTest();

        Set<Id> resultIds = (new Map<Id, SObject>(processExceptions)).keySet();
        Assert.isTrue(resultIds.contains(processException.Id), 'No process exception record(s) found');
        Assert.areEqual(
            processExceptions[0].Status,
            COMM_DO_ProcessExceptions.RESOLVED,
            'Process Exception status is not RESOLVED =' + processExceptions[0].Status
        );
    }
}