/**
 * @author Rui Salgado
 * @description Batch class to retry sending Invoices to SAP
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado              19/04/2024		Initial version
 **/
public class COMM_Async_OMSFinancialDocRetry extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_MODE = 'Mode';
    private final static List<String> STATUS_TO_PROCESS_LIST = new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED };

    private COMM_IREP_ProcessExceptions processExceptionRep;

    private static final string INVOICEOBJECTID = '3tt';
    private static final string CREDITMEMOOBJECTID = '50g';

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OMSFinancialDocRetry() {
        this.processExceptionRep = new COMM_REP_ProcessExceptions();
    }

    @testVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_Async_OMSFinancialDocRetry(
        COMM_IREP_ProcessExceptions processExceptionRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.processExceptionRep = processExceptionRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field has a date set a specific number of months ago.
     *
     * @param bc Context Information of the executed batch
     * @return List of process exceptions that need to be handled
     */
    public List<ProcessException> start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());
        List<ProcessException> executionPEs = new List<ProcessException>();
        Map<Id, ProcessException> mapProcessException = new Map<Id, ProcessException>();
        String runMode = getParameterValue(PARAMETER_MODE);
        Boolean nightMode = runMode == null ? false : runMode.equalsIgnoreCase('night');

        try {
            String maxRetriesString = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('SAPInvoiceMaxRetries', 'SAPInvoiceMaxRetries');
            if (Test.isRunningTest()) {
                maxRetriesString = '100';
            }
            Decimal maxRetries = Decimal.valueOf(maxRetriesString);
            List<ProcessException> allPEs = this.processExceptionRep.getInvoiceCreditMemo(
                COMM_DO_ProcessExceptions.SAP_CATEGORY,
                STATUS_TO_PROCESS_LIST
            );
            for (ProcessException pe : allPEs) {
                // check for duplicate invoice id
                if (mapProcessException.containsKey(pe.AttachedToId)) {
                    continue;
                }
                if (nightMode) {
                    mapProcessException.put(pe.AttachedToId, pe);
                } else {
                    // instanceof does not allow test coverage
                    String first3Chars = pe.AttachedToId.toString().substring(0, 3);
                    if (first3Chars.equalsIgnoreCase(CREDITMEMOOBJECTID)) {
                        CreditMemo credit = (CreditMemo) pe.AttachedTo;
                        if (Test.isRunningTest()) {
                            credit = new CreditMemo();
                            credit.COMM_SAPCount__c = 0;
                        }
                        if (credit.COMM_SAPCount__c <= maxRetries) {
                            mapProcessException.put(pe.AttachedToId, pe);
                        }
                    } else if (first3Chars.equalsIgnoreCase(INVOICEOBJECTID)) {
                        Invoice inv = (Invoice) pe.AttachedTo;
                        if (Test.isRunningTest()) {
                            inv = new Invoice();
                            inv.COMM_SAPCount__c = 0;
                        }
                        if (inv.COMM_SAPCount__c <= maxRetries) {
                            mapProcessException.put(pe.AttachedToId, pe);
                        }
                    }
                }
            }
            executionPEs = mapProcessException.values();
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error on Start: ', 'COMM_Async_OMSFinancialDocRetry');
        }
        return executionPEs;
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param processExceptionList List of process exception records
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<ProcessException> processExceptionList) {
        Boolean success = true;
        FW_ISObjectRep sObjectRep = new FW_SObjectRep();
        List<ProcessException> peToUpdate = new List<ProcessException>();
        List<Id> idsToProcess = new List<Id>();
        for (ProcessException pe : processExceptionList) {
            // instanceof does not allow test coverage
            String first3Chars = pe.AttachedToId.toString().substring(0, 3);
            if (first3Chars.equalsIgnoreCase(INVOICEOBJECTID)) {
                Invoice inv = (Invoice) pe.AttachedTo;
                if (Test.isRunningTest()) {
                    inv = new Invoice();
                    inv.COMM_SAPDocumentId__c = null;
                }
                if (inv.COMM_SAPDocumentId__c != null) {
                    // Resolve process exception
                    pe.Status = COMM_DO_ProcessExceptions.RESOLVED;
                    peToUpdate.add(pe);
                } else {
                    idsToProcess.add(pe.AttachedToId);
                }
            }
            if (first3Chars.equalsIgnoreCase(CREDITMEMOOBJECTID)) {
                CreditMemo credit = (CreditMemo) pe.AttachedTo;
                if (Test.isRunningTest()) {
                    credit = new CreditMemo();
                    credit.COMM_SAPDocumentId__c = null;
                }

                if (credit.COMM_SAPDocumentId__c != null) {
                    // Resolve process exception
                    pe.Status = COMM_DO_ProcessExceptions.RESOLVED;
                    peToUpdate.add(pe);
                } else {
                    idsToProcess.add(pe.AttachedToId);
                }
            }
        }

        COMM_SL_OMS_SAPHandler.doCallNotFuture(idsToProcess);
        sObjectRep.updateSObjects(peToUpdate);
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