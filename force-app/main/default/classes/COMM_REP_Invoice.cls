/**
 * @author Rui Salgado
 * @description Invoice selector class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Rui Salgado      19/04/2024       Added method getAllInvoiceBasedOnStatus
 * Daniel Reto      03/06/2024       New method: getForSAPInvoice
 * Daniel Reto      08/07/2024       New fields added on getByIds method
 **/
public inherited sharing class COMM_REP_Invoice extends FW_SobjectRep implements COMM_IREP_Invoice {
    /**
     * @description Selects Invoice records based on the Id list
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     */
    public List<Invoice> getByIds(List<String> invoiceIds) {
        return [
            SELECT Id, ReferenceEntityId, Status, Balance, COMM_SAPDocumentId__c, COMM_IssuanceDate__c
            FROM Invoice
            WHERE Id IN :invoiceIds
            WITH SECURITY_ENFORCED
        ];
    }
    /**
     * @description Selects Invoice to communicate with CPMS
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     */
    public List<Invoice> getForCPMS(List<Id> invoiceIds, String family, String productType) {
        return [
            SELECT
                Id,
                Balance,
                Status,
                TYPEOF ReferenceEntity
                    WHEN OrderSummary THEN ID
                END,
                (
                    SELECT
                        Id,
                        Quantity,
                        ChargeAmountWithTax,
                        ReferenceEntityItemId,
                        Product2.Id,
                        Product2.COMM_Airport__c,
                        Product2.COMM_Park__c,
                        Product2.COMM_CPMS__c
                    FROM InvoiceLines
                    WHERE Product2.Family = :family AND Type = :productType
                )
            FROM Invoice
            WHERE id IN :invoiceIds
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Selects Invoice records to send to SAP based on the Id list
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     **/
    public List<Invoice> getForSAPInvoice(List<String> invoiceIds) {
        return [
            SELECT
                id,
                Status,
                DocumentNumber,
                DueDate,
                TotalAmount,
                COMM_SAPCount__c,
            	COMM_SAPDocumentId__c,
                COMM_InvoiceEditCount__c,
                TotalTaxAmount,
                BillingAccount.Name,
                BillingAccount.COMM_Email__c,
                BillingAccount.PersonEmail,
                BillingAccount.COMM_VATNumber__c,
                TYPEOF ReferenceEntity
                    WHEN OrderSummary THEN
                        ID,
                        SalesChannel.SalesChannelName,
                        COMM_SalesType__c,
                        OrderedDate,
                        BillingStreet,
                        BillingPostalCode,
                        BillingCity,
                        BillingCountryCode,
                        BillingEmailAddress,
                        COMM_BillingVATNumber__c,
                        COMM_BillingName__c

                END,
                (
                    SELECT
                        Id,
                        Product2.Id,
                        Product2.StockKeepingUnit,
                        Product2.COMM_SAPLocation__c,
                        Product2.COMM_Tax__c,
                        TYPEOF ReferenceEntityItem
                            WHEN OrderItemSummary THEN Description
                        END,
                        Quantity,
                        LineAmount,
                        RelatedLineId,
                        ReferenceEntityItemType,
                        Type
                    FROM InvoiceLines
                )
            FROM Invoice
            WHERE id IN :invoiceIds
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Selects Invoice records to send to SAP based on the Id list
     * @param invoiceIds Set of the Ids
     * @param dateClause Date Clause to include on Query
     * @return List of Invoice
     **/
    public List<Invoice> getForSAPInvoice(Set<Id> invoiceIds, String dateClause) {
        String relatedRecordStatus = 'Posted';
        return (List<Invoice>) Database.query(
            'SELECT ' +
                'Id, ' +
                'Status, ' +
                'DocumentNumber, ' +
                'DueDate, ' +
                'TotalAmount, ' +
                'COMM_SAPCount__c, ' +
                'COMM_SAPDocumentId__c, ' +
                'COMM_InvoiceEditCount__c, ' +
                'TotalTaxAmount, ' +
                'BillingAccountId, ' +
                'BillingAccount.Name, ' +
                'BillingAccount.COMM_Email__c, ' +
                'BillingAccount.PersonEmail, ' +
                'BillingAccount.COMM_VATNumber__c, ' +
                'TYPEOF ReferenceEntity ' +
                'WHEN OrderSummary THEN ' +
                'ID, ' +
                'SalesChannel.SalesChannelName, ' +
                'COMM_SalesType__c, ' +
                'OrderedDate, ' +
                'BillingStreet, ' +
                'BillingPostalCode, ' +
                'BillingCity, ' +
                'BillingCountryCode, ' +
                'BillingEmailAddress, ' +
                'COMM_BillingVATNumber__c, ' +
                'COMM_BillingName__c ' +
                'END, ' +
                '( ' +
                'SELECT ' +
                'Id, ' +
                'Product2.Id, ' +
                'Product2.StockKeepingUnit, ' +
                'Product2.COMM_SAPLocation__c, ' +
                'Product2.COMM_Tax__c, ' +
                'TYPEOF ReferenceEntityItem ' +
                'WHEN OrderItemSummary THEN Description ' +
                'END, ' +
                'Quantity, ' +
                'LineAmount, ' +
                'RelatedLineId, ' +
                'ReferenceEntityItemType, ' +
                'Type ' +
                'FROM InvoiceLines ' +
                ') ' +
                'FROM Invoice ' +
                'WHERE ' +
                'Id IN :invoiceIds ' +
                'AND ( COMM_SAPDocumentId__c  = null OR COMM_SAPDocumentId__c  = \'-1\' ) ' +
                'AND Status =: relatedRecordStatus ' +
                'AND Balance = 0 ' +
                'AND ' +
                dateClause.replaceAll('CreatedDate', 'DueDate') +
                ' WITH SECURITY_ENFORCED'
        );
    }
}