/**
 * @author Daniel Reto
 * @description Batch class to communicate with SAP in order to generate the required
 * Invoice and Credit Memo Fiscal Documents.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto              29/05/2024		Original version
 **/
public with sharing class COMM_Async_SAPSendInvoiceAndCreditMemo extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    //REP and SL Classes
    private COMM_IREP_Account accountRep;
    private COMM_IREP_Invoice invoiceRep;
    private COMM_IREP_CreditMemo creditMemoRep;
    private COMM_IREP_MonthlyFiscalDocumentControl docControlRep;
    private COMM_IREP_OrderItemAdjustmentLineSummary orderItemAdjustmentRep = new COMM_REP_OrderItemAdjustmentLineSummary();

    //Maximum Size for Field to store sent JSON in SF
    private static final Integer MAX_JSON_LENGTH = 131072;

    //Batch Framework Parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static string PARAMETER_DATECLAUSE = 'Date Clause';
    @TestVisible
    private final static string PARAMETER_MAXRETRIES = 'Max Retries';
    @TestVisible
    private final static string PARAMETER_RETRY_ONLY = 'Retry Only';

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SAPSendInvoiceAndCreditMemo() {
        this.accountRep = new COMM_REP_Account();
        this.invoiceRep = new COMM_REP_Invoice();
        this.creditMemoRep = new COMM_REP_CreditMemo();
        this.docControlRep = new COMM_REP_MonthlyFiscalDocumentControl();
        this.orderItemAdjustmentRep = new COMM_REP_OrderItemAdjustmentLineSummary();
    }

    @testVisible
    private COMM_Async_SAPSendInvoiceAndCreditMemo(
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep,
        COMM_IREP_Account accountRep,
        COMM_IREP_Invoice invoiceRep,
        COMM_IREP_CreditMemo creditMemoRep,
        COMM_IREP_MonthlyFiscalDocumentControl docControlRep,
        COMM_IREP_OrderItemAdjustmentLineSummary orderItemAdjustmentRep
    ) {
        this.accountRep = accountRep;
        this.invoiceRep = invoiceRep;
        this.creditMemoRep = creditMemoRep;
        this.docControlRep = docControlRep;
        this.orderItemAdjustmentRep = orderItemAdjustmentRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. Queries for generate Fiscal Document Records.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        Boolean retryOnly = Boolean.valueOf(getParameterValue(PARAMETER_RETRY_ONLY));
        if (!retryOnly) {
            String dateClause = getParameterValue(PARAMETER_DATECLAUSE);

            List<COMM_MonthlyFiscalDocumentControl__c> controllerList = new List<COMM_MonthlyFiscalDocumentControl__c>();
            for (Account accRecord : accountRep.getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteral(dateClause)) {
                //Check if Account has Invoices or Credit Memos for Period Defined in Date Clause
                if (!accRecord.Invoices.isEmpty() || !accRecord.CreditMemos.isEmpty()) {
                    Boolean hasInvoiceVC = false;
                    Boolean hasCreditMemoVC = false;
                    Datetime controllerDate;

                    for (Invoice invoiceRecord : accRecord.Invoices) {
                        if (((OrderSummary) invoiceRecord.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                            hasInvoiceVC = true;
                            controllerDate = invoiceRecord.DueDate;
                            break;
                        }
                    }
                    for (CreditMemo creditMemoRecord : accRecord.CreditMemos) {
                        if (((OrderSummary) creditMemoRecord.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                            hasCreditMemoVC = true;
                            controllerDate = creditMemoRecord.CreditDate;
                            break;
                        }
                    }

                    if (hasInvoiceVC || hasCreditMemoVC) {
                        COMM_MonthlyFiscalDocumentControl__c controllerRecord = new COMM_MonthlyFiscalDocumentControl__c();
                        controllerRecord.COMM_Account__c = accRecord.Id;
                        controllerRecord.COMM_Type__c = COMM_DO_MonthlyFiscalDocumentControl.RESERVATION_TYPE;
                        controllerRecord.COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS;
                        controllerRecord.COMM_RetryCounter__c = 0;
                        controllerRecord.COMM_DocumentMonth__c = controllerDate.month();
                        controllerRecord.COMM_DocumentYear__c = controllerDate.year();

                        //Generate Controller for Invoice and Credit Note if required
                        if (hasInvoiceVC) {
                            controllerRecord.COMM_DocumentType__c = COMM_DO_MonthlyFiscalDocumentControl.INVOICE_DOC_TYPE;
                            controllerList.add(controllerRecord);
                        }
                        if (hasCreditMemoVC) {
                            COMM_MonthlyFiscalDocumentControl__c creditControllerRecord = controllerRecord.clone();
                            creditControllerRecord.COMM_DocumentType__c = COMM_DO_MonthlyFiscalDocumentControl.CREDIT_MEMO_DOC_TYPE;
                            controllerList.add(creditControllerRecord);
                        }
                    }
                }
            }

            //Insert Fiscal Document Control Records if any were created
            if (!controllerList.isEmpty()) {
                docControlRep.insertSObjects(controllerList);
            }
        }

        Integer maxRetries = Integer.valueOf(getParameterValue(PARAMETER_MAXRETRIES));

        //Build Query to obtain Control Records with Status set as not Processed or Error AND have retried less than the max number
        FW_QueryBuilder query = new FW_QueryBuilder(COMM_MonthlyFiscalDocumentControl__c.sObjectType)
            .selectFields(
                new List<SObjectField>{
                    COMM_MonthlyFiscalDocumentControl__c.Id,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_Account__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_RetryCounter__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_DocumentMonth__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_DocumentYear__c,
                    COMM_MonthlyFiscalDocumentControl__c.COMM_DocumentType__c
                }
            )
            .setWhere('COMM_RetryCounter__c < ' + maxRetries)
            .whereIn(
                COMM_MonthlyFiscalDocumentControl__c.COMM_ProcessStatus__c,
                new List<String>{ COMM_DO_MonthlyFiscalDocumentControl.NOTPROCESSED_STATUS, COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS }
            )
            .whereEquals(COMM_MonthlyFiscalDocumentControl__c.COMM_Type__c, COMM_DO_MonthlyFiscalDocumentControl.RESERVATION_TYPE);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method.
     *
     * @param bc Context Information of the executed batch
     * @param controllerList List of Monthly Fiscal Document Control Records
     * whose associated invoices and credit memos are to be sent to SAP
     */
    public void execute(Database.BatchableContext bc, List<COMM_MonthlyFiscalDocumentControl__c> controllerList) {
        //Map with Control Records where Key is the Account associated with the Controller
        Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>> controlMap = new Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>>();

        String dateClause = COMM_SL_SAPSendInvoiceHelper.buildWhereClause(controllerList, controlMap);

        List<Invoice> invoiceToUpdateList = new List<Invoice>();
        List<CreditMemo> creditMemoToUpdateList = new List<CreditMemo>();
        List<Account> accountList = accountRep.getAccountsByIdsWithInvoicesAndCreditMemos(controlMap.keySet(), dateClause);
        Map<Id, List<Invoice>> invoiceListByAccountIdMap = new Map<Id, List<Invoice>>();
        Map<Id, List<CreditMemo>> creditMemoListByAccountIdMap = new Map<Id, List<CreditMemo>>();
        Set<Id> invoiceIdSet = new Set<Id>();
        Set<Id> creditMemoIdSet = new Set<Id>();

        for (Account accountRecord : accountList) {
            if (!accountRecord.Invoices.isEmpty()) {
                invoiceIdSet.addAll((new Map<Id, Invoice>(accountRecord.Invoices)).keySet());
            }
            if (!accountRecord.CreditMemos.isEmpty()) {
                creditMemoIdSet.addAll((new Map<Id, CreditMemo>(accountRecord.CreditMemos)).keySet());
            }
        }

        Set<Id> orderItemSummaryIdSet = new Set<Id>();
        if (!invoiceIdSet.isEmpty()) {
            for (Invoice invoiceRecord : invoiceRep.getForSAPInvoice(invoiceIdSet, dateClause)) {
                if (((OrderSummary) invoiceRecord.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                    if (!invoiceListByAccountIdMap.containsKey(invoiceRecord.BillingAccountId)) {
                        invoiceListByAccountIdMap.put(invoiceRecord.BillingAccountId, new List<Invoice>());
                    }
                    invoiceListByAccountIdMap.get(invoiceRecord.BillingAccountId).add(invoiceRecord);
                }

                //For Promotion Line Items retrieve Order Item Summary Id to obtain Promotion Id
                for (InvoiceLine invoiceLine : invoiceRecord.InvoiceLines) {
                    if (invoiceLine.Type.equalsIgnoreCase('Adjustment')) {
                        Id orderItemSummaryId = ((OrderItemSummary) invoiceLine.ReferenceEntityItem).Id;
                        orderItemSummaryIdSet.add(orderItemSummaryId);
                    }
                }
            }
        }
        if (!creditMemoIdSet.isEmpty()) {
            for (CreditMemo creditMemoRecord : creditMemoRep.getForSAPCreditMemo(creditMemoIdSet, dateClause)) {
                if (((OrderSummary) creditMemoRecord.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                    if (!creditMemoListByAccountIdMap.containsKey(creditMemoRecord.BillingAccountId)) {
                        creditMemoListByAccountIdMap.put(creditMemoRecord.BillingAccountId, new List<CreditMemo>());
                    }
                    creditMemoListByAccountIdMap.get(creditMemoRecord.BillingAccountId).add(creditMemoRecord);
                }
            }
        }

        Map<String, String> promotionNameByOrderItemSummaryMap = new Map<String, String>();
        if (!orderItemSummaryIdSet.isEmpty()) {
            //Query for Promotion Id. Since several promotion can be applied to the same product use promotion price as additional key.
            for (
                OrderItemAdjustmentLineSummary summaryRecord : orderItemAdjustmentRep.getOrderItemAdjustLineSumByOrderItemSummaryIds(
                    orderItemSummaryIdSet
                )
            ) {
                promotionNameByOrderItemSummaryMap.put(
                    summaryRecord.OrderItemSummaryId + String.valueOf(summaryRecord.OriginalOrderItemAdjustmentLineItem.Amount),
                    ((Promotion) summaryRecord.AdjustmentCause)?.Name
                );
            }
        }

        for (Account accRecord : accountList) {
            //Verify if Account has Subscription Invoices to send to SAP
            if (invoiceListByAccountIdMap.containsKey(accRecord.Id) || creditMemoListByAccountIdMap.containsKey(accRecord.Id)) {
                System.debug('accRecord: '+accRecord);
                System.debug('controlMap: '+controlMap);
                for (COMM_MonthlyFiscalDocumentControl__c controlRecord : controlMap.get(accRecord.Id)) {
                    //Obtain Date from Control Record then verify invoice/creditMemo to obtain all created on the same month as control record
                    DateTime controlDate = DateTime.newInstanceGmt(
                        Integer.valueOf(controlRecord.COMM_DocumentYear__c),
                        Integer.valueOf(controlRecord.COMM_DocumentMonth__c),
                        1,
                        0,
                        0,
                        0
                    );
                    List<Invoice> accountRelatedInvoiceDuringControlDate = new List<Invoice>();
                    List<CreditMemo> accountRelatedCreditMemoDuringControlDate = new List<CreditMemo>();
                    Boolean isInvoice = COMM_DO_MonthlyFiscalDocumentControl.INVOICE_DOC_TYPE.equals(controlRecord.COMM_DocumentType__c);

                    COMM_SL_SAPDocumentRequest request = COMM_SL_OMS_SAPHandler.buildCreditPaymentsRequest(
                        accRecord,
                        invoiceListByAccountIdMap.containsKey(accRecord.Id) ? invoiceListByAccountIdMap.get(accRecord.Id) : new List<Invoice>(),
                        creditMemoListByAccountIdMap.containsKey(accRecord.Id)
                            ? creditMemoListByAccountIdMap.get(accRecord.Id)
                            : new List<CreditMemo>(),
                        controlDate,
                        accountRelatedInvoiceDuringControlDate,
                        accountRelatedCreditMemoDuringControlDate,
                        isInvoice,
                        promotionNameByOrderItemSummaryMap
                    );

                    //Verify if there are items to send to SAP (ex: Invoices in a given month weren't returned on the same month)
                    if (request?.orderItems == null || request.orderItems.isEmpty()) {
                        //Set Invoice/Credit Memo with not sent data
                        if (isInvoice) {
                            COMM_SL_OMS_SAPHandler.handleNoItems(accountRelatedInvoiceDuringControlDate, invoiceToUpdateList);
                        } else {
                            COMM_SL_OMS_SAPHandler.handleNoItems(accountRelatedCreditMemoDuringControlDate, creditMemoToUpdateList);
                        }

                        controllerList.get(0).COMM_SAPDocumentId__c = '-1';
                        controllerList.get(0).COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.PROCESSED_STATUS;
                        controllerList.get(0).COMM_SentRequestJson__c = request != null ? System.JSON.serialize(request)?.left(MAX_JSON_LENGTH) : '';
                        controllerList.get(0).COMM_StatusMessage__c = 'no items to process for given month';
                        controllerList.get(0).COMM_RetryCounter__c += 1;
                    } else {
                        COMM_SL_SAPDocumentResponse response = isInvoice
                            ? COMM_SL_OMS_SAPHandler.DoCallAndHandleResponse(request, accountRelatedInvoiceDuringControlDate, invoiceToUpdateList)
                            : COMM_SL_OMS_SAPHandler.DoCallAndHandleResponse(
                                  request,
                                  accountRelatedCreditMemoDuringControlDate,
                                  creditMemoToUpdateList
                              );

                        String errorMessage = '';
                        if (response == null) {
                            errorMessage = 'Null response received';
                            controllerList.get(0).COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS;
                        } else if (!String.isEmpty(response.resultCode)) {
                            // error
                            errorMessage = response.resultDesc;
                            controllerList.get(0).COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS;
                        } else {
                            // register sap document id
                            controllerList.get(0).COMM_SAPDocumentId__c = response.documentId;
                            controllerList.get(0).COMM_ProcessStatus__c = COMM_DO_MonthlyFiscalDocumentControl.PROCESSED_STATUS;
                        }
                        controllerList.get(0).COMM_SentRequestJson__c = request != null ? System.JSON.serialize(request)?.left(MAX_JSON_LENGTH) : '';
                        controllerList.get(0).COMM_StatusMessage__c = response != null ? System.JSON.serialize(response) : '';
                        controllerList.get(0).COMM_RetryCounter__c += 1;
                    }
                }
            }
        }
        //Update Invoice Records if any are set for Update
        if (!invoiceToUpdateList.isEmpty()) {
            invoiceRep.updateSObjects(invoiceToUpdateList);
        }
        //Update Credit Memo Records if any are set for Update
        if (!creditMemoToUpdateList.isEmpty()) {
            creditMemoRep.updateSObjects(creditMemoToUpdateList);
        }
        //Update Fiscal Document Control Records if any were created
        docControlRep.updateSObjects(controllerList);
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