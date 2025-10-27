/**
 * @author Daniel Lascas
 * @description COMM_MonthlyFiscalDocumentControl__c SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/04/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_DO_MonthlyFiscalDocumentControl implements COMM_IDO_MonthlyFiscalDocumentControl {
    public static final String RESERVATION_TYPE = 'Reservations';
    public static final String SUBSCRIPTION_TYPE = 'Subscriptions';
    //Status Picklist Values
    public static final String ERROR_STATUS = 'Error';
    public static final String NOTPROCESSED_STATUS = 'Not Processed';
    public static final String PROCESSED_STATUS = 'Processed';
    //Document Type Picklist Values
    public static final String INVOICE_DOC_TYPE = 'Invoice';
    public static final String CREDIT_MEMO_DOC_TYPE = 'CreditMemo';
}