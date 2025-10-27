/**
 * @author Daniel Lascas
 * @description Account repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    22/02/2024       Original version
 **/
public interface COMM_IREP_Account extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Person Accounts by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Person Accounts Records found
     **/
    List<Account> getPersonAccountsByIds(Set<Id> accountIds);
    /**
     * @description Retrieve a list of Accounts by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    List<Account> getAccountByIds(Set<Id> accountIds);
    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices that haven't been sent to SAP
     * based on a where clause
     *
     * @param accountIds Set of Account Ids to restrict query (only used if set isn't empty)
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 month ago 'CreatedDate = N_MONTHS_AGO:1')
     * @return List of Accounts Records found with subscription invoices
     */
    List<Account> getPartnerAccountsAndInvoicesByDateLiteral(Set<String> accountIds, String dateClause);
    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices that haven't been sent to SAP
     * based on a where clause
     *
     * @param accountIds Ids of Partner Accounts
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 2 months ago 'CreatedDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with subscription invoices
     */
    List<Account> getAccountsAndInvoicesByIdsAndDateLiteral(Set<Id> accountIds, String dateClause);
    /**
     * @description Retrieve a list of Affiliate Accounts by a set of Account Ids with invoices and credit memos that haven't been sent to SAP
     * based on a where clause
     *
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 months ago 'CreditDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with Invoices and Credit Memos
     */
    List<Account> getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteral(String dateClause);
    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices and credit memos that haven't been sent to SAP
     * based on a where clause
     *
     * @param accountIds Ids of Partner Accounts
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 months ago 'CreditDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with subscription invoices
     */
    List<Account> getAccountsByIdsWithInvoicesAndCreditMemos(Set<Id> accountIds, String dateClause);
    /**
     * @description Retrieve a list of Accounts with fields required for
     * OCAPI requests by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    List<Account> getAccountWithRequestFieldsByIds(Set<Id> accountIds);
    /**
     * @description Retrieve a list of Reseller Account and their Assortment Products by a reseller Id
     *
     * @param resellerId Id of the Reseller Account
     * @param airportCode Airport the Products are associated with (Opcional, use null to retrieve all)
     * @param category The Category the Products to retrieve belong to (Opcional, use null to retrieve all)
     * @return List of Reseller Account Record with related Assortment Products
     */
    List<Account> getResellerAccountProducts(String resellerId, String airportCode, String category);
    /**
     * @description Retrieve a list of Accounts with associated orders
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    List<Account> getAccountsAndOrdersByIds(Set<Id> accountIds);
    /**
     * @description Retrieve a list of Accounts by a set of Account Ids that are resellers
     * @param ids Account Ids
     * @return List of accounts that are set as Reseller
     */
    List<Account> getResellers(List<String> resellerIds);
}