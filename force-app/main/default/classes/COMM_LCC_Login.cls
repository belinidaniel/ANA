/**
 * @author Luis Oliveira
 * @description Controller of login Lightning Web Component.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Luis Oliveira    27/02/2024       Original version
 * Daniel Lascas    22/10/2024       Added Key Encryption Logic
 **/
public with sharing class COMM_LCC_Login {
    private static final String LOGIN_KEY_NAME = 'Login';
    private static final String RESET_KEY_NAME = 'Reset';

    /**
     * @description Obtain Key used to encrypt and decrypt data shared
     * between Login component and server.
     *
     * @return Encryption Key.
     */
    @AuraEnabled
    public static String getLoginKey() {
        return COMM_EncryptionSetting__mdt.getInstance(LOGIN_KEY_NAME)?.COMM_Value__c;
    }

    /**
     * @description Obtain Key used to encrypt and decrypt data shared
     * between set password component and server.
     *
     * @return Encryption Key.
     */
    @AuraEnabled
    public static String getResetKey() {
        return COMM_EncryptionSetting__mdt.getInstance(RESET_KEY_NAME)?.COMM_Value__c;
    }

    /**
     * @description Logins the user into the site.
     *
     * @param startUrl - The url to be redirected after authentication.
     * @param payload - Encrypted data with the user's credentials info.
     * @return The reference page in case successful authentication.
     */
    @AuraEnabled
    public static String siteLogin(String startUrl, String payload) {
        try {
            COMM_EncryptionSetting__mdt loginSetting = Test.isRunningTest()
                ? COMM_TestDataFactory.getTestEncryptionSetting()
                : COMM_EncryptionSetting__mdt.getInstance(LOGIN_KEY_NAME);
            RequestWrapper decryptedData = (RequestWrapper) JSON.deserializeStrict(
                COMM_GEN_Utility.decryptStringWithAES(payload, loginSetting?.COMM_Value__c),
                RequestWrapper.class
            );
            //Verify if request timestamp is still inside buffer time.
            if (
                decryptedData?.timestamp != null &&
                decryptedData.timestamp.addSeconds(Integer.valueOf(loginSetting?.COMM_Buffer__c)) > Datetime.now()
            ) {
                String email = decryptedData.email;
                String password = decryptedData.password;
                return COMM_SL_SiteLogin.handleSiteLogin(startUrl, email, password);
            }
            //Throw Invalid Session Error if validation failed.
            throw new AuraException('Invalid Session');
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Login: Authentication Error', 'COMM_LCC_Login');
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Resets user password.
     *
     * @param email - The user's email.
     * @param startUrl Start URL parameter from self register page.
     */
    @AuraEnabled
    public static void resetPassword(String email, String startUrl) {
        try {
            String communityURL = Site.getBaseSecureUrl();
            String communityName = Site.getName();
            new COMM_SL_ResetPassword().resetPassword(email, communityURL, communityName, startUrl);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Forgot Password: Reset Passsword Error ' + email, 'COMM_LCC_Login');
            throw new AuraHandledException(System.Label.COMM_FORGOT_PASSWORD_INVALID_TOKEN);
        }
    }

    /**
     * @description Changes User's password.
     *
     * @param payload - The encrypted user data received from front-end.
     */
    @AuraEnabled
    public static void changePassword(String payload) {
        Id userId = null;
        try {
            COMM_EncryptionSetting__mdt resetSetting = Test.isRunningTest()
                ? COMM_TestDataFactory.getTestEncryptionSetting()
                : COMM_EncryptionSetting__mdt.getInstance(RESET_KEY_NAME);
            RequestWrapper decryptedData = (RequestWrapper) JSON.deserializeStrict(
                COMM_GEN_Utility.decryptStringWithAES(payload, resetSetting?.COMM_Value__c),
                RequestWrapper.class
            );
            userId = decryptedData?.userId;
            //Verify if request timestamp is still inside buffer time.
            if (
                decryptedData?.timestamp != null &&
                decryptedData.timestamp.addSeconds(Integer.valueOf(resetSetting?.COMM_Buffer__c)) > Datetime.now()
            ) {
                new COMM_SL_ResetPassword().handleChangePassword(userId, decryptedData.password);
                return;
            }
            //Throw Invalid Request Error if validation failed.
            throw new AuraException('Invalid Request');
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Forgot Password: Change Passsword Error ' + userId, 'COMM_LCC_Login');
            throw new AuraHandledException(System.Label.COMM_FORGOT_PASSWORD_INVALID_TOKEN);
        }
    }

    /**
     * @description Validates Token in URL belongs to a User that resetted his password,
     * if not throw error.
     *
     * @param token - The token from page url parameter.
     * @return userInformationList containing the User Id from token and the User Email.
     */
    @AuraEnabled
    public static List<String> validateResetToken(String token) {
        COMM_REP_User commRepUser = new COMM_REP_User();
        List<String> userInformationList = new List<String>();
        User userRecord;
        try {
            userRecord = new COMM_SL_ResetPassword().handleValidateResetToken(token);
        } catch (Exception e) {
            //Log Error if one occured during validation then throw generic error message to front-end
            COMM_GEN_Utility.logError(e, 'Forgot Password: Validate Reset Token Error ' + token, 'COMM_LCC_Login');
            throw new AuraHandledException(System.Label.COMM_FORGOT_PASSWORD_INVALID_TOKEN);
        }
        //If Token validation returned null value (ex: user not found), throw invalid token error message to front-end
        if (userRecord == null) {
            //Log Error if value was returned as null then throw generic error message to front-end
            Exception e = new AuraHandledException(System.Label.COMM_FORGOT_PASSWORD_INVALID_TOKEN);
            COMM_GEN_Utility.logError(e, 'Forgot Password: Validate Reset Token Error ' + token, 'COMM_LCC_Login');
            throw e;
        }
        userInformationList.Add(userRecord.Id);
        userInformationList.Add(userRecord.Email);
        userInformationList.Add(userRecord.FirstName);
        userInformationList.Add(userRecord.LastName);
        return userInformationList;
    }

    /**
     * @description Wrapper to represent data structure expected from front-end.
     */
    public class RequestWrapper {
        private Id userId;
        private String email;
        private String password;
        private Datetime timestamp;
    }
}