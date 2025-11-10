/**
 * @description      Controller to manage the external managed account
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo    25/02/2024       Original version
 *
 **/
public with sharing class COMM_LCC_ExternalManagedAccount {
    /**
     * @description Get External Managed Accounts.
     *
     * @param communityId the community id.
     * @return Account List.
     */
    @AuraEnabled
    public static List<ExternalManagedAccountWrapper> getExternalManagedAccounts(String communityId) {
        try {
            // Retrieve the external managed accounts from the service layer
            List<ConnectApi.ExternalManagedAccountOutput> externalAccounts = COMM_SL_ExternalManagedAccounts.handleExternalManagedAccounts(
                communityId
            );

            List<ExternalManagedAccountWrapper> wrappedAccountsList = new List<ExternalManagedAccountWrapper>();
            for (ConnectApi.ExternalManagedAccountOutput externalAccount : externalAccounts) {
                ExternalManagedAccountWrapper wrapper = new ExternalManagedAccountWrapper(externalAccount);
                wrappedAccountsList.add(wrapper);
            }
            return wrappedAccountsList;
        } catch (Exception e) {
            COMM_GEN_Utility.logError(
                e,
                'Error while getting the External Managed Accounts',
                'COMM_LCC_ExternalManagedAccount.getExternalManagedAccounts'
            );
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Update User Effective Account.
     *
     * @param accountId the account id.
     * @param userId the user id.
     */
    @AuraEnabled
    public static void switchAccount(String accountId, String userId) {
        try {
            COMM_SL_ExternalManagedAccounts.handleSwitchAccount(accountId, userId);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error updating Effective Account Id', 'COMM_LCC_ExternalManagedAccount.switchAccount');
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Get User  EffectiveAccountId .
     *
     * @param userId the user id.
     * @return User whith effective account id .
     */
    @AuraEnabled
    public static String getEffectiveAccountId(id userId) {
        try {
            return COMM_SL_User.getEffectiveAccountId(userId);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error while getting the Effective Account', 'COMM_LCC_User.getEffectiveAccountId');
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Wrapper class to manage the content
     */
    public class ExternalManagedAccountWrapper {
        /**
         * @description accountId.
         */
        @AuraEnabled
        public String accountId { get; set; }

        /**
         * @description accountName.
         */
        @AuraEnabled
        public String accountName { get; set; }

        /**
         * @description Get the managed content url by content key or id.
         *
         * @param managedAccount managed accounts.
         */
        public ExternalManagedAccountWrapper(ConnectApi.ExternalManagedAccountOutput managedAccount) {
            this.accountId = managedAccount.accountId;
            this.accountName = managedAccount.accountName;
        }
    }
}