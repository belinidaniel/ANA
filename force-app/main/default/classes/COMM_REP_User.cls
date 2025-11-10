/**
 * @author Luis Oliveira
 * @description User repository class to query data.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Luis Oliveira    27/02/2024       Original version
 * Miguel Justo     28/02/2024       Added getUser
 * Daniel Lascas    28/02/2024       Added methods getUserByEmailAndLoginType and getUsersById
 * Daniel Lascas    08/03/2024       Added method getUserAccountAndContactDataById
 * Daniel Lascas    26/03/2024       Added method getAzureUserByEmail
 * Miguel Freire    23/03/2024       Added method getUsersByIdEmailValidation and getUserByEmailValidationStatusAndDate
 * Daniel Reto      29/05/2024       PDM warning messages fix
 * Miguel Freire    19/07/2024       Added method getActiveNonPartnerUserByEmail
 **/
public inherited sharing class COMM_REP_User extends FW_SobjectRep implements COMM_IREP_User {
    /**
     * @description Get active portal user given the email.
     *
     * @param Email - The user's email.
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return The active user, null otherwise.
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public User getActivePortalUserByEmail(String email, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, Name, Email, IsActive, Username
                FROM User
                WHERE Email = :email AND ContactId != NULL AND Contact.AccountId != NULL AND IsActive = TRUE
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } else {
            users = [
                SELECT Id, Name, Email, IsActive, Username
                FROM User
                WHERE Email = :email AND ContactId != NULL AND Contact.AccountId != NULL AND IsActive = TRUE
                LIMIT 1
            ];
        }

        return users.size() > 0 ? users[0] : null;
    }

    /**
     * @description Retrieve a User  by its ID from the database
     * @param userId - User identifier.
     * @return User data.
     **/
    public List<User> getUser(Set<Id> userIds) {
        List<User> users = new List<User>();
        users = [
            SELECT Id, Name, FirstName, LastName, Username, Email, COMM_EffectiveAccountId__c, ContactId
            FROM User
            WHERE Id IN :userIds AND IsActive = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return users;
    }

    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records found
     **/
    public List<User> getUsersById(Set<Id> userIds) {
        return [
            SELECT
                Id,
                ContactId,
                COMM_LoginType__c,
                COMM_EffectiveAccountId__c,
                COMM_ResetPasswordEmailExpirationDate__c,
                COMM_IsPasswordReseted__c,
                COMM_EmailValidationExpirationDate__c,
                COMM_EmailValidationChangedAddress__c,
                LanguageLocaleKey,
                Email
            FROM User
            WHERE Id IN :userIds AND IsActive = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve the list of Active User Records with their language by a set of Ids.
     *
     * @param userIds Set of User Ids to query Users.
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found.
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUserWithLaguageFieldById(Set<Id> userIds, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, LanguageLocaleKey
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
                WITH USER_MODE
            ];
        } else {
            users = [
                SELECT Id, LanguageLocaleKey
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
            ];
        }

        return users;
    }

    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     * with fields used for Email Change Validation.
     *
     * @param userIds Set of User Ids to query Users
     * @param securityEnforced - Uses the user mode security clause or not.
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUsersWithEmailChangeValidationById(Set<Id> userIds, Boolean securityEnforced) {
        if (securityEnforced) {
            return [
                SELECT Id, ContactId, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationChangedAddress__c
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
                WITH USER_MODE
            ];
        } else {
            return [
                SELECT Id, ContactId, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationChangedAddress__c
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
            ];
        }
    }

    /**
     * @description Retrieve the list of Active User Records that use a set of Emails and a set of Identifiers.
     *
     * @param emails Set of Emails to query Users
     * @param identifiers Set of Identifiers that User's use to Login
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUserByEmailAndLoginType(Set<String> emails, Set<String> identifiers, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, Email, LanguageLocaleKey, COMM_LoginType__c, Username
                FROM User
                WHERE Email IN :emails AND COMM_LoginType__c IN :identifiers AND IsActive = TRUE
                WITH USER_MODE
            ];
        } else {
            users = [
                SELECT Id, Email, LanguageLocaleKey, COMM_LoginType__c, Username
                FROM User
                WHERE Email IN :emails AND COMM_LoginType__c IN :identifiers AND IsActive = TRUE
            ];
        }

        return users;
    }

    /**
     * @description Retrieve the list of Active User Records with their
     * associated Contact and Account Record by a Set of Ids
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records with Account and Contact found
     **/
    public List<User> getUserAccountAndContactDataById(Set<Id> userIds) {
        return [
            SELECT
                Id,
                AccountId,
                ContactId,
                COMM_EffectiveAccountId__c,
                Account.Id,
                Account.Name,
                Account.FirstName,
                Account.LastName,
                Account.PersonEmail,
                Account.PersonMobilePhone,
                Account.isPersonAccount,
                Account.Phone,
                Account.RecordTypeId,
                Account.COMM_ParentAccountIsAffiliate__c,
                Account.COMM_ParentAccountData__c,
                Account.COMM_Email__c,
                Account.COMM_IsPartner__c,
                Account.COMM_IsAffiliate__c,
                Account.COMM_IndividualStaff__c,
                Account.COMM_BillingFirstName__c,
                Account.COMM_BillingLastName__c,
                Account.COMM_VATNumber__c,
                Account.COMM_PaymentMethod__c,
                Account.BillingStreet,
                Account.BillingPostalCode,
                Account.BillingCity,
                Account.BillingCountryCode,
                Account.COMM_CompanyName__c,
                Account.COMM_CompanyVATNumber__c,
                Account.COMM_CompanyBillingAddress__Street__s,
                Account.COMM_CompanyBillingAddress__PostalCode__s,
                Account.COMM_CompanyBillingAddress__City__s,
                Account.COMM_CompanyBillingAddress__CountryCode__s,
                Account.COMM_PreferredContact__c,
                Account.COMM_PreferredContact__pc,
                Account.COMM_MarketingAndCommunicationConsent__c,
                Account.COMM_MarketingAndCommunicationConsent__pc,
                Account.COMM_ParentAccount__c,
                Contact.Id,
                Contact.FirstName,
                Contact.LastName,
                Contact.Email,
                Contact.MobilePhone,
                Contact.COMM_MarketingAndCommunicationConsent__c,
                Contact.COMM_PreferredContact__c
            FROM User
            WHERE Id IN :userIds AND IsActive = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve the list of Active Azure User Records.
     * An Azure User has Login Type set as Azure and FederationId EQUALS Email
     *
     * @param emails Set of Emails to query Users
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getAzureUsersByEmail(Set<String> emails, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, Email, LanguageLocaleKey, COMM_LoginType__c
                FROM User
                WHERE
                    Email IN :emails
                    AND COMM_LoginType__c = :COMM_DO_User.AZURE_SSO_IDENTIFIER
                    AND FederationIdentifier IN :emails
                    AND IsActive = TRUE
                WITH USER_MODE
            ];
        } else {
            users = [
                SELECT Id, Email, LanguageLocaleKey, COMM_LoginType__c
                FROM User
                WHERE
                    Email IN :emails
                    AND COMM_LoginType__c = :COMM_DO_User.AZURE_SSO_IDENTIFIER
                    AND FederationIdentifier IN :emails
                    AND IsActive = TRUE
            ];
        }

        return users;
    }

    /**
     * @description Retrieve the list of User Records by a Set of Ids without user mode
     *
     * @param userIds Set of User Ids to query Users
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUsersByIdEmailValidation(Set<Id> userIds, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, isActive, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationStatus__c, LanguageLocaleKey
                FROM User
                WHERE Id IN :userIds
                WITH USER_MODE
            ];
        } else {
            users = [
                SELECT Id, isActive, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationStatus__c, LanguageLocaleKey
                FROM User
                WHERE Id IN :userIds
            ];
        }
        return users;
    }

    /**
     * @description Retrieve the list of inactive User Records that the email validation link has expired.
     *
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUserByInValidationExpiredEmail(Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationStatus__c, accountId
                FROM User
                WHERE
                    COMM_EmailValidationStatus__c = :COMM_DO_User.EMAIL_VALIDATION_PICKLIST_INVALIDATION
                    AND COMM_EmailValidationExpirationDate__c <= :Datetime.now()
                    AND accountId != NULL
                WITH USER_MODE
            ];
        } else {
            users = [
                SELECT Id, COMM_EmailValidationExpirationDate__c, COMM_EmailValidationStatus__c, accountId
                FROM User
                WHERE
                    COMM_EmailValidationStatus__c = :COMM_DO_User.EMAIL_VALIDATION_PICKLIST_INVALIDATION
                    AND COMM_EmailValidationExpirationDate__c <= :Datetime.now()
                    AND accountId != NULL
            ];
        }
        return users;
    }

    /**
     * @description Retrieve the list of Active User Records by a Set of Ids
     * with fields used for Password, Email validation
     *
     * @param userIds Set of User Ids to query Users
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return List of User Records found
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<User> getUserValidationById(Set<Id> userIds, Boolean securityEnforced) {
        if (securityEnforced) {
            return [
                SELECT
                    Id,
                    COMM_ResetPasswordEmailExpirationDate__c,
                    COMM_IsPasswordReseted__c,
                    COMM_PasswordRetrievalCount__c,
                    COMM_LastPasswordRetrievalTime__c,
                    COMM_EmailValidationExpirationDate__c,
                    COMM_EmailValidationChangedAddress__c,
                    Email,
                    FirstName,
                    LastName
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
                WITH USER_MODE
            ];
        } else {
            return [
                SELECT
                    Id,
                    COMM_ResetPasswordEmailExpirationDate__c,
                    COMM_IsPasswordReseted__c,
                    COMM_PasswordRetrievalCount__c,
                    COMM_LastPasswordRetrievalTime__c,
                    COMM_EmailValidationExpirationDate__c,
                    COMM_EmailValidationChangedAddress__c,
                    Email,
                    FirstName,
                    LastName
                FROM User
                WHERE Id IN :userIds AND IsActive = TRUE
            ];
        }
    }
    /**
     * @description Get active non partner user given the email.
     *
     * @param Email - The user's email.
     * @param securityEnforced - Uses the security enforced clause or not.
     * @return The active user, null otherwise.
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public User getActiveNonPartnerUserByEmail(String email, Boolean securityEnforced) {
        List<User> users = new List<User>();
        if (securityEnforced) {
            users = [
                SELECT Id, Name, Email, IsActive, Username
                FROM User
                WHERE
                    Email = :email
                    AND IsActive = TRUE
                    AND Profile.Name NOT IN (:COMM_DO_Profile.PROFILE_NAME_PARTNER_ADMIN, :COMM_DO_Profile.PROFILE_NAME_SUPER_PARTNER_ADMIN)
                WITH USER_MODE
                LIMIT 1
            ];
        } else {
            users = [
                SELECT Id, Name, Email, IsActive, Username
                FROM User
                WHERE
                    Email = :email
                    AND IsActive = TRUE
                    AND Profile.Name NOT IN (:COMM_DO_Profile.PROFILE_NAME_PARTNER_ADMIN, :COMM_DO_Profile.PROFILE_NAME_SUPER_PARTNER_ADMIN)
                LIMIT 1
            ];
        }

        return users.size() > 0 ? users[0] : null;
    }
}