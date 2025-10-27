/**
 * @author Diogo Gonçalves
 * @description CreditMemo repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    30/04/2024       Original version
 * Daniel Reto        28/05/2024       New method: getForSAPCreditMemo
 * Daniel Reto        03/06/2024       New method: getForSAPCreditMemo
 * Daniel Reto        08/07/2024       New fields added on getByIds method
 **/
public inherited sharing class COMM_REP_CreditMemo extends FW_SobjectRep implements COMM_IREP_CreditMemo {
    /**
     * @description Retrieve a list of CreditMemo by a set of <SObjectName>  Ids
     *
     * @param ids - Set of Ids to query
     * @return List of CreditMemo Records found
     **/
    public List<CreditMemo> getByIds(List<String> ids) {
        return [
            SELECT Id, ReferenceEntityId, COMM_SAPDocumentId__c, COMM_IssuanceDate__c
            FROM CreditMemo
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }

    /**
     * @description Selects Credit Memo records to send to SAP based on the Id list
     * @param creditMemoIds List of the Ids
     * @return List of Credit Memo
     **/
    public List<CreditMemo> getForSAPCreditMemo(List<String> creditMemoIds) {
        return [
            SELECT
                id,
                Status,
                DocumentNumber,
                CreditDate,
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
                        LineAmount,
                        RelatedLineId,
                        ReferenceEntityItemType,
                        Type
                    FROM CreditMemoLines
                )
            FROM CreditMemo
            WHERE Id IN :creditMemoIds
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Selects Credit Memo records to send to SAP based on the Id list and Date
     * @param creditMemoIds List of the Ids
     * @param dateClause Date Clause to include on Query
     * @return List of Credit Memo
     **/
    public List<CreditMemo> getForSAPCreditMemo(Set<Id> creditMemoIds, String dateClause) {
        String relatedRecordStatus = 'Posted';
        return (List<CreditMemo>) Database.query(
            'SELECT ' +
                'Id, ' +
                'Status, ' +
                'DocumentNumber, ' +
                'CreditDate, ' +
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
                'LineAmount, ' +
                'RelatedLineId, ' +
                'ReferenceEntityItemType, ' +
                'Type ' +
                'FROM CreditMemoLines ' +
                ') ' +
                'FROM CreditMemo ' +
                'WHERE ' +
                'Id IN :creditMemoIds ' +
                'AND ( COMM_SAPDocumentId__c  = null OR COMM_SAPDocumentId__c  = \'-1\' ) ' +
                'AND Status =: relatedRecordStatus ' +
                'AND Balance = 0 ' +
                'AND ' +
                dateClause.replaceAll('CreatedDate', 'CreditDate') +
                ' WITH SECURITY_ENFORCED'
        );
    }
}