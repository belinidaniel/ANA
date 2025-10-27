/**
 * @author Daniel Lascas
 * @description Batch class to communicate with SAP in order to generate the required
 * Subscription Invoice Fiscal Document.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas            15/04/2024		ECOMM-194: Original version
 **/
public with sharing class COMM_Async_SAPSendSubInvoice extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    //REP and SL Classes
    private COMM_IREP_Account accountRep;
    private COMM_IREP_SubscriptionInvoice invoiceRep;
    private COMM_IREP_MonthlyFiscalDocumentControl docControlRep;
    private COMM_SL_SAPFinancialDocument sapDocumentSl;

    //Batch Framework Parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_DATECLAUSE = 'Date Clause';
    @TestVisible
    private final static string PARAMETER_MAXRETRIES = 'Max Retries';
    @TestVisible
    private final static string PARAMETER_PAYMENT_DAYS = 'Payment Days';
    @TestVisible
    private final static string PARAMETER_RETRY_ONLY = 'Retry Only';
    @TestVisible
    private final static string PARAMETER_ACCOUNT_LIST = 'Account Ids';

    @TestVisible
    private Integer paymentDays;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SAPSendSubInvoice() {
        this.accountRep = new COMM_REP_Account();
        this.invoiceRep = new COMM_REP_SubscriptionInvoice();
        this.docControlRep = new COMM_REP_MonthlyFiscalDocumentControl();
        this.sapDocumentSl = new COMM_SL_SAPFinancialDocument();
    }

    @testVisible
    private COMM_Async_SAPSendSubInvoice(
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep,
        COMM_IREP_Account accountRep,
        COMM_IREP_SubscriptionInvoice invoiceRep,
        COMM_IREP_MonthlyFiscalDocumentControl docControlRep,
        COMM_SL_SAPFinancialDocument sapDocumentSl
    ) {
        this.accountRep = accountRep;
        this.invoiceRep = invoiceRep;
        this.docControlRep = docControlRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
        this.sapDocumentSl = sapDocumentSl;
    }

    /**
     * @description Batch Start Method. Queries for Active Subscriptions to generate Invoices.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        //Verify Batch Parameter to determine if Batch only processes failed records
        Boolean retryOnly = Boolean.valueOf(getParameterValue(PARAMETER_RETRY_ONLY));
        //Verify Batch Parameter to determine if Batch only processes invoices for specific accounts
        Set<String> accountIdSet = new Set<String>(
            String.isNotBlank(getParameterValue(PARAMETER_ACCOUNT_LIST)) ? getParameterValue(PARAMETER_ACCOUNT_LIST).split(',') : new List<String>()
        );
        if (!retryOnly) {
            String dateClause = getParameterValue(PARAMETER_DATECLAUSE);

            List<COMM_MonthlyFiscalDocumentControl__c> controllerList = new List<COMM_MonthlyFiscalDocumentControl__c>();
            Map<Id, List<COMM_SubscriptionInvoice__c>> accountInvoiceMap = new Map<Id, List<COMM_SubscriptionInvoice__c>>();
            for (Account accRecord : accountRep.getPartnerAccountsAndInvoicesByDateLiteral(accountIdSet, dateClause)) {
                //Check if Account has Invoices for Period Defined in Date Clause
                if (!accRecord.SubscriptionInvoices__r.isEmpty()) {
                    Datetime controllerDate = accRecord.SubscriptionInvoices__r[0].CreatedDate;

                    COMM_MonthlyFiscalDocumentControl__c controllerRecord = new COMM_MonthlyFiscalDocumentControl__c();
                    controllerRecord.COMM_Account__c = accRecord.Id;
                    controllerRecord.COMM_Type__c = COMM_DO_MonthlyFiscalDocumentControl.SUBSCRIPTION_TYPE;
                    controllerRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS;
                    controllerRecord.COMM_RetryCounter__c = 0;
                    controllerRecord.COMM_DocumentMonth__c = controllerDate.month();
                    controllerRecord.COMM_DocumentYear__c = controllerDate.year();
                    controllerList.add(controllerRecord);
                    accountInvoiceMap.put(accRecord.Id, accRecord.SubscriptionInvoices__r);
                }
            }

            //Insert Fiscal Document Control Records if any were created
            if (!controllerList.isEmpty()) {
                docControlRep.insertSObjects(controllerList);

                //Associate Invoices to newly generated Control Record
                List<COMM_SubscriptionInvoice__c> invoiceToUpdate = new List<COMM_SubscriptionInvoice__c>();
                for (COMM_MonthlyFiscalDocumentControl__c controlRecord : controllerList) {
                    for (COMM_SubscriptionInvoice__c invoice : accountInvoiceMap.get(controlRecord.COMM_Account__c)) {
                        invoice.COMM_MonthlyFiscalDocumentControl__c = controlRecord.Id;
                        invoiceToUpdate.add(invoice);
                    }
                }
                invoiceRep.updateSObjects(invoiceToUpdate);
            }
        }

        Integer maxRetries = String.isNotBlank(getParameterValue(PARAMETER_MAXRETRIES))
            ? Integer.valueOf(getParameterValue(PARAMETER_MAXRETRIES))
            : null;
        paymentDays = Integer.valueOf(getParameterValue(PARAMETER_PAYMENT_DAYS));

        //Build Query to obtain Control Records with Status set as not Processed or Error AND have retried less than the max number
        FW_QueryBuilder query = new FW_QueryBuilder(COMM_MonthlyFiscalDocumentControl__c.sObjectType)
            .selectFields(
                new List<SObjectField>{
                    COMM_MonthlyFiscalDocumentControl__c.Id,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_Account__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_RetryCounter__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_DocumentMonth__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_DocumentYear__c
                }
            );
        //Verify if Max Retries was defined
        if (maxRetries != null) {
            query.setWhere('COMM_RetryCounter__c < ' + maxRetries);
        }
        //Set query parameters
        query.whereIn(
                COMM_MonthlyFiscalDocumentControl__c.COMM_ProcessStatus__c,
                new List<String>{ COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS, COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS }
            )
            .whereEquals(COMM_MonthlyFiscalDocumentControl__c.COMM_Type__c, COMM_DO_MonthlyFiscalDocumentControl.SUBSCRIPTION_TYPE);
        //Verify if Batch only Processes Invoice for specific accounts
        if (!accountIdSet.isEmpty()) {
            query.whereIn(COMM_MonthlyFiscalDocumentControl__c.COMM_Account__c, new List<String>(accountIdSet));
        }

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method.
     *
     * @param bc Context Information of the executed batch
     * @param controllerList List of Monthly Fiscal Document Control Records
     * whose associated invoices are to be sent to SAP
     */
    public void execute(Database.BatchableContext bc, List<COMM_MonthlyFiscalDocumentControl__c> controllerList) {
        //Map with Control Records where Key is the Account associated with the Controller
        Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>> controlMap = new Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>>();

        String dateClause = COMM_SL_SAPSendInvoiceHelper.buildWhereClause(controllerList, controlMap);

        List<COMM_SubscriptionInvoice__c> invoiceToUpdateList = new List<COMM_SubscriptionInvoice__c>();
        List<COMM_MonthlyFiscalDocumentControl__c> controllersToUpdateList = new List<COMM_MonthlyFiscalDocumentControl__c>();
        for (Account accRecord : accountRep.getAccountsAndInvoicesByIdsAndDateLiteral(controlMap.keySet(), dateClause)) {
            //Verify if Account has Subscription Invoices to send to SAP
            if (!accRecord.SubscriptionInvoices__r.isEmpty()) {
                for (COMM_MonthlyFiscalDocumentControl__c controlRecord : controlMap.get(accRecord.Id)) {
                    //Obtain Date from Control Record (Last Day of Month) then verify invoice to obtain all created on the same month as control record
                    Date controlDate = Date.newInstance(
                            Integer.valueOf(controlRecord.COMM_DocumentYear__c),
                            Integer.valueOf(controlRecord.COMM_DocumentMonth__c) + 1,
                            1
                        )
                        .addDays(-1);
                    List<COMM_SubscriptionInvoice__c> invoiceToSendList = COMM_SL_SAPSendInvoiceHelper.obtainInvoiceForMonthList(
                        controlDate,
                        controlRecord.Id,
                        accRecord.SubscriptionInvoices__r,
                        accRecord.COMM_StaffCompanyRatio__c,
                        accRecord.COMM_OfficialEntityRatio__c
                    );

                    //Call SL to make call to SAP to generate financial document then verify result
                    COMM_SL_SAPDocumentResponse documentResponse = sapDocumentSl.createFinancialDocument(
                        accRecord.IsPersonAccount ? accRecord.PersonEmail : accRecord.COMM_Email__c,
                        controlRecord,
                        accRecord,
                        controlDate,
                        paymentDays,
                        invoiceToSendList
                    );
                    COMM_SL_SAPSendInvoiceHelper.verifySAPResponse(invoiceToSendList, documentResponse, controlRecord, invoiceToUpdateList);
                    controllersToUpdateList.add(controlRecord);
                }
            }
        }
        //Update Subscription Invoice Records if any are set for Update
        if (!invoiceToUpdateList.isEmpty()) {
            invoiceRep.updateSObjects(invoiceToUpdateList);
        }
        //Insert Fiscal Document Control Records if any were created
        if (!controllersToUpdateList.isEmpty()) {
            docControlRep.updateSObjects(controllersToUpdateList);
        }
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