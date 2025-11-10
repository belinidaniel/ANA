/**
 * @author Daniel Lascas
 * @description User SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/02/2024       Original version
 **/
public inherited sharing class COMM_DO_User implements COMM_IDO_User {
    //Picklist values used to identify user's Login Method
    public final static string NORMAL_LOGIN_IDENTIFIER = 'Normal';
    public final static string GOOGLE_SSO_IDENTIFIER = 'Google';
    public final static string FACEBOOK_SSO_IDENTIFIER = 'Facebook';
    public final static string AZURE_SSO_IDENTIFIER = 'Azure';
    public final static string AZURE_AUTHPROVIDER_LABEL = 'Open ID Connect';

    //Default User Values
    public final static string TIME_ZONE_PICKLIST_PTLS = 'Europe/Lisbon';
    public final static string EMAIL_ENCODINGKEY_PICKLIST_UTF8 = 'UTF-8';

    //Picklist values used to identify the email validation status
    public final static string EMAIL_VALIDATION_PICKLIST_INVALIDATION = 'In Validation';
    public final static string EMAIL_VALIDATION_PICKLIST_VALIDATED = 'Validated';

    private COMM_IREP_Profile profileRep;

    /**
     * @description Class Constructor to initialize REP classes
     */
    public COMM_DO_User() {
        this.profileRep = new COMM_REP_PROFILE();
    }

    @TestVisible
    private COMM_DO_User(COMM_IREP_PROFILE profileRep) {
        this.profileRep = profileRep;
    }

    /**
     * @description Method to generate an instance of a User Record from the provided parameters
     *
     * @param firstName First Name to be associated with the generated User
     * @param lastName Last Name to be associated with the generated User
     * @param email Email to be associated with the generated User
     * @param identifier Identifier of the Login Method to be used by the User (Google, Facebook or Normal)
     * @return User Record generated
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public User instantiateUser(String firstName, String lastName, String email, String identifier) {
        User user = new User();
        user.username = email + '.' + identifier;
        user.email = email;
        user.lastName = lastName;
        user.firstName = firstName;
        user.COMM_LoginType__c = identifier;
        String prefix = email.replace('@', '.');
        if (prefix.length() > 40 - 7) {
            prefix = prefix.substring(0, 40 - 7);
        }
        user.CommunityNickname = prefix + String.valueOf(Crypto.getRandomInteger()).substring(1, 7);

        String alias = firstName + lastName;
        //Alias must be 8 characters or less
        if (alias.length() > 8) {
            alias = alias.substring(0, 8);
        }

        user.alias = alias;
        user.languagelocalekey = UserInfo.getLanguage();
        user.localesidkey = UserInfo.getLocale();
        user.EmailEncodingKey = EMAIL_ENCODINGKEY_PICKLIST_UTF8;
        user.TimeZoneSidKey = TIME_ZONE_PICKLIST_PTLS;
        user.profileId = (profileRep.getProfilesByName(new Set<String>{ COMM_DO_Profile.PROFILE_NAME_IDENTITY_USER }, false)[0]).Id;

        return user;
    }
}