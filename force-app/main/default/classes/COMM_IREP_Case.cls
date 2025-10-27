/**
 * @author           Daniel Lascas
 * @description      Case repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/03/2024       ECOMM-368: Original version
 * Daniel Lascas    18/03/2024       ECOMM-194: Added getSubscriptionCaseByIds
 **/
public interface COMM_IREP_Case extends FW_ISObjectRep {
    /**
     * @description Query Cases of Record Type "Individual Staff Request" that are on "In Pending"
     * status associated with a set of Accounts
     *
     * @param accountIds Set of Account Id's to find Cases related to it
     * @param securityEnforced Uses the security enforced clause or not.
     * @return List of Queried Case Records
     */
    List<Case> getIndividualStaffRequestPendingByAccountId(Set<Id> accountIds, Boolean securityEnforced);
    /**
     * @description Query Subscription Cases with a set of Ids
     *
     * @param caseIds Set of Case Id's to query
     * @param securityEnforced Uses the security enforced clause or not.
     * @return List of Queried Case Records
     */
    List<Case> getSubscriptionCaseByIds(Set<Id> caseIds, Boolean securityEnforced);
    /**
     * @description Query Cases by specified identifiers
     *
     * @param caseIds Set of Case Id's
     * @return List of Queried Case Records
     */
    List<Case> getCasesByCaseIds(Set<Id> caseIds);
}