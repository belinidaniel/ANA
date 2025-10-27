/**
 * @author Luis Oliveira
 * @description Service Layer class for Site Login logic used on Community
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Luis Oliveira    14/03/2024       Original version
 **/
public with sharing class COMM_SL_SiteLogin {
    /**
     * @description Manages the site login for the current user.
     *
     * @param startUrl - The url to be redirected after authentication.
     * @param email - The user's email.
     * @param password - The user's password.
     * @return The reference page in case successful authentication, null otherwise.
     */
    public static String handleSiteLogin(String startUrl, String email, String password) {
        return new COMM_SL_User_WithoutSharing().handleSiteLogin(startUrl, email, password);
    }

    private without sharing class COMM_SL_User_WithoutSharing {
        /**
         * @description Manages the site login for the current user.
         *
         * @param startUrl - The url to be redirected after authentication.
         * @param email - The user's email.
         * @param password - The user's password.
         * @return The reference page in case successful authentication, null otherwise.
         */
        public String handleSiteLogin(String startUrl, String email, String password) {
            // 1. Initializes the repositories.
            COMM_REP_User userRep = new COMM_REP_User();

            // 2. Get the active portal user.
            // Check if a External Identity User alredy exists with the provider email and login type 'Normal'
            List<User> userRecordsList = userRep.getUserByEmailAndLoginType(
                new Set<String>{ email },
                new Set<String>{ COMM_DO_User.NORMAL_LOGIN_IDENTIFIER },
                false
            );

            if (
                userRecordsList.isEmpty() ||
                userRecordsList[0].COMM_LoginType__c == COMM_DO_User.GOOGLE_SSO_IDENTIFIER ||
                userRecordsList[0].COMM_LoginType__c == COMM_DO_User.FACEBOOK_SSO_IDENTIFIER
            ) {
                return null;
            }

            // 3. Authenticates the user.
            String userName = userRecordsList[0].Username;
            ApexPages.PageReference pageRef = Site.login(userName, password, startUrl);

            return pageRef.getUrl();
        }
    }
}