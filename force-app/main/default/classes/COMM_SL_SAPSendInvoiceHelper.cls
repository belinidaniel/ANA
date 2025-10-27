/**
 * @author Daniel Lascas
 * @description Helper Class with methods used when processing invoices for Batch
 * COMM_Async_SAPSendSubInvoice
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/04/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_SL_SAPSendInvoiceHelper {
    private static final String WHERE_CLAUSE = 'CreatedDate = N_MONTHS_AGO:';
    private static final String AND_CLAUSE = ' AND ';

    //SAP Success Response Code
    @TestVisible
    private static final String RESPONSE_STATUS_CODE_OK = '200';

    /**
     * @description Method to Build the Date Where Clause used in the query to obtain the invoices for a given month.
     * Where Clause uses Salesforce literal 'N_MONTHS_AGO:x' that retrieves all records whose Date field is set
     * x months ago.
     *
     * @param controllerList List of Controller Records
     * @param controlMap Map where the Controller Records are stored where the Key is the Controller's Account
     * @return Where Clause String for Created Date Field
     */
    public static String buildWhereClause(
        List<COMM_MonthlyFiscalDocumentControl__c> controllerList,
        Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>> controlMap
    ) {
        String dateClause = '';
        for (COMM_MonthlyFiscalDocumentControl__c controlRecord : controllerList) {
            //Calculate Date from current and build WHERE clause for Date.
            Date controlDate = Date.newInstance(
                Integer.valueOf(controlRecord.COMM_DocumentYear__c),
                Integer.valueOf(controlRecord.COMM_DocumentMonth__c),
                1
            );
            Integer monthsAgo = controlDate.monthsBetween(System.today());
            dateClause += WHERE_CLAUSE + monthsAgo + AND_CLAUSE;

            //Store Control Record in Map
            if (!controlMap.containsKey(controlRecord.COMM_Account__c)) {
                controlMap.put(controlRecord.COMM_Account__c, new List<COMM_MonthlyFiscalDocumentControl__c>());
            }
            controlMap.get(controlRecord.COMM_Account__c).add(controlRecord);
        }
        return dateClause.removeEnd(AND_CLAUSE);
    }

    /**
     * @description Method to parse through a list of invoices and return list of invoices for the month of a specific date
     *
     * @param controlDate Date of the month where the invoices that were created is to be retrieved
     * @param controlId Id of the Control Record (to group invoices with the same control record)
     * @param invoiceList List of Invoices to verify
     * @param staffRatio Ratio for Invoices exempt from Payment of Staff Company Type
     * @param entityRatio Ratio for Invoices exempt from Payment of External Entity Type
     * @return List of Invoices whose Created Date is set on the same month as the control date
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<COMM_SubscriptionInvoice__c> obtainInvoiceForMonthList(
        Date controlDate,
        Id controlId,
        List<COMM_SubscriptionInvoice__c> invoiceList,
        String staffRatio,
        String entityRatio
    ) {
        List<COMM_SubscriptionInvoice__c> invoiceToSendList = new List<COMM_SubscriptionInvoice__c>();
        Map<String, List<COMM_SubscriptionInvoice__c>> staffInvoiceMap = new Map<String, List<COMM_SubscriptionInvoice__c>>();
        Map<String, List<COMM_SubscriptionInvoice__c>> entityInvoiceMap = new Map<String, List<COMM_SubscriptionInvoice__c>>();

        //Verify Invoices for the Monthly Period defined in Control Record.
        //If Invoice already associated with another Control Record then ignore it.
        for (COMM_SubscriptionInvoice__c invoice : invoiceList) {
            if (
                controlDate.monthsBetween(Date.valueOf(invoice.CreatedDate)) == 0 &&
                (invoice.COMM_MonthlyFiscalDocumentControl__c == null || controlId.equals(invoice.COMM_MonthlyFiscalDocumentControl__c))
            ) {
                invoiceToSendList.add(invoice);

                //Create Key for Ratio appliable Invoices (Key is Park + Airport)
                String mapKey = invoice.COMM_SubscriptonProduct__r.COMM_Park__c + invoice.COMM_SubscriptonProduct__r.COMM_Airport__c;
                //If Subscription's Payment Method is Courtesy then exempt it from Payment
                if (COMM_DO_Subscription.PAYMENT_COURTESY.equals(invoice.COMM_Subscripton__r.COMM_PaymentMethod__c)) {
                    invoice.COMM_ExemptPayment__c = true;
                } else if (COMM_DO_Product2.SUBCATEGORY_STAFF_COMPANY.equals(invoice.COMM_SubscriptonProduct__r.COMM_SubCategory__c)) {
                    //For Staff Company Subscriptions verify if Exemption should apply based on Account Ratio
                    addToMap(staffInvoiceMap, invoice, mapKey);
                } else if (COMM_DO_Product2.SUBCATEGORY_OFFICIAL_ENTITY.equals(invoice.COMM_SubscriptonProduct__r.COMM_SubCategory__c)) {
                    //For Official Entity Subscriptions verify if Exemption should apply based on Account Ratio
                    addToMap(entityInvoiceMap, invoice, mapKey);
                }
            }
        }

        verifyPriceExemptions(staffInvoiceMap, staffRatio);
        verifyPriceExemptions(entityInvoiceMap, entityRatio);

        return invoiceToSendList;
    }

    /**
     * @description Add Invoice to Map with list based on Key. If a list for the key
     * hasn't been created, creates a new one.
     *
     * @param invoiceMap Map where the invoice will be added
     * @param invoiceToAdd Invoice record to be added to map with list
     * @param mapKey The Key used to identify the list on the map
     */
    private static void addToMap(Map<String, List<COMM_SubscriptionInvoice__c>> invoiceMap, COMM_SubscriptionInvoice__c invoiceToAdd, String mapKey) {
        if (!invoiceMap.containsKey(mapKey)) {
            invoiceMap.put(mapKey, new List<COMM_SubscriptionInvoice__c>());
        }
        invoiceMap.get(mapKey).add(invoiceToAdd);
    }

    /**
     * @description Verify Subscription Invoices of that will be marked as exempt of Payment based on Account Ratio.
     * Exemption is applyed to the cheapest invoice per park and airport.
     *
     * @param invoiceMap Map with the list of invoices to check for exemption
     * @param accountRatio Ratio of the Account to apply to invoices for exemption. Expected format to be x/y.
     */
    private static void verifyPriceExemptions(Map<String, List<COMM_SubscriptionInvoice__c>> invoiceMap, String accountRatio) {
        if (String.isNotBlank(accountRatio) && !invoiceMap.isEmpty()) {
            for (String mapKey : invoiceMap.keySet()) {
                List<COMM_SubscriptionInvoice__c> invoiceToExemptList = invoiceMap.get(mapKey);
                Integer invoiceCounter = invoiceToExemptList.size();
                if (invoiceCounter > 1) {
                    Decimal leftNum = Decimal.valueOf(accountRatio.substringBeforeLast('/'));
                    Decimal rightNum = Decimal.valueOf(accountRatio.substringAfterLast('/'));
                    Decimal invoicesToPay = invoiceCounter * (leftNum / rightNum);
                    Integer roundedToPayNumber = Integer.valueOf(invoicesToPay.round());
                    //Set cheapest invoices for exemption (at the end of list).
                    for (Integer index = 0; index < invoiceCounter; index++) {
                        invoiceToExemptList[index].COMM_ExemptPayment__c = index >= roundedToPayNumber;
                    }
                }
            }
        }
    }

    /**
     * @description Verify SAP Response and set Invoice Records and Monthly Fiscal Document Control records
     * for update/creation based on response
     *
     * @param invoiceSentList List of invoices that were sent to SAP
     * @param documentResponse Response from SAP after request to generate fiscal document finished
     * @param controlRecord Monthly Fiscal Document Control records associated with the invoices sent to SAP
     * @param invoiceToUpdateList List of Invoices were the invoices set for DML update are stored
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void verifySAPResponse(
        List<COMM_SubscriptionInvoice__c> invoiceSentList,
        COMM_SL_SAPDocumentResponse documentResponse,
        COMM_MonthlyFiscalDocumentControl__c controlRecord,
        List<COMM_SubscriptionInvoice__c> invoiceToUpdateList
    ) {
        //Verify if received response from SAP and it was Success (CODE = 200 OR Document Id was provided)
        Boolean wasSuccess =
            documentResponse != null && (RESPONSE_STATUS_CODE_OK.equals(documentResponse.resultCode) || documentResponse.documentId != null);
        //If Success then update Subscription Invoice Records to update with SAP Document Id and Generated Status.
        if (wasSuccess) {
            for (COMM_SubscriptionInvoice__c invoiceRecord : invoiceSentList) {
                COMM_SubscriptionInvoice__c invoiceUpdate = new COMM_SubscriptionInvoice__c();
                invoiceUpdate.Id = invoiceRecord.Id;
                invoiceUpdate.COMM_IssuanceDate__c = System.today();
                invoiceUpdate.COMM_SAPNumber__c = documentResponse.documentId;
                invoiceUpdate.COMM_Status__c = COMM_DO_SubscriptionInvoice.GENERATED_STATUS;
                invoiceUpdate.COMM_ExemptPayment__c = invoiceRecord.COMM_ExemptPayment__c;
                invoiceToUpdateList.add(invoiceUpdate);
            }
        } else {
            //If failed increase retry counter in Control Record
            controlRecord.COMM_RetryCounter__c += 1;
        }
        //Update Control Record with information based on SAP Response
        controlRecord.COMM_SAPDocumentId__c = documentResponse?.documentId;
        controlRecord.COMM_StatusMessage__c = documentResponse?.resultCode + ': ' + documentResponse?.resultDesc;
        controlRecord.COMM_ProcessStatus__c = wasSuccess
            ? COMM_DO_MonthlyFiscalDocumentControl.PROCESSED_STATUS
            : COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS;
    }
}