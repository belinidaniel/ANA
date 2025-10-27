/**
 * @author Miguel Justo
 * @description Service Layer class that handles the External Managed Accounts methods
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Justo   06/03/2024       Original version
 **/
public with sharing class COMM_SL_ExternalManagedAccounts {
    /**
     * @description Get External Managed Accounts.
     *
     * @param communityId the community id.
     * @return Account List.
     */
    public static List<ConnectApi.ExternalManagedAccountOutput> handleExternalManagedAccounts(String communityId) {
        ConnectApi.ExternalManagedAccountCollectionOutput managedAccounts = ConnectApi.ExternalManagedAccount.getCommunitiesExternalManagedAccounts(
            communityId,
            true
        );
        return managedAccounts.externalManagedAccounts;
    }

    /**
     * @description Update User Effective Account.
     *
     * @param accountId the account id.
     * @param userId the user id.
     */
    public static void handleSwitchAccount(String accountId, String userId) {
        // Repositories classes
        COMM_REP_User userRep = new COMM_REP_User();
        COMM_IREP_Contact contactRep = new COMM_REP_Contact();
        List<User> userList = userRep.getUser(new Set<Id>{ userId });

        if (!userList.isEmpty()) {
            // Update the user with the new effective account.
            User userRecord = new User(Id = userList[0].Id, COMM_EffectiveAccountId__c = accountId);
            userRep.updateSObjects(new List<User>{ userRecord });

            // Update the user's contact with the new effective account if he has one.
            if (userList[0].ContactId != null) {
                Contact contactRecord = new Contact(Id = userList[0].ContactId, COMM_EffectiveAccountId__c = accountId);
                contactRep.updateSObjects(new List<Contact>{ contactRecord });
            }
        }
    }
}