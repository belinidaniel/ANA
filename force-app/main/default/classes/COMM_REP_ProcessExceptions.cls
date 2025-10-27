/**
 * @author Rui Salgado
 * @description Process Exception selector class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Daniel Reto      04/06/2024       Original version
 **/
public inherited sharing class COMM_REP_ProcessExceptions extends FW_SobjectRep implements COMM_IREP_ProcessExceptions {
    /**
     * @description Selects ProcessException records
     * @param category Category
     * @param attachedTo Attached to salesforce id
     * @param orderSummaryId Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<ProcessException> getByCategoryAttachedStatus(String category, String attachedTo, String orderSummaryId, List<String> oldStatus) {
        return [
            SELECT Id
            FROM ProcessException
            WHERE category = :category AND attachedToId = :attachedTo AND OrderSummaryId = :orderSummaryId AND Status IN :oldStatus
            WITH USER_MODE
        ];
    }
    
    /**
     * @description Selects ProcessException records
     * @param category Category
     * @param attachedToSet set of Attached to salesforce id
     * @param orderSummaryIdSet  Set of Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<ProcessException> getByCategoryAttachedStatusBulk(String category, Set<String> attachedToSet, Set<String> orderSummaryIdSet, List<String> oldStatus) {
        return [
            SELECT Id
            FROM ProcessException
            WHERE category = :category AND attachedToId IN :attachedToSet AND OrderSummaryId IN :orderSummaryIdSet AND Status IN :oldStatus
            WITH USER_MODE
        ];
    }

    /**
     * @description Selects ProcessException records
     * @param category Category
     * @param orderSummaryIds List of Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    public List<ProcessException> getByOrderSummary(String category, List<String> orderSummaryIds, List<String> oldStatus) {
        return [
            SELECT Id
            FROM ProcessException
            WHERE category = :category AND OrderSummaryId IN :orderSummaryIds AND Status IN :oldStatus
            WITH USER_MODE
        ];
    }

    /**
     * @description Selects ProcessException records by attatched Id
     * @param category Category
     * @param attatchedToIds List of Attatched Ids
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    public List<ProcessException> getByAttatched(String category, List<String> attatchedToIds, List<String> oldStatus) {
        return [
            SELECT Id
            FROM ProcessException
            WHERE category = :category AND attachedToId IN :attatchedToIds AND Status IN :oldStatus
            WITH USER_MODE
        ];
    }

    /**
     * @description Selects ProcessException linked to Invoice or Credit Memos
     * @param category Category
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    public List<ProcessException> getInvoiceCreditMemo(String category, List<String> oldStatus) {
        return [
            SELECT
                Id,
                Status,
                AttachedToId,
                TYPEOF AttachedTo
                    WHEN Invoice THEN ID, COMM_SAPCount__c, COMM_SAPDocumentId__c, ReferenceEntityId
                    WHEN CreditMemo THEN ID, COMM_SAPCount__c, COMM_SAPDocumentId__c, ReferenceEntityId
                END
            FROM ProcessException
            WHERE Category = :category AND Status IN :oldStatus
            WITH USER_MODE
        ];
    }
}