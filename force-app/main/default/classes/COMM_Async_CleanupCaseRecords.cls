/**
 * @author Carlos Fusco
 * @description Batch class to cleanup Case records based on parameters
 * defined in the Batch Definition Record
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco          26/04/2024		  Original version
 **/
public with sharing class COMM_Async_CleanupCaseRecords extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    @TestVisible
    private final static string PARAMETER_DATEFIELD = 'Date Field';
    @TestVisible
    private final static string PARAMETER_OPERATOR = 'Operator';
    @TestVisible
    private final static string PARAMETER_MONTHS_AGO = 'Months';
    @TestVisible
    private final static string PARAMETER_RECORD_TYPE = 'Record Type';
    @TestVisible
    private final static string PARAMETER_STATUS = 'Status';
    @TestVisible
    private final static string PARAMETER_ORIGIN = 'Origin';

    private FW_ISObjectRep sObjectRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_CleanupCaseRecords() {
        this.sObjectRep = new FW_SObjectRep();
    }

    @testVisible
    private COMM_Async_CleanupCaseRecords(FW_ISObjectRep sObjectRep, FW_IREP_JobExecution jobExecutionRep, FW_IREP_Parameters parameterRep) {
        this.sObjectRep = sObjectRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field has a date set a specific number of months ago.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        SObjectType sobjType = Schema.getGlobalDescribe().get('Case');
        String dateField = getParameterValue(PARAMETER_DATEFIELD);
        String operator = getParameterValue(PARAMETER_OPERATOR);
        String monthsAgo = getParameterValue(PARAMETER_MONTHS_AGO);
        String recordTypeId = COMM_GEN_Utility.getRecordTypeIdByDevName(Schema.Case.SObjectType, getParameterValue(PARAMETER_RECORD_TYPE));
        String status = getParameterValue(PARAMETER_STATUS);
        String origin = getParameterValue(PARAMETER_ORIGIN);

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(new List<String>{ 'Id' })
            .setWhere(dateField + ' ' + operator + ' N_MONTHS_AGO:' + monthsAgo)
            .whereEquals(Case.RecordTypeId, recordTypeId)
            .whereEquals(Case.Status, status)
            .whereEquals(Case.Origin, origin);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param caseList List of Cases that will be deleted
     */
    public void execute(Database.BatchableContext bc, List<Case> caseList) {
        sObjectRep.deleteSObjects(caseList);
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