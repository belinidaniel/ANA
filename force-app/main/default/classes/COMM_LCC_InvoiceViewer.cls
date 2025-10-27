/**
 * @author Daniel Lascas
 * @description Controller for the comm_invoiceViewer lwc.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024       ECOMM-194: Original version
 * Daniel Reto      08/07/2024       New type of object to be used on handleGetFileData method
 *
 **/
public with sharing class COMM_LCC_InvoiceViewer {
    private COMM_SL_SAPFinancialDocument finacialDocumentSl;
    private COMM_IREP_SubscriptionInvoice subInvoiceRep;
    private COMM_IREP_Invoice invoiceRep;
    private COMM_IREP_CreditMemo creditMemoRep;

    /**
     * @description Constructor to initialize REP and SL classes
     */
    public COMM_LCC_InvoiceViewer() {
        this.finacialDocumentSl = new COMM_SL_SAPFinancialDocument();
        this.subInvoiceRep = new COMM_REP_SubscriptionInvoice();
        this.invoiceRep = new COMM_REP_Invoice();
        this.creditMemoRep = new COMM_REP_CreditMemo();
    }

    @TestVisible
    private COMM_LCC_InvoiceViewer(COMM_SL_SAPFinancialDocument finacialDocumentSl, COMM_IREP_SubscriptionInvoice subInvoiceRep, COMM_IREP_Invoice invoiceRep, COMM_IREP_CreditMemo creditMemoRep) {
        this.finacialDocumentSl = finacialDocumentSl;
        this.subInvoiceRep = subInvoiceRep;
        this.invoiceRep = invoiceRep;
        this.creditMemoRep = creditMemoRep;
    }

    /**
     * @description LWC Accessible method to obtain invoice document from SAP
     **/
    @AuraEnabled
    public static String getFileData(String recordId) {
        return new COMM_LCC_InvoiceViewer().handleGetFileData(recordId);
    }

    /**
     * @description Method to obtain the invoice's fiscal document from SAP and return it's Blob data
     * encoded as Base64
     *
     * @param recordId Id of the Subscription Invoice whose Fiscal Document is to be retrieved.
     * @return Fiscal Document encoded in base64
     */
    @TestVisible
    private String handleGetFileData(String recordId) {
        List<SObject> objectList = new List<SObject>();
        Attachment fileRecord;
        if(((Id) recordId).getSObjectType().getDescribe().getName() == 'COMM_SubscriptionInvoice__c'){
            objectList = subInvoiceRep.getSubInvoiceByIds(new Set<Id>{ recordId });
            if (objectList.isEmpty() || String.isBlank((String) objectList[0].get('COMM_SAPNumber__c'))) {
                //Throw Error Message to User if attempting to obtain invoice document when it hasn't been set to SAP yet.
                Exception e = new AuraException(System.Label.COMM_SUBSCRIPTION_INVOICE_NOT_GENERATED_ERROR);
                COMM_GEN_Utility.logError(e, 'Request for SAP document failed to obtain a valid record, ' + recordId, 'COMM_LCC_InvoiceViewer');
                throw e;
            }
            fileRecord = finacialDocumentSl.getFinancialDocument(
                COMM_SL_SAPFinancialDocument.DOCUMENT_TYPE_INVOICE,
                (Date) objectList[0].get('COMM_IssuanceDate__c'),
                (String) objectList[0].get('COMM_SAPNumber__c')
            );
        } else if(((Id) recordId).getSObjectType().getDescribe().getName() == 'Invoice'){
            objectList = invoiceRep.getByIds(new List<String>{ recordId });
            if (objectList.isEmpty() || String.isBlank((String) objectList[0].get('COMM_SAPDocumentId__c')) || ((String) objectList[0].get('COMM_SAPDocumentId__c')) == '-1') {
                //Throw Error Message to User if attempting to obtain invoice document when it hasn't been set to SAP yet.
                Exception e = new AuraException(System.Label.COMM_SUBSCRIPTION_INVOICE_NOT_GENERATED_ERROR);
                COMM_GEN_Utility.logError(e, 'Request for SAP document failed to obtain a valid record, ' + recordId, 'COMM_LCC_InvoiceViewer');
                throw e;
            }
            fileRecord = finacialDocumentSl.getFinancialDocument(
                COMM_SL_SAPFinancialDocument.DOCUMENT_TYPE_INVOICE,
                (Date) objectList[0].get('COMM_IssuanceDate__c'),
                (String) objectList[0].get('COMM_SAPDocumentId__c')
            );
        } else if(((Id) recordId).getSObjectType().getDescribe().getName() == 'CreditMemo'){
            objectList = creditMemoRep.getByIds(new List<String>{ recordId });
            if (objectList.isEmpty() || String.isBlank((String) objectList[0].get('COMM_SAPDocumentId__c')) || ((String) objectList[0].get('COMM_SAPDocumentId__c')) == '-1') {
                //Throw Error Message to User if attempting to obtain invoice document when it hasn't been set to SAP yet.
                Exception e = new AuraException(System.Label.COMM_CREDIT_MEMO_NOT_GENERATED_ERROR);
                COMM_GEN_Utility.logError(e, 'Request for SAP document failed to obtain a valid record, ' + recordId, 'COMM_LCC_InvoiceViewer');
                throw e;
            }
            fileRecord = finacialDocumentSl.getFinancialDocument(
                COMM_SL_SAPFinancialDocument.DOCUMENT_TYPE_CREDIT,
                (Date) objectList[0].get('COMM_IssuanceDate__c'),
                (String) objectList[0].get('COMM_SAPDocumentId__c')
            );
        }

        return EncodingUtil.Base64Encode(fileRecord.Body);
    }
}