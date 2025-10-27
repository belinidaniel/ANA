/**
 * @author           Daniel Lascas
 * @description      Case repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/03/2024       ECOMM-368: Original version
 * Daniel Lascas    18/03/2024       ECOMM-194: Added getSubscriptionCaseByIds
 **/
public inherited sharing class COMM_REP_Case extends FW_SobjectRep implements COMM_IREP_Case {
    /**
     * @description Query Cases of Record Type "Individual Staff Request" that are on "In Pending"
     * status associated with a set of Accounts
     *
     * @param accountIds Set of Account Id's to find Cases related to it
     * @param securityEnforced Uses the security enforced clause or not.
     * @return List of Queried Case Records
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Case> getIndividualStaffRequestPendingByAccountId(Set<Id> accountIds, Boolean securityEnforced) {
        if (securityEnforced) {
            return [
                SELECT Id
                FROM Case
                WHERE
                    RecordType.DeveloperName = :COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT
                    AND Status = :COMM_DO_Case.IN_APPROVAL_STATUS
                    AND AccountId IN :accountIds
                WITH USER_MODE
            ];
        } else {
            return [
                SELECT Id
                FROM Case
                WHERE
                    RecordType.DeveloperName = :COMM_DO_Case.INDIVIDUAL_STAFF_REQUEST_RT
                    AND Status IN (:COMM_DO_Case.IN_APPROVAL_STATUS, :COMM_DO_Case.WAITING_APPROVAL_STATUS)
                    AND AccountId IN :accountIds
            ];
        }
    }

    /**
     * @description Query Cases by specified identifiers
     *
     * @param caseIds Set of Case Id's
     * @return List of Queried Case Records
     */
    public List<Case> getCasesByCaseIds(Set<Id> caseIds) {
        return [
            SELECT
                Id,
                COMM_FirstName__c,
                COMM_LastName__c,
                COMM_VATNumber__c,
                COMM_Address__Street__s,
                COMM_Address__City__s,
                COMM_Address__CountryCode__s,
                COMM_Address__PostalCode__s,
                COMM_PhoneNumber__c,
                SuppliedEmail,
                COMM_JobRole__c,
                COMM_VehicleBrand__c,
                COMM_VehicleModel__c,
                COMM_LicensePlate__c,
                COMM_SecondaryVehicleBrand__c,
                COMM_SecondaryVehicleModel__c,
                COMM_SecondaryLicensePlate__c,
                RecordType.Name,
                RecordType.DeveloperName,
                COMM_Airport__c,
                Status
            FROM Case
            WHERE Id IN :caseIds
        ];
    }

    /**
     * @description Query Subscription Cases with a set of Ids
     *
     * @param caseIds Set of Case Id's to query
     * @param securityEnforced Uses the security enforced clause or not.
     * @return List of Queried Case Records
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Case> getSubscriptionCaseByIds(Set<Id> caseIds, Boolean securityEnforced) {
        if (securityEnforced) {
            return [
                SELECT
                    Id,
                    AccountId,
                    COMM_Card__c,
                    COMM_NewCardRequest__c,
                    COMM_Subscription__c,
                    ProductId,
                    COMM_SubscriptionPrice__c,
                    COMM_CardPrice__c,
                    RecordType.DeveloperName
                FROM Case
                WHERE Id IN :caseIds
                WITH USER_MODE
            ];
        } else {
            return [
                SELECT
                    Id,
                    AccountId,
                    COMM_Card__c,
                    COMM_NewCardRequest__c,
                    COMM_Subscription__c,
                    ProductId,
                    COMM_SubscriptionPrice__c,
                    COMM_CardPrice__c,
                    RecordType.DeveloperName
                FROM Case
                WHERE Id IN :caseIds
            ];
        }
    }
}