/**
 * @author Daniel Lascas
 * @description Controller for the comm_languageSelector lwc.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/06/2024       ECOMM-1256: Original version
 *
 **/
public with sharing class COMM_LCC_LanguageSelector {
    private COMM_IREP_User userRep;

    /**
     * @description Class constructor to initialize REP
     */
    public COMM_LCC_LanguageSelector() {
        this.userRep = new COMM_REP_User();
    }

    /**
     * @description LWC Accessible method to verify if User's Language is diferente from site's
     *
     * @param siteLanguage Language Code of the Community Site's Currently Selected Language.
     * @return True if user language was updated, false otherwise.
     **/
    @AuraEnabled
    public static Boolean verifyUserLanguage(String siteLanguage) {
        return new COMM_LCC_LanguageSelector().handleVerifyUserLanguage(siteLanguage);
    }

    /**
     * @description LWC Accessible method to verify if User's Language is diferente from site's
     *
     * @param siteLanguage Language Code of the Community Site's Currently Selected Language.
     **/
    @AuraEnabled
    public static void updateUserLanguage(String siteLanguage) {
        new COMM_LCC_LanguageSelector().handleUpdateUserLanguage(siteLanguage);
    }

    /**
     * @description Handler for Verifying User Language. Checks if current User is authenticated (not guest)
     * and language is diferente from Community Site's. If true then update user's language to site's.
     *
     * @param siteLanguage Language Code of the Community Site's Currently Selected Language.
     * @return True if user language was updated, false otherwise.
     */
    private Boolean handleVerifyUserLanguage(String siteLanguage) {
        //Verify if User is Guest and Site Language is equal to User's Current Language
        if (Auth.CommunitiesUtil.isGuestUser() || String.isBlank(siteLanguage) || siteLanguage.equals(UserInfo.getLanguage())) {
            return false;
        }
        handleUpdateUserLanguage(siteLanguage);
        return true;
    }

    /**
     * @description Handler to update current user's language.
     *
     * @param siteLanguage Language Code for user's new language.
     */
    private void handleUpdateUserLanguage(String siteLanguage) {
        try {
            User userUpdate = new User(Id = UserInfo.getUserId(), LanguageLocaleKey = siteLanguage);
            userRep.updateSObjects(new List<User>{ userUpdate });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'failed to update user language', 'COMM_LCC_LanguageSelector');
            throw e;
        }
    }
}