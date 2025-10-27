/**
 * @author Daniel Lascas
 * @description Service Layer class that handles the Auth.Provider methods
 * for Google and Facebook Logins
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/02/2024       Original version
 **/
public without sharing class COMM_SL_AuthProviderHandler implements Auth.RegistrationHandler {
    private COMM_REP_Account accountRep;
    private COMM_REP_Contact contactRep;
    private COMM_REP_User userRep;
    private COMM_DO_User userDo;

    /**
     * @description Class Constructor to initialize REP classes
     */
    public COMM_SL_AuthProviderHandler() {
        this.accountRep = new COMM_REP_Account();
        this.contactRep = new COMM_REP_Contact();
        this.userRep = new COMM_REP_User();
        this.userDo = new COMM_DO_User();
    }
    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_SL_AuthProviderHandler(COMM_REP_Account accountRep, COMM_REP_Contact contactRep, COMM_REP_User userRep, COMM_DO_User userDo) {
        this.accountRep = accountRep;
        this.contactRep = contactRep;
        this.userRep = userRep;
        this.userDo = userDo;
    }

    /**
     * @description Authentication Method to create a User record when there isn't a User associated with the Authentication Method used
     *
     * @param portalId - Id of the Community from where the User initiated the Social Login
     * @param data - User's information provided by the Auth Provider of the Social Login
     * @return User Record created
     **/
    public User createUser(Id portalId, Auth.UserData data) {
        //For Azure.
        // Check if Auth.Provider is from Azure and get the user
        if (data != null && data.email != null && data.provider == COMM_DO_User.AZURE_AUTHPROVIDER_LABEL) {
            // Get useres by email and login type = 'Azure'
            List<User> azureUsers = userRep.getAzureUsersByEmail(new Set<String>{ data.email }, false);
            // If User exists Login
            if (!azureUsers.isEmpty()) {
                return azureUsers[0];
            }
            // If User doesnt exist log error and return null so user goes to error page
            else {
                COMM_GEN_Utility.logError(
                    new AuraException('No User with email ' + data.email),
                    'Azure Login, failed to find existing User. Data Provided: ' + JSON.serialize(data),
                    'COMM_SL_AuthProviderHandler'
                );
                return null;
            }
        }

        //Check if a non Partner User alredy exists
        User identityUserRecord = userRep.getActiveNonPartnerUserByEmail(data.email, false);
        if (identityUserRecord != null) {
            // If an identity user exists with this email already exists trow error
            AuraException newException = new AuraException(System.label.COMM_REGISTER_REGISTRATION_FAILED);
            COMM_GEN_Utility.logError(newException, newException.getMessage(), 'COMM_SL_AuthProviderHandler');
            throw newException;
        }

        //Let anyone register as long as the required fields are supplied
        if (data == null || data.email == null || (data.lastName == null && data.firstName == null)) {
            COMM_GEN_Utility.logError(
                new AuraException('Required Fields Missing'),
                'Google/Facebook Login. Data Provided: ' + JSON.serialize(data),
                'COMM_SL_AuthProviderHandler'
            );
            return null;
        } else if (data.lastName == null && data.firstName != null) {
            //If last name wasn't provided but first name was then copy first name to last
            data.lastName = data.firstName;
        }
        // For Facebook and Google
        // Create Person Account to associate with User
        Id accountCreatedId = createPersonAccount(data);
        // Query created Account (to obtain the Person Account's Contact Id)
        List<Account> accountList = accountRep.getPersonAccountsByIds(new Set<Id>{ accountCreatedId });
        // Instatiate a User Record, associate it with the created Account and return it
        User user = userDo.instantiateUser(data.firstName, data.lastName, data.email, data.provider);
        user.ContactId = accountList[0].PersonContactId;
        return user;
    }

    /**
     * @description Authentication Method to update the User record after logging in the future
     *
     * @param userId - Id of the User that is logging in using Social Login
     * @param portalId - Id of the Community from where the User initiated the Social Login
     * @param data - User's information provided by the Auth Provider
     **/
    public void updateUser(Id userId, Id portalId, Auth.UserData data) {
        //Skip Update if Authentication doesn't provide data or required Name
        if (data == null || (data.firstName == null && data.lastName == null)) {
            return;
        } else if (data.firstName != null && data.lastName == null) {
            //If First Name provided but Last Name missing (required in Salesforce) then copy
            data.lastName = data.firstName;
        }
        //Get User with id from Auth.Provider to obtain it's Contact Id
        List<User> userRecords = userRep.getUsersById(new Set<Id>{ userId });
        //Check if User has a related Contact. Skip Contact update if he doesn't (ex: Backoffice Users).
        if (userRecords[0].ContactId != null) {
            // Update Contact associated with User
            updateContact(data, userRecords[0].ContactId);
        }
        // Update User
        try {
            User userUpdate = new User(Id = userId, FirstName = data.firstName, LastName = data.lastName);
            userRep.updateSObjects(new List<User>{ userUpdate });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error updating User during Social Login', 'COMM_SL_AuthProviderHandler');
            throw e;
        }
    }

    /**
     * @description Create the Person Account Record that will be associated with the created User Record
     *
     * @param data - User's info from the Auth Provider
     * @return Id of the createed Account
     **/
    private Id createPersonAccount(Auth.UserData data) {
        // Create Account
        Account userAccount = COMM_DO_Account.instantiatePersonAccount(data.firstName, data.lastName, data.email);
        try {
            accountRep.insertSObjects(new List<Account>{ userAccount });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error creating Person Account during Social Login', 'COMM_SL_AuthProviderHandler');
            throw e;
        }
        return userAccount.Id;
    }

    /**
     * @description Update the Contact associated with the User Record with the data from the Authentication Provider
     * @param data - User's information provided by the Auth Provider
     * @param contactId - Id of the Contact Record to update
     **/
    private void updateContact(Auth.UserData data, Id contactId) {
        try {
            Contact contactUpdate = new Contact(Id = contactId, FirstName = data.firstName, LastName = data.lastName);
            contactRep.updateSObjects(new List<Contact>{ contactUpdate });
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error updating Contact during Social Login', 'COMM_SL_AuthProviderHandler');
            throw e;
        }
    }
}