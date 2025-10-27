/**
 * @author Luis Oliveira
 * @description User repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Luis Oliveira    27/02/2024       Original version
 * Daniel Lascas    28/02/2024       Added methods getUserByEmailAndLoginType and getUsersById
 * Daniel Lascas    08/03/2024       Added method getUserAccountAndContactDataById
 * Miguel Freire    23/03/2024       Added method getUsersByIdEmailValidation and getUserByEmailValidationStatusAndDate
 * Daniel Lascas    26/03/2024       Added method getAzureUserByEmail
 * Miguel Freire    19/07/2024       Added method getActiveNonPartnerUserByEmail
 **/
public interface COMM_IREP_User extends FW_ISObjectRep {
    User getActivePortalUserByEmail(String email, Boolean securityEnforced);

    /**
     * @description Retrieve the list of Active User Records that use a set of Emails and a set of Identifiers
     *
     * @param emails Set of Emails to query Users
     * @param identifiers Set of Identifiers that User's use to Login
     * @return List of User Records found
     **/
    List<User> getUserByEmailAndLoginType(Set<String> emails, Set<String> identifiers, Boolean securityEnforced);
    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records found
     **/
    List<User> getUsersById(Set<Id> userIds);
    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     * with fields used for Email Change Validation.
     *
     * @param userIds Set of User Ids to query Users
     * @param securityEnforced - Uses the user mode security clause or not.
     * @return List of User Records found
     **/
    List<User> getUsersWithEmailChangeValidationById(Set<Id> userIds, Boolean securityEnforced);
    /**
     * @description Retrieve the list of Active User Records with their
     * associated Contact and Account Record by a Set of Ids
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records with Account and Contact found
     **/
    List<User> getUserAccountAndContactDataById(Set<Id> userIds);
    /**
     * @description Retrieve the list of Active Azure User Records.
     * An Azure User has Login Type set as Azure and FederationId EQUALS Email
     *
     * @param emails Set of Emails to query Users
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    List<User> getAzureUsersByEmail(Set<String> emails, Boolean securityEnforced);
    /**
     * @description Retrieve the list of User Records by a Set of Ids without user mode
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records found
     **/
    List<User> getUsersByIdEmailValidation(Set<Id> userIds, Boolean securityEnforced);

    /**
     * @description Retrieve the list of inactive User Records that the email validation link has expired.
     *
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    List<User> getUserByInValidationExpiredEmail(Boolean securityEnforced);
    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     * with fields used for Password, Email validation
     *
     * @param userIds Set of User Ids to query Users
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    List<User> getUserValidationById(Set<Id> userIds, Boolean securityEnforced);
    /**
     * @description Get active non partner user given the email.
     *
     * @param Email - The user's email.
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return The active user, null otherwise.
     */
    User getActiveNonPartnerUserByEmail(String email, Boolean securityEnforced);
    /**
     * @description Retrieve the list of Active User Records with their language by a set of Ids.
     *
     * @param userIds Set of User Ids to query Users.
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found.
     **/
    List<User> getUserWithLaguageFieldById(Set<Id> userIds, Boolean securityEnforced);
}