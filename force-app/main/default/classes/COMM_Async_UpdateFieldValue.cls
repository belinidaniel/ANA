/**
 * @author Daniel Lascas
 * @description Generic Batch class to update a field value of all record's of
 * a SObject to a value defined on Batch Parameter
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas            23/04/2024		ECOMM-305: Original version
 **/
public with sharing class COMM_Async_UpdateFieldValue extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_OBJECT_NAME = 'SObject API Name';
    @TestVisible
    private final static string PARAMETER_FIELD_NAME = 'Field API Name';
    @TestVisible
    private final static string PARAMETER_UPDATED_VALUE = 'Value';
    @TestVisible
    private final static string PARAMETER_WHERE_CLAUSE = 'Where Clause';

    private FW_ISObjectRep sObjectRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_UpdateFieldValue() {
        this.sObjectRep = new FW_SObjectRep();
    }

    @TestVisible
    private COMM_Async_UpdateFieldValue(FW_ISObjectRep sObjectRep, FW_IREP_JobExecution jobExecutionRep, FW_IREP_Parameters parameterRep) {
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
        this.sObjectRep = sObjectRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        String objectName = getParameterValue(PARAMETER_OBJECT_NAME);
        SObjectType sobjType = Schema.getGlobalDescribe().get(objectName);
        String whereClause = getParameterValue(PARAMETER_WHERE_CLAUSE);

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType).selectFields(new List<String>{ 'Id' });
        if (String.isNotBlank(whereClause)) {
            query.setWhere(whereClause);
        }

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the field to a specific value that is defined in
     * Batch Definition Parameter for the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param sObjectList List of SObject that will be updated
     */
    public void execute(Database.BatchableContext bc, List<SObject> sObjectList) {
        String fieldName = getParameterValue(PARAMETER_FIELD_NAME);
        Object fieldValue = COMM_GEN_Utility.getValueForFieldType(
            getParameterValue(PARAMETER_OBJECT_NAME),
            fieldName,
            getParameterValue(PARAMETER_UPDATED_VALUE)
        );

        for (SObject sobjRecord : sObjectList) {
            sobjRecord.put(fieldName, fieldValue);
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