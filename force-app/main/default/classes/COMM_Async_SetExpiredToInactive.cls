/**
 * @author Daniel Lascas
 * @description Generic Batch class to update expired records to inactive
 * based on parameters defined in the Batch Definition Record
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas            19/02/2024		Original version
 **/
public with sharing class COMM_Async_SetExpiredToInactive extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_OBJECT_NAME = 'SObject API Name';
    @TestVisible
    private final static string PARAMETER_ACTIVEFIELD = 'Active Field';
    @TestVisible
    private final static string PARAMETER_DATEFIELD = 'Date Field';

    private FW_ISObjectRep sObjectRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SetExpiredToInactive() {
        this.sObjectRep = new FW_SObjectRep();
    }

    @testVisible
    private COMM_Async_SetExpiredToInactive(FW_ISObjectRep sObjectRep, FW_IREP_JobExecution jobExecutionRep, FW_IREP_Parameters parameterRep) {
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

        String objectName = getParameterValue(PARAMETER_OBJECT_NAME);
        String dateField = getParameterValue(PARAMETER_DATEFIELD);
        String dateNow = Datetime.now().format(COMM_GEN_Utility.TIME_FORMAT);
        String activeField = getParameterValue(PARAMETER_ACTIVEFIELD);
        SObjectType sobjType = Schema.getGlobalDescribe().get(objectName);
        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(new List<String>{ 'Id' })
            .setWhere(dateField + ' < ' + dateNow)
            .whereEquals(activeField, true);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the records active field to false that were obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param sObjectList List of SObject that will be deleted
     */
    public void execute(Database.BatchableContext bc, List<SObject> sObjectList) {
        String activeField = getParameterValue(PARAMETER_ACTIVEFIELD);
        for (SObject sobjRecord : sObjectList) {
            sobjRecord.put(activeField, false);
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