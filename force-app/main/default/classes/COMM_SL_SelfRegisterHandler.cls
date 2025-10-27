/**
 * @author           Miguel Freire
 * @description      Normal Registration Handler
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    18/03/2024       Original version
 **/
public without sharing class COMM_SL_SelfRegisterHandler {
    private COMM_DO_User commDoUser;
    private COMM_REP_User commRepUser;
    private COMM_REP_Contact commRepContact;
    private COMM_DO_Email commDoEmail;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_SL_SelfRegisterHandler() {
        this.commDoUser = new COMM_DO_User();
        this.commRepUser = new COMM_REP_User();
        this.commRepContact = new COMM_REP_Contact();
        this.commDoEmail = new COMM_DO_Email();
    }

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_SL_SelfRegisterHandler(
        COMM_REP_User commRepUser,
        COMM_DO_User commDoUser,
        COMM_REP_Contact commRepContact,
        COMM_DO_Email commDoEmail
    ) {
        this.commRepUser = commRepUser;
        this.commDoUser = commDoUser;
        this.commRepContact = commRepContact;
        this.commDoEmail = commDoEmail;
    }

    /**
     * @description Method to get the user inputs from self register.
     *
     * @param firstName User input from self register page
     * @param lastName User input from self register page
     * @param email User input from self register page
     * @param password User input from self register page
     * @param siteLanguage User input from self register page
     * @param redirectUrl Start URL parameter from self register page
     * @param goToCheckout Boolean from self register page indicating that user is to be redirected to checkout page after validation
     */
    @AuraEnabled
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void registerUser(
        String firstName,
        String lastName,
        String email,
        String password,
        String siteLanguage,
        String redirectUrl,
        Boolean goToCheckout
    ) {
        new COMM_SL_SelfRegisterHandler().handleRegisterUser(firstName, lastName, email, password, siteLanguage, redirectUrl, goToCheckout);
    }

    /**
     * @description Method to handle the user inputs from self register.
     *
     * @param firstName User input from self register page
     * @param lastName User input from self register page
     * @param email User input from self register page
     * @param password User input from self register page
     * @param siteLanguage User input from self register page
     * @param redirectUrl URL that user is redirected after logging in when confirming account
     * @param goToCheckout Boolean indicating that user is to be redirected to checkout page instead of url
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void handleRegisterUser(
        String firstName,
        String lastName,
        String email,
        String password,
        String siteLanguage,
        String redirectUrl,
        Boolean goToCheckout
    ) {
        // Check if a non Partner User alredy exists
        User identityUserRecord = commRepUser.getActiveNonPartnerUserByEmail(email, false);
        if (identityUserRecord != null) {
            // If an identity user exists with this email already exists trow error
            AuraException newException = new AuraException(System.label.COMM_REGISTER_REGISTRATION_FAILED);
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_SelfRegisterHandler');
            throw newException;
        }
        // Create User
        User userRecord = commDoUser.instantiateUser(firstName, lastName, email, COMM_DO_User.NORMAL_LOGIN_IDENTIFIER);
        // Get the siteLanguage code
        String languageCode = siteLanguage.replace('-', '_');
        // Set the user language to the same he as in the site registration page
        userRecord.languagelocalekey = languageCode;
        // Insert PersonAccount and User
        try {
            Site.createPersonAccountPortalUser(userRecord, UserInfo.getUserId(), password);
        } catch (exception newException) {
            // If creation of user or person account fails trow erros
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_SelfRegisterHandler');
            throw newException;
        }
        // Query the User Information
        List<User> userRecords = commRepUser.getUserByEmailAndLoginType(
            new Set<String>{ email },
            new Set<String>{ COMM_DO_User.NORMAL_LOGIN_IDENTIFIER },
            false
        );
        // Encode Id and send Email
        if (!userRecords.isEmpty()) {
            COMM_DO_Email.encodeIdAndSetEmail(userRecords[0], redirectUrl, COMM_DO_Email.EMAIL_TEMPLATE_EMAIL_VALIDATION, goToCheckout);
        }
    }
}