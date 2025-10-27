/**
 * @author Jose Passos
 * @description Batch class to update orders to complete as soon as it reaches the End Date of the reservation
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Jose Passos              17/04/2024		Original version
 **/
public inherited sharing class COMM_Async_SetOrderToCompleted extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string OBJECT_NAME = 'OrderSummary',
        ORDER_SUMMARY_STATUS_COMPLETED = 'Completed',
        ORDER_SUMMARY_STATUS_PAID = 'Paid';

    @TestVisible
    private final static string PARAMETER_RESERVATION_END_DATE = 'Reservation End Date';

    private FW_ISObjectRep sObjectRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SetOrderToCompleted() {
        this.sObjectRep = new FW_SObjectRep();
    }

    @testVisible
    private COMM_Async_SetOrderToCompleted(FW_ISObjectRep sObjectRep, FW_IREP_JobExecution jobExecutionRep, FW_IREP_Parameters parameterRep) {
        this.sObjectRep = sObjectRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field is set in the past.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());
        FW_QueryBuilder query;

        try {
            String filterDate = getParameterValue(PARAMETER_RESERVATION_END_DATE);
            if (String.isBlank(filterDate)) {
                filterDate = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ssXXX');
            } else {
                filterDate = Datetime.valueOf(filterDate).format('yyyy-MM-dd\'T\'HH:mm:ssXXX');
            }
            SObjectType sobjType = Schema.getGlobalDescribe().get(OBJECT_NAME);
            query = new FW_QueryBuilder(sobjType)
                .selectFields(new List<String>{ 'Id' })
                .setWhere('COMM_MaxReservationEnd__c < ' + filterDate)
                .whereEquals('Status', ORDER_SUMMARY_STATUS_PAID);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error on Start: ', 'COMM_Async_SetOrderToCompleted');
        }
        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Closes Order if Reservation End Date has passed.
     *
     * @param bc Context Information of the executed batch
     * @param sObjectList List of SObject that will be updated
     */
    public void execute(Database.BatchableContext bc, List<SObject> sObjectList) {
        for (SObject sobjRecord : sObjectList) {
            sobjRecord.put('Status', ORDER_SUMMARY_STATUS_COMPLETED);
        }
        sObjectRep.updateSObjects(sObjectList);
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}