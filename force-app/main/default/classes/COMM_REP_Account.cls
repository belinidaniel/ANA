/**
 * @author Daniel Lascas
 * @description Account repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    22/02/2024       Original version
 * Daniel Lascas    08/03/2024       Added method getAccountByIds
 **/
public inherited sharing class COMM_REP_Account extends FW_SobjectRep implements COMM_IREP_Account {
    /**
     * @description Retrieve a list of Person Accounts by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Person Accounts Records found
     **/
    public List<Account> getPersonAccountsByIds(Set<Id> accountIds) {
        return [SELECT Id, PersonContactId FROM Account WHERE Id IN :accountIds AND IsPersonAccount = TRUE WITH USER_MODE];
    }
    /**
     * @description Retrieve a list of Accounts by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    public List<Account> getAccountByIds(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                Name,
                Phone,
                BillingAddress,
                BillingStreet,
                BillingPostalCode,
                BillingCity,
                BillingCountryCode,
                IsPersonAccount,
                RecordTypeId,
                COMM_Email__c,
                COMM_IsPartner__c,
                COMM_IsAffiliate__c,
                COMM_IndividualStaff__c,
                COMM_PaymentMethod__c,
                COMM_VATNumber__c,
                COMM_PreferredContact__c,
                COMM_MarketingAndCommunicationConsent__c
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices that haven't been sent to SAP
     * based on a where clause
     * @example SELECT Id,(SELECT Id,CreatedDate FROM SubscriptionInvoices__r WHERE :dateClause AND COMM_SAPNumber__c = null
     * AND COMM_MonthlyFiscalDocumentControl__c = null) FROM Account WHERE Type = 'Partner' AND Id in :accountIds WITH USER_MODE
     *
     * @param accountIds Set of Account Ids to restrict query (only used if set isn't empty)
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 months ago 'CreatedDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with subscription invoices
     */
    public List<Account> getPartnerAccountsAndInvoicesByDateLiteral(Set<String> accountIds, String dateClause) {
        //Build Query using Framework's Query Builder to help clean where clause
        FW_QueryBuilder queryBuilder = new FW_QueryBuilder(Account.sObjectType)
            .selectFields(new List<SObjectField>{ Account.Id })
            .selectSubquery(
                'SubscriptionInvoices__r',
                new List<SObjectField>{ COMM_SubscriptionInvoice__c.Id, COMM_SubscriptionInvoice__c.CreatedDate }
            )
            .setWhere(dateClause)
            .whereEquals(COMM_SubscriptionInvoice__c.COMM_SAPNumber__c, null)
            .whereEquals(COMM_SubscriptionInvoice__c.COMM_MonthlyFiscalDocumentControl__c, null)
            .getParent()
            .whereEquals(Account.Type, COMM_DO_Account.TYPE_PARTNER);
        if (!accountIds.isEmpty()) {
            queryBuilder.whereIn(Account.Id, new List<String>(accountIds));
        }
        String query = queryBuilder.getQuery() + ' WITH USER_MODE';
        return (List<Account>) Database.query(query);
    }

    /**
     * @description Retrieve a list of Affiliate Accounts by a set of Account Ids with invoices and credit memos that haven't been sent to SAP
     * based on a where clause
     *
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 months ago 'CreditDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with Invoices and Credit Memos
     */
    public List<Account> getAffiliateAccountsWithInvoicesAndCreditMemosByDateLiteral(String dateClause) {
        String relatedRecordStatus = 'Posted';
        return (List<Account>) Database.query(
            'SELECT Id, (SELECT Id, DueDate, TYPEOF ReferenceEntity WHEN OrderSummary THEN COMM_SalesType__c END FROM Invoices WHERE DueDate = ' +
                String.escapeSingleQuotes(dateClause) +
                ' AND ( COMM_SAPDocumentId__c = NULL OR COMM_SAPDocumentId__c = \'-1\' ) AND Status =: relatedRecordStatus AND Balance = 0), (SELECT Id, CreditDate, TYPEOF ReferenceEntity WHEN OrderSummary THEN COMM_SalesType__c END FROM CreditMemos WHERE CreditDate = ' +
                String.escapeSingleQuotes(dateClause) +
                ' AND ( COMM_SAPDocumentId__c = NULL OR COMM_SAPDocumentId__c = \'-1\' ) AND Status =: relatedRecordStatus AND Balance = 0) FROM Account WHERE COMM_IsAffiliate__c = TRUE WITH USER_MODE'
        );
    }

    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices that haven't been sent to SAP
     * based on a where clause
     *
     * @example SELECT Id,Name,BillingStreet,BillingPostalCode,BillingCity,BillingCountryCode,COMM_VATNumberWithCode__c,IsPersonAccount,PersonEmail,COMM_Email__c,
     * COMM_StaffCompanyRatio__c,COMM_OfficialEntityRatio__c (SELECT Id,CreatedDate,COMM_Subscripton__c,COMM_TaxAmount__c,COMM_TaxCode__c,COMM_SubscriptionAmount__c,
     * COMM_SubscriptionAmountWithoutTax__c,COMM_CardAmount__c,COMM_CardAmountWithoutTax__c,COMM_CardTaxCode__c,COMM_CardTaxAmount__c,COMM_ExemptPayment__c,
     * COMM_SubscriptonProduct__r.Name,COMM_SubscriptonProduct__r.ProductCode,COMM_SubscriptonProduct__r.Description,COMM_SubscriptonProduct__r.COMM_Airport__c,
     * COMM_SubscriptonProduct__r.COMM_Park__c,COMM_SubscriptonProduct__r.COMM_Tax__c,COMM_SubscriptonProduct__r.COMM_SAPLocation__c,
     * COMM_SubscriptonProduct__r.COMM_SubCategory__c,COMM_CardProduct__r.Name,COMM_CardProduct__r.ProductCode,COMM_CardProduct__r.Description,
     * COMM_CardProduct__r.COMM_Airport__c,COMM_CardProduct__r.COMM_Tax__c, COMM_CardProduct__r.COMM_SAPLocation__c
     * FROM SubscriptionInvoices__r WHERE :dateClause AND COMM_SAPNumber__c = null ORDER BY COMM_SubscriptonProduct__r.COMM_Airport__c ASC,
     * COMM_SubscriptonProduct__r.COMM_Park__c ASC,COMM_SubscriptionAmount__c DESC) FROM Account WHERE Id IN :accountIds AND Type = 'Partner' WITH USER_MODE
     *
     * @param accountIds Ids of Partner Accounts
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 2 months ago 'CreatedDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with subscription invoices
     */
    public List<Account> getAccountsAndInvoicesByIdsAndDateLiteral(Set<Id> accountIds, String dateClause) {
        //Build Query using Framework's Query Builder to help clean where clause
        String query = new FW_QueryBuilder(Account.sObjectType)
            .selectFields(
                new List<SObjectField>{
                    Account.Id,
                    Account.Name,
                    Account.BillingStreet,
                    Account.BillingPostalCode,
                    Account.BillingCity,
                    Account.BillingCountryCode,
                    Account.COMM_VATNumberWithCode__c,
                    Account.IsPersonAccount,
                    Account.PersonEmail,
                    Account.COMM_Email__c,
                    Account.COMM_StaffCompanyRatio__c,
                    Account.COMM_OfficialEntityRatio__c
                }
            )
            .selectSubquery(
                'SubscriptionInvoices__r',
                new List<SObjectField>{
                    COMM_SubscriptionInvoice__c.Id,
                    COMM_SubscriptionInvoice__c.CreatedDate,
                    COMM_SubscriptionInvoice__c.COMM_Subscripton__c,
                    COMM_SubscriptionInvoice__c.COMM_TaxAmount__c,
                    COMM_SubscriptionInvoice__c.COMM_TaxCode__c,
                    COMM_SubscriptionInvoice__c.COMM_SubscriptionAmount__c,
                    COMM_SubscriptionInvoice__c.COMM_SubscriptionAmountWithoutTax__c,
                    COMM_SubscriptionInvoice__c.COMM_CardAmount__c,
                    COMM_SubscriptionInvoice__c.COMM_CardAmountWithoutTax__c,
                    COMM_SubscriptionInvoice__c.COMM_CardTaxCode__c,
                    COMM_SubscriptionInvoice__c.COMM_CardTaxAmount__c,
                    COMM_SubscriptionInvoice__c.COMM_ExemptPayment__c,
                    COMM_SubscriptionInvoice__c.COMM_MonthlyFiscalDocumentControl__c
                }
            )
            .selectParentFields(
                COMM_SubscriptionInvoice__c.COMM_SubscriptonProduct__c,
                new List<SObjectField>{
                    Product2.Name,
                    Product2.ProductCode,
                    Product2.Description,
                    Product2.COMM_Airport__c,
                    Product2.COMM_Park__c,
                    Product2.COMM_Tax__c,
                    Product2.COMM_SAPLocation__c,
                    Product2.COMM_SubCategory__c
                }
            )
            .selectParentFields(
                COMM_SubscriptionInvoice__c.COMM_CardProduct__c,
                new List<SObjectField>{
                    Product2.Name,
                    Product2.ProductCode,
                    Product2.Description,
                    Product2.COMM_Airport__c,
                    Product2.COMM_Tax__c,
                    Product2.COMM_SAPLocation__c
                }
            )
            .selectParentFields(COMM_SubscriptionInvoice__c.COMM_Subscripton__c, new List<SObjectField>{ COMM_Subscription__c.COMM_PaymentMethod__c })
            .setWhere(dateClause)
            .whereEquals(COMM_SubscriptionInvoice__c.COMM_SAPNumber__c, null)
            .orderByAsc('COMM_SubscriptonProduct__r.COMM_Airport__c')
            .orderByAsc('COMM_SubscriptonProduct__r.COMM_Park__c ')
            .orderByDesc(COMM_SubscriptionInvoice__c.COMM_SubscriptionAmount__c)
            .getParent()
            .whereIn(Account.Id, new List<Id>(accountIds))
            .whereEquals(Account.Type, COMM_DO_Account.TYPE_PARTNER)
            .getQuery();
        query += ' WITH USER_MODE';
        return (List<Account>) Database.query(query);
    }

    /**
     * @description Retrieve a list of Partner Accounts by a set of Account Ids with invoices and credit memos that haven't been sent to SAP
     * based on a where clause
     *
     * @param accountIds Ids of Partner Accounts
     * @param dateClause Clause to use for checking dates (ex to retrieve invoice created 1 months ago 'CreditDate = N_MONTHS_AGO:2')
     * @return List of Accounts Records found with subscription invoices
     */
    public List<Account> getAccountsByIdsWithInvoicesAndCreditMemos(Set<Id> accountIds, String dateClause) {
        //Build Query using Framework's Query Builder to help clean where clause
        String query = new FW_QueryBuilder(Account.sObjectType)
            .selectFields(
                new List<SObjectField>{
                    Account.Id,
                    Account.BillingStreet,
                    Account.BillingPostalCode,
                    Account.BillingCity,
                    Account.BillingCountryCode,
                    Account.COMM_BillingFirstName__c,
                    Account.COMM_BillingLastName__c,
                    Account.COMM_VATNumber__c,
                    Account.IsPersonAccount,
                    Account.Name,
                    Account.PersonEmail,
                    Account.COMM_Email__c,
                    Account.COMM_StaffCompanyRatio__c,
                    Account.COMM_OfficialEntityRatio__c
                }
            )
            .selectSubquery('Invoices', new List<SObjectField>{ Invoice.Id })
            .setWhere(dateClause)
            .getParent()
            .selectSubquery('CreditMemos', new List<SObjectField>{ CreditMemo.Id })
            .setWhere(dateClause)
            .getParent()
            .whereIn(Account.Id, new List<Id>(accountIds))
            .whereEquals(Account.COMM_IsAffiliate__c, true)
            .getQuery();
        query += ' WITH USER_MODE';
        System.debug(query);
        return (List<Account>) Database.query(query);
    }

    /**
     * @description Retrieve a list of Accounts with fields required for
     * OCAPI requests by a set of Account Ids
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    public List<Account> getAccountWithRequestFieldsByIds(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                IsPersonAccount,
                PersonEmail,
                PersonContactId,
                COMM_Email__c,
                COMM_IntegrationRequestBody__c,
                COMM_CustomerNumber__pc,
                (SELECT Id, Email, COMM_CustomerNumber__c FROM Contacts)
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieve a list of Reseller Account and their Assortment Products by a reseller Id
     * @example SELECT Id,COMM_IsReseller__c,(SELECT Id,COMM_AvailableDailyQuantity__c,COMM_PriceBook__c,
     * COMM_Product__c,COMM_Product__r.Name,COMM_Product__r.ProductCode,COMM_Product__r.Family,
     * COMM_Product__r.COMM_Airport__c,COMM_Product__r.COMM_ProductType__c,COMM_Product__r.COMM_ValidFrom__c,
     * COMM_Product__r.COMM_ValidTo__c FROM ResellerAssortments__r WHERE COMM_Active__c = true AND
     * COMM_Product__r.COMM_Airport__c = :airportCode AND COMM_Product__r.Family = :category ORDER BY Name ASC)
     * FROM Account WHERE Id = :resellerId WITH USER_MODE
     *
     * @param resellerId Id of the Reseller Account
     * @param airportCode Airport the Products are associated with (Opcional, use null to retrieve all)
     * @param category The Category the Products to retrieve belong to (Opcional, use null to retrieve all)
     * @return List of Reseller Account Record with related Assortment Products
     */
    public List<Account> getResellerAccountProducts(String resellerId, String airportCode, String category) {
        //Build Query using Framework's Query Builder for dinamic query
        FW_QueryBuilder queryBuilder = new FW_QueryBuilder(Account.sObjectType)
            .selectFields(new List<SObjectField>{ Account.Id, Account.COMM_IsReseller__c })
            .selectSubquery(
                'ResellerAssortments__r',
                new List<SObjectField>{
                    COMM_ResellerAssortment__c.Id,
                    COMM_ResellerAssortment__c.COMM_AvailableDailyQuantity__c,
                    COMM_ResellerAssortment__c.COMM_DailyLimit__c,
                    COMM_ResellerAssortment__c.COMM_PriceBook__c,
                    COMM_ResellerAssortment__c.COMM_Product__c
                }
            )
            .selectParentFields(
                COMM_ResellerAssortment__c.COMM_Product__c,
                new List<SObjectField>{
                    Product2.Name,
                    Product2.ProductCode,
                    Product2.Family,
                    Product2.COMM_Airport__c,
                    Product2.COMM_ProductType__c,
                    Product2.COMM_ValidFrom__c,
                    Product2.COMM_ValidTo__c,
                    Product2.COMM_ParentProduct__c,
                    Product2.COMM_ParentProductCode__c
                }
            )
            .whereEquals(COMM_ResellerAssortment__c.COMM_Active__c, true)
            .orderByAsc(COMM_ResellerAssortment__c.Name);

        //Add provided opcional filters to query
        if (String.isNotBlank(airportCode)) {
            queryBuilder.whereEquals('COMM_Product__r.COMM_Airport__c', airportCode);
        }
        if (String.isNotBlank(category)) {
            queryBuilder.whereEquals('COMM_Product__r.Family', category);
        }

        //Add Reseller Id to Query
        String query = queryBuilder.getParent().whereEquals(Account.COMM_ResellerId__c, resellerId).getQuery();
        //Add USER_MODE Security
        query += ' WITH USER_MODE';

        return (List<Account>) Database.query(query);
    }

    /**
     * @description Retrieve a list of Accounts with associated orders
     *
     * @param accountIds Set of Account Ids to query
     * @return List of Accounts Records found
     **/
    public List<Account> getAccountsAndOrdersByIds(Set<Id> accountIds) {
        return [
            SELECT Id, (SELECT Id FROM Orders)
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of Accounts by a set of Account Ids that are resellers
     * @param ids Account Ids
     * @return List of accounts that are set as Reseller
     */
    public List<Account> getResellers(List<String> resellerIds) {
        return [
            SELECT Id, Name, COMM_Email__c
            FROM Account
            WHERE COMM_IsReseller__c = TRUE AND COMM_ResellerId__c IN :resellerIds
            WITH SECURITY_ENFORCED
        ];
    }
}