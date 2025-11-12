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
 * Hugo Manera      28/05/2025       New method: getForSearchInvoice
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

    public List<Invoice> getForSearchInvoice(COMM_WS_SearchInvoicesInput inputRequest, String invoiceExtraFilter) {
        FW_QueryBuilder invoiceLineQuery = new FW_QueryBuilder(InvoiceLine.SObjectType)
            .selectFields(new List<SObjectField>{ InvoiceLine.Name })
            .selectParentFields(InvoiceLine.Product2Id, new List<SObjectField>{ Product2.COMM_Airport__c });

        FW_QueryBuilder invoiceQuery = new FW_QueryBuilder(Invoice.SObjectType)
            .selectFields(
                new List<SObjectField>{
                    Invoice.id,
                    Invoice.Status,
                    Invoice.DocumentNumber,
                    Invoice.InvoiceDate,
                    Invoice.DueDate,
                    Invoice.TotalAmountWithTax,
                    Invoice.COMM_SAPDocumentId__c
                }
            )
            .selectParentFields(Invoice.BillingAccountId, new List<SObjectField>{ Account.PersonEmail, Account.Name });

        // Add extra filter first (base filter)
        if (String.isNotBlank(invoiceExtraFilter)) {
            invoiceQuery.setWhere(invoiceExtraFilter);
        }

        // Apply date filters using consistent pattern with proper null checks and formatting
        if (inputRequest.invoiceStartDate != null && inputRequest.invoiceEndDate != null) {
            String dateFilter =
                'InvoiceDate >= ' +
                String.valueOf(inputRequest.invoiceStartDate) +
                ' AND InvoiceDate <= ' +
                String.valueOf(inputRequest.invoiceEndDate.addDays(1));

            if (String.isNotBlank(invoiceExtraFilter)) {
                invoiceQuery.setWhere(invoiceExtraFilter + ' AND ' + dateFilter);
            } else {
                invoiceQuery.setWhere(dateFilter);
            }
        }

        // Apply individual field filters using proper query builder methods
        if (String.isNotBlank(inputRequest.sapDocumentId)) {
            invoiceQuery.whereEquals('COMM_SAPDocumentId__c', String.escapeSingleQuotes(inputRequest.sapDocumentId));
        }

        if (inputRequest.status != null && !inputRequest.status.isEmpty()) {
            // Sanitize status values to prevent injection
            List<String> sanitizedStatus = new List<String>();
            for (String status : inputRequest.status) {
                if (String.isNotBlank(status)) {
                    sanitizedStatus.add(String.escapeSingleQuotes(status));
                }
            }
            if (!sanitizedStatus.isEmpty()) {
                invoiceQuery.whereIn('Status', sanitizedStatus);
            }
        }

        invoiceQuery.orderByDesc(Invoice.InvoiceDate);
        invoiceQuery.orderByAsc(Invoice.Status);

        // Build final query with proper escaping and validation
        String baseQuery = invoiceQuery.getQuery();
        String subQuery = invoiceLineQuery.getQuery();

        // Validate query components before string manipulation
        if (String.isBlank(baseQuery) || String.isBlank(subQuery)) {
            throw new QueryException('Invalid query construction: base or sub query is empty');
        }
        subQuery = subQuery.replace('FROM', ', TYPEOF ReferenceEntityItem WHEN OrderItemSummary THEN COMM_AffiliateNumber__c END FROM');
        String query = baseQuery.replace(' FROM', ', TYPEOF ReferenceEntity WHEN OrderSummary THEN OrderNumber END, (' + subQuery + ') FROM');
        query = query.replaceAll('\\bInvoiceLine\\b', 'InvoiceLines');
        query = query.replace('ORDER BY', 'WITH SECURITY_ENFORCED ORDER BY');

        return Database.query(query);
    }

    /**
     * @description Custom exception for query validation errors
     */
    public class QueryException extends Exception {
    }
}