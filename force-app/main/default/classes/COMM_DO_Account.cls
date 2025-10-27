/**
 * @author Daniel Lascas
 * @description Account object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/12/2023       Original version
 * Daniel Lascas    12/03/2023       ECOMM-142 - Added Picklist Values
 **/
public inherited sharing class COMM_DO_Account implements COMM_IDO_Account {
    //Developer Name of the Person Account Record Type
    public final static string PERSON_ACCOUNT_RECORD_TYPE = 'COMM_Individual';
    public final static string COLLECTIVEPARTNER_ACCOUNT_RECORD_TYPE = 'COMM_CollectivePartner';
    //Picklist Values for Preferred Contact Field
    public final static String PREFERRED_CONTACT_PHONE = 'Phone';
    public final static String PREFERRED_CONTACT_EMAIL = 'E-Mail';
    //Picklist Values for Consent Fields
    public final static String CONSENT_YES = 'Yes';
    public final static String CONSENT_NO = 'No';
    //Account Type (for Commerce Connected App)
    public static final String ACCOUNT_TYPE_B2C = 'B2C';
    public static final String ACCOUNT_TYPE_B2B = 'B2B';
    //Account Type Picklist Values
    public static final String TYPE_PARTNER = 'Partner';
    //Account Payment Method Picklist Values
    public static final String PAYMENT_METHOD_CREDIT = 'Credit';
    //Address Country Code Picklist Values
    private static final String PT_COUNTRY_CODE = 'PT';

    /**
     * @description Method to generate a Person Account Record with the required fields
     * @param firstName First Name to be associated with the generated Person Account
     * @param lastName Last Name to be associated with the generated Person Account
     * @param email Email to be associated with the generated Person Account
     * @return Person Account Record generated
     */
    public static Account instantiatePersonAccount(String firstName, String lastName, String email) {
        Account account = new Account();
        account.FirstName = firstName;
        account.LastName = lastName;
        account.PersonEmail = email;
        account.RecordTypeId = COMM_GEN_Utility.getRecordTypeIdByDevName(Schema.Account.SObjectType, PERSON_ACCOUNT_RECORD_TYPE);
        return account;
    }

    /**
     * @description Verify if VAT Number is invalid. Validation is only performed for Portuguese NIF.
     * For non-Portugese VAT, validation is skipped.
     *
     * @param accountRecord Account to be Validated
     * @param previousAccountRecord Account to be Validated before VAT Update (to skip validation if not changed)
     * @param verifyVatNumberField Boolean indicating if validation is for COMM_VATNumber__c or COMM_CompanyVATNumber__c
     * @return True if validation returned invalid, False otherwise
     */
    public static Boolean verifyInvalidVAT(Account accountRecord, Account previousAccountRecord, Boolean verifyVatNumberField) {
        //Verify if Country Code or VAT Number Changed
        Boolean fieldChanged = verifyVatNumberField
            ? COMM_GEN_Utility.isChangedField(accountRecord, previousAccountRecord, String.valueOf(Account.COMM_VATNumber__c)) ||
              COMM_GEN_Utility.isChangedField(accountRecord, previousAccountRecord, String.valueOf(Account.BillingCountryCode))
            : COMM_GEN_Utility.isChangedField(accountRecord, previousAccountRecord, String.valueOf(Account.COMM_CompanyVATNumber__c)) ||
              COMM_GEN_Utility.isChangedField(
                  accountRecord,
                  previousAccountRecord,
                  String.valueOf(Account.COMM_CompanyBillingAddress__CountryCode__s)
              );
        //Country Code for Validation
        String countryCode = verifyVatNumberField ? accountRecord.BillingCountryCode : accountRecord.COMM_CompanyBillingAddress__CountryCode__s;
        //Ignore if Country Code is empty
        if (String.isBlank(countryCode)) {
            return false;
        }
        //VAT Number to validate
        String vatNumberToValidate = verifyVatNumberField ? accountRecord.COMM_VATNumber__c : accountRecord.COMM_CompanyVATNumber__c;
        //VAT Number is Invalid if the following is true:
        //- Country Code is empty or Portuguese
        //- VAT Number or Country Code field changed
        //- Validation Service returns false
        return (String.isBlank(countryCode) || PT_COUNTRY_CODE.equals(countryCode)) &&
            (fieldChanged && !COMM_DO_VATNumberValidation.getInstance().isValid(countryCode, vatNumberToValidate, true));
    }
}