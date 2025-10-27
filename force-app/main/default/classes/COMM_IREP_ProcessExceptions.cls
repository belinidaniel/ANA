/**
 * @author Rui Salgado
 * @description Process Exception selector interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Diogo Gonçalves  10/05/2024       ECOMM-133: Added getByOrderSummary
 * Daniel Reto      04/06/2024       Added getByCategoryAttachedStatusBulk
 **/
@SuppressWarnings('PMD.ExcessiveParameterList')
public interface COMM_IREP_ProcessExceptions extends FW_ISObjectRep {
    /**
     * @description Selects ProcessException records
     * @param category Category
     * @param attachedTo Attached to salesforce id
     * @param orderSummaryId Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    List<ProcessException> getByCategoryAttachedStatus(String category, String attachedTo, String orderSummaryId, List<String> oldStatus);
/**
     * @description Selects ProcessException records
     * @param category Category
     * @param attachedToSet set of Attached to salesforce id
     * @param orderSummaryIdSet  Set of Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    List<ProcessException> getByCategoryAttachedStatusBulk(String category, Set<String> attachedToSet, Set<String> orderSummaryIdSet, List<String> oldStatus);

    /**
     * @description Selects ProcessException records
     * @param category Category
     * @param orderSummaryId Order Summary Id
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    List<ProcessException> getByOrderSummary(String category, List<String> orderSummaryIds, List<String> oldStatus);

    /**
     * @description Selects ProcessException records by attatched Id
     * @param category Category
     * @param attatchedToIds List of Attatched Ids
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    List<ProcessException> getByAttatched(String category, List<String> attatchedToIds, List<String> oldStatus);

    /**
     * @description Selects ProcessException linked to Invoice or Credit Memos
     * @param category Category
     * @param oldStatus Status
     * @return List of ProcessExceptions
     */
    List<ProcessException> getInvoiceCreditMemo(String category, List<String> oldStatus);
}