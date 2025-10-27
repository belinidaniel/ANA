/**
 * @author Daniel Lascas
 * @description Controller for the comm_accountInformation lwc.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/03/2024       ECOMM-142 - Original version
 *
 **/
public with sharing class COMM_LCC_AccountInformation {
    //Field Names used on Front-End (LWC)
    private static final String PREFERENCIAL_CONTACT_FIELD = 'preferencialContact';
    private static final String MARKETING_CONSENT_FIELD = 'marketingConsent';
    private static final String FIRST_NAME_FIELD = 'personalFirstName';
    private static final String LAST_NAME_FIELD = 'personalLastName';
    private static final String PHONE_CODE_FIELD = 'personalPhoneCode';
    private static final String PHONE_NUMBER_FIELD = 'personalPhoneNumber';
    private static final String IS_B2C_FIELD = 'isB2C';
    private static final String IS_PARTNER_FIELD = 'isPartner';
    private static final String IS_AFFILIATE_FIELD = 'isAffiliate';

    private COMM_IREP_User userRep;
    private COMM_IREP_Case caseRep;
    private COMM_IREP_Account accountRep;
    private COMM_IREP_Contact contactRep;
    private COMM_IDO_AccountManagementMapping mappingDo;

    /**
     * @description Constructor to initialize Repository Classes
     */
    public COMM_LCC_AccountInformation() {
        this.userRep = new COMM_REP_User();
        this.caseRep = new COMM_REP_Case();
        this.accountRep = new COMM_REP_Account();
        this.contactRep = new COMM_REP_Contact();
        this.mappingDo = new COMM_DO_AccountManagementMapping();
    }

    @TestVisible
    private COMM_LCC_AccountInformation(
        COMM_IREP_User userRep,
        COMM_IREP_Case caseRep,
        COMM_IREP_Account accountRep,
        COMM_IREP_Contact contactRep,
        COMM_IDO_AccountManagementMapping mappingDo
    ) {
        this.userRep = userRep;
        this.caseRep = caseRep;
        this.accountRep = accountRep;
        this.contactRep = contactRep;
        this.mappingDo = mappingDo;
    }

    /**
     *  @description    LWC Accessible method to retrieve the picklist values for the Country Field in Addresses
     *                  Values are returned in a Map where Key = Country Code, Value = Country Name
     **/
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCountryPicklistValues() {
        //Retrieve Country Picklist Values
        Map<String, String> countryPicklistMap = new Map<String, String>();
        for (Schema.PicklistEntry picklistEntry : Account.COMM_CompanyBillingAddress__CountryCode__s.getDescribe().getPicklistValues()) {
            countryPicklistMap.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }
        return countryPicklistMap;
    }

    /**
     * @description LWC accessible method to retrieve User's Account Data Retrieval. If User uses Account Switcher,
     * the returned data will correspond to the chosen Account.
     * @return Map with the User's Account data
     */
    @AuraEnabled
    public static Map<String, Object> retrieveAccountDetails() {
        return new COMM_LCC_AccountInformation().handleRetrieveAccountDetails();
    }

    /**
     * @description LWC accessible method to validate if provided VAT Number is valid.
     *
     * @return True if VAT is Valid, false otherwise
     */
    @AuraEnabled
    public static Boolean validateVAT(String vatToValidate, String countryCode) {
        return COMM_GEN_Utility.validateVAT(vatToValidate, countryCode);
    }

    /**
     * @description Handles the User's Account Data Retrieval Logic. If User uses Account Switcher,
     * the returned data will correspond to the chosen Account.
     * @return Map with the User's Account data
     */
    @TestVisible
    private Map<String, Object> handleRetrieveAccountDetails() {
        //Retrieve User Data and check if he has an Account to return
        List<User> userList = userRep.getUserAccountAndContactDataById(new Set<Id>{ UserInfo.getUserId() });
        if (userList.isEmpty() || userList[0].AccountId == null) {
            //If no Account was found, log error then throw error to inform User that no Account was found
            AuraException error = new AuraException(System.Label.COMM_ACCOUNT_INFORMATION_NO_DATA_FOUND);
            COMM_GEN_Utility.logError(error, 'Error finding Account Data for User in Account Management', 'COMM_LCC_AccountInformation');
            throw error;
        }

        Account accountData = userList[0].Account;
        Contact contactData = userList[0].Contact;

        //If User used Account Switcher (COMM_EffectuveAccountId__c is Filled AND != User's Account)
        //Then switch returned Account Data to User's Account
        if (String.isNotBlank(userList[0].COMM_EffectiveAccountId__c) && !userList[0].AccountId.equals(userList[0].COMM_EffectiveAccountId__c)) {
            List<Account> accountList = accountRep.getAccountByIds(new Set<Id>{ userList[0].COMM_EffectiveAccountId__c });
            if (!accountList.isEmpty()) {
                accountData = accountList[0];
            }
        }

        Map<String, Object> accountDataMap = getDataMapFromRecords(accountData, contactData);

        //If Account has Parent Account and it's affiliate. Switch data.
        if (String.isNotBlank(accountData.COMM_ParentAccount__c) && accountData.COMM_ParentAccountIsAffiliate__c) {
            Map<String, Object> affiliateData = (Map<String, Object>) JSON.deserializeUntyped(accountData.COMM_ParentAccountData__c);
            accountDataMap.putAll(affiliateData);
        }

        //Verify if any Pending Cases exist (query is made without security due to Customers License not allow Case Read Permission)
        List<Case> caseList = caseRep.getIndividualStaffRequestPendingByAccountId(new Set<Id>{ userList[0].AccountId }, false);
        accountDataMap.put('requestPending', !caseList.isEmpty());
        return accountDataMap;
    }

    /**
     * @description Generate Map to send to LWC from Account and Contact Data.
     *
     * @param accountData User's Account Record to send to LWC
     * @param contactData User's Contact Record to sent to LWC
     * @return Map with the Data needed for the LWC
     */
    private Map<String, Object> getDataMapFromRecords(Account accountData, Contact contactData) {
        Map<String, Object> dataMap = new Map<String, Object>();
        Boolean isB2C = accountData.IsPersonAccount;
        Boolean isAffiliate = String.isNotBlank(accountData.COMM_ParentAccount__c) && accountData.COMM_ParentAccountIsAffiliate__c;
        dataMap.put(IS_B2C_FIELD, isB2C);
        dataMap.put(IS_PARTNER_FIELD, accountData.COMM_IsPartner__c);
        mappingDo.mapJsonFromSObject(accountData, dataMap, isB2C);
        //If B2B or Affiliate then map Contact Data into JSON
        if (!isB2C || isAffiliate) {
            mappingDo.mapJsonFromSObject(contactData, dataMap, false);
        }
        //Convert Prefencial Contact Value for Front-end (Email = FALSE, Mobile = TRUE)
        dataMap.put(
            PREFERENCIAL_CONTACT_FIELD,
            COMM_DO_Contact.PREFERRED_CONTACT_MOBILE.equals(String.valueOf(dataMap.get(PREFERENCIAL_CONTACT_FIELD)))
        );
        //Convert Marketing Consent Value for Front-end (No = FALSE, Yes = TRUE)
        dataMap.put(MARKETING_CONSENT_FIELD, COMM_DO_Contact.CONSENT_YES.equals(String.valueOf(dataMap.get(MARKETING_CONSENT_FIELD))));

        //Check phone number for phone code
        parsePhoneNumber(dataMap);
        return dataMap;
    }

    /**
     * @description Verifies if Phone Number exists on the map and if it's stored as
     * 'PHONE_CODE PHONE_NUMBER' with only one space between code and number. If it
     * is then updates data map with the numbers split.
     *
     * @param dataMap Data Map with the Phone Number Stored
     */
    private void parsePhoneNumber(Map<String, Object> dataMap) {
        if (dataMap.containsKey(PHONE_NUMBER_FIELD) && dataMap.get(PHONE_NUMBER_FIELD) != null) {
            String[] splitPhone = String.valueOf(dataMap.get(PHONE_NUMBER_FIELD)).split(' ');
            if (splitPhone.size() == 2) {
                dataMap.put(PHONE_CODE_FIELD, splitPhone[0]);
                dataMap.put(PHONE_NUMBER_FIELD, splitPhone[1]);
            }
        }
    }

    /**
     * @description LWC accessible method to update the User's Account Data with the data filled
     * on the LWC's form by the Community User.
     * @param accountDataJSON Account Data filled on the lwc's form as a JSON
     */
    @AuraEnabled
    public static void updateAccountDetails(Map<String, Object> accountDataJSON) {
        new COMM_LCC_AccountInformation().handleUpdateAccountDetails(accountDataJSON);
    }

    /**
     * @description Handles the User's Account Data Update Logic.
     * Update the User's Account Data with the data filled on the LWC's form by the Community User.
     * @param accountDataJSON Account Data filled on the lwc's form as a JSON
     */
    @TestVisible
    private void handleUpdateAccountDetails(Map<String, Object> accountDataMap) {
        try {
            Account accountData = new Account();
            Boolean isB2C = (Boolean) accountDataMap.get(IS_B2C_FIELD);
            Boolean isAffiliate = accountDataMap.containsKey(IS_AFFILIATE_FIELD) ? (Boolean) accountDataMap.get(IS_AFFILIATE_FIELD) : false;

            //Convert Consent Values to the Values stored in Salesforce
            convertConsentToSalesforce(accountDataMap);

            //Call Mapping method to convert Front-end Data for Back-end
            mappingDo.mapSObjectFromJson(accountDataMap, accountData, isB2C);

            //If B2B then update the User's Contact Record
            if (!isB2C) {
                Contact contactData = new Contact();
                mappingDo.mapSObjectFromJson(accountDataMap, contactData, isB2C);

                //Store Phone in Contact from LWC as Phone Code + Phone Number without space (ex: +351 930111222)
                if (accountDataMap.containsKey(PHONE_CODE_FIELD) && accountDataMap.containsKey(PHONE_NUMBER_FIELD)) {
                    contactData.MobilePhone = accountDataMap.get(PHONE_CODE_FIELD) + ' ' + contactData.MobilePhone;
                }
                //Call DML operation to update Contact
                contactRep.updateSObjects(new List<Contact>{ contactData });
            } else if (accountDataMap.containsKey(PHONE_CODE_FIELD) && accountDataMap.containsKey(PHONE_NUMBER_FIELD)) {
                //Store Phone in Person Account from LWC as Phone Code + Phone Number without space (ex: +351 930111222)
                accountData.PersonMobilePhone = accountDataMap.get(PHONE_CODE_FIELD) + ' ' + accountData.PersonMobilePhone.deleteWhitespace();
            }

            if (!isAffiliate) {
                //Call DML operation to update Account/Person Account if Account isn't affiliate
                accountRep.updateSObjects(new List<Account>{ accountData });
            }

            //If First or Last Name was changed then update User's Record with the new names
            if (accountDataMap.containsKey(FIRST_NAME_FIELD) || accountDataMap.containsKey(LAST_NAME_FIELD)) {
                User userData = new User(
                    Id = UserInfo.getUserId(),
                    FirstName = (String) accountDataMap.get(FIRST_NAME_FIELD),
                    LastName = (String) accountDataMap.get(LAST_NAME_FIELD)
                );
                userRep.updateSObjects(new List<User>{ userData });
            }
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error updating Account Data', 'COMM_LCC_AccountInformation');
            throw e;
        }
    }

    /**
     * @description Converts the Consent From Front-end (LWC) to the values stored on the back-end.
     *
     * @param accountDataMap Data Map obtained from Front-end
     */
    private void convertConsentToSalesforce(Map<String, Object> accountDataMap) {
        //Convert Marketing Consent Value to Back-end (TRUE = Yes, FALSE = No)
        if (accountDataMap.containsKey(MARKETING_CONSENT_FIELD)) {
            accountDataMap.put(
                MARKETING_CONSENT_FIELD,
                Boolean.valueOf(accountDataMap.get(MARKETING_CONSENT_FIELD)) ? COMM_DO_Contact.CONSENT_YES : COMM_DO_Contact.CONSENT_NO
            );
        }

        //Convert Prefencial Contact Value to Back-end (TRUE = Mobile, FALSE = Email)
        if (accountDataMap.containsKey(PREFERENCIAL_CONTACT_FIELD)) {
            accountDataMap.put(
                PREFERENCIAL_CONTACT_FIELD,
                Boolean.valueOf(accountDataMap.get(PREFERENCIAL_CONTACT_FIELD))
                    ? COMM_DO_Contact.PREFERRED_CONTACT_MOBILE
                    : COMM_DO_Contact.PREFERRED_CONTACT_EMAIL
            );
        }
    }

    /**
     * @description LWC accessible method to initiate the change password logic.
     */
    @AuraEnabled
    public static void changePassword() {
        try {
            String communityURL = Site.getBaseSecureUrl();
            String communityName = Site.getName();
            new COMM_SL_ResetPassword().resetUserPassword(UserInfo.getUserId(), UserInfo.getLanguage(), communityURL, communityName, null, false);
        } catch (Exception e) {
            //Log Error
            COMM_GEN_Utility.logError(e, 'Changing Password', 'COMM_LCC_AccountInformation');
            throw e;
        }
    }

    /**
     * @description LWC accessible method to initiate the change password logic.
     */
    @AuraEnabled
    public static void changeEmail(String newEmail) {
        try {
            String communityURL = Site.getBaseSecureUrl();
            String communityName = Site.getName();
            new COMM_SL_ChangeEmail().changeEmail(UserInfo.getUserId(), UserInfo.getLanguage(), newEmail, communityURL, communityName);
        } catch (Exception e) {
            //Log Error
            COMM_GEN_Utility.logError(e, 'Changing Email', 'COMM_LCC_AccountInformation');
            throw e;
        }
    }

    /**
     * @description LWC accessible method to initiate the user's account deactivation process.
     */
    @AuraEnabled
    public static void deactivateAccount() {
        try {
            //Call flow to deactivate and send email informing of Account deactivation
            Flow.Interview.COMM_User_FLW_DeactivateCommunityUser userDeactivationFlow = new Flow.Interview.COMM_User_FLW_DeactivateCommunityUser(
                new Map<String, Object>()
            );
            userDeactivationFlow.start();
        } catch (Exception e) {
            //Log Error
            COMM_GEN_Utility.logError(e, 'Error deactivating user account', 'COMM_LCC_AccountInformation');
            throw e;
        }
    }
}