/**
 * @author Daniel Lascas
 * @description Class used to validate Taxpayer Identification Numbers (VAT, TIN or NIF).
 * The rules used by this class are defined in the custom metadata COMM_VATNumberRule__mdt
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024       Original Version
 **/
public inherited sharing class COMM_DO_VATNumberValidation {
    private static COMM_DO_VATNumberValidation instance = null;
    //A map containing the VAT number metadata rules sorted by Country Code
    private final Map<String, COMM_VATNumberRule__mdt> mdtMapByCountryCode = new Map<String, COMM_VATNumberRule__mdt>();
    //Metadata checked as the default rule to be used
    private static COMM_VATNumberRule__mdt defaultMdt;

    /**
     * @description Method to return an instance of the class.
     * If one hasn't been created then initiate a new one.
     *
     * @return Class instance of VAT Validator
     */
    public static COMM_DO_VATNumberValidation getInstance() {
        if (instance == null) {
            instance = new COMM_DO_VATNumberValidation();
        }
        return instance;
    }

    /**
     * @description Method to set the default metadata in a test class for better testing
     *
     * @param testDefaultMdt Default Metadata Record to be used
     **/
    @TestVisible
    private void setDefaultMetadata(COMM_VATNumberRule__mdt testDefaultMdt) {
        defaultMdt = testDefaultMdt;
    }

    /**
     * @description Constructor to initialize Rule Map
     */
    private COMM_DO_VATNumberValidation() {
        for (COMM_VATNumberRule__mdt vatNumberRule : COMM_VATNumberRule__mdt.getAll().values()) {
            mdtMapByCountryCode.put(vatNumberRule.COMM_CountryShortCode__c.toUpperCase(), vatNumberRule);

            //Store the default metadata
            if (vatNumberRule.COMM_IsDefault__c) {
                defaultMdt = vatNumberRule;
            }
        }
    }

    /**
     * @description Check if a VAT number is valid. Optionally specify if blank values are valid or not
     *
     * @param countryCode The Country Code that is used for validation
     * @param vatNumber The VAT Number to validate
     * @param isBlankValid Specify if Blank Values are accepted as valid VAT Numbers
     * @return True if VAT Number is a valid VAT for the country, false otherwise
     **/
    public boolean isValid(string countryCode, string vatNumber, boolean isBlankValid) {
        return string.isNotBlank(vatNumber) ? this.validateVATNumber(countryCode, vatNumber) : isBlankValid;
    }

    /**
     * @description Helper method for isValid. Check if a VAT number is valid.
     * If a country code is passed, then the VAT number will be validated against the rule for the selected country
     * Else it's validated gainst the default rule
     *
     * @param countryCode The Country Code that is used for validation
     * @param vatNumber The VAT Number to validate
     * @return True if VAT Number is a valid VAT for the country, false otherwise
     **/
    private boolean validateVATNumber(String countryCode, String vatNumber) {
        Boolean isValidNumber = false;
        countryCode = getCountryCode(countryCode);
        vatNumber = countryCode + vatNumber.deleteWhitespace();
        return validateWithCountryCode(countryCode, vatNumber);
    }

    /**
     * @description Helper method to resolve the country code
     * If the country code was passed, use the country code provided.
     * If country wasn't provided, then use the default country code
     *
     * @param countryCode The Code of the Country whose rules will be used on the validation
     * @return Country Code that is used for validation
     **/
    private string getCountryCode(String countryCode) {
        String actualCountryCode = '';
        if (String.isNotBlank(countryCode)) {
            actualCountryCode = countryCode;
        } else {
            actualCountryCode = defaultMdt.COMM_CountryShortCode__c;
        }
        return actualCountryCode.toUpperCase();
    }

    /**
     * @description Helper method for validateVATNumber
     * Validate the vat number with the rule for the selected country
     *
     * @param countryCode The Country Code that is used for validation
     * @param vatNumber The VAT Number to validate
     * @return True if VAT Number is a valid VAT for the country, false otherwise
     **/
    private boolean validateWithCountryCode(String countryCode, String vatNumber) {
        Boolean isValidNumber = true;
        COMM_VATNumberRule__mdt vatNumberRule = mdtMapByCountryCode.get(countryCode);
        if (vatNumberRule != null) {
            switch on countryCode {
                when 'PT' {
                    //For PT VAT Numbers validate the regex and the checksum
                    isValidNumber = validatePT(vatNumberRule.COMM_Rule__c, vatNumber);
                }
                when else {
                    isValidNumber = Pattern.matches(vatNumberRule.COMM_Rule__c, vatNumber);
                }
            }
        }
        return isValidNumber;
    }

    /**
     * @description Validate Portuguese vat numbers
     *
     * @param rule The Portuguese Pattern Rule (9 digits)
     * @param vatNumber The VAT Number to validate
     * @return True if VAT Number is a valid Portuguese VAT, false otherwise
     **/
    private Boolean validatePT(String rule, String vatNumber) {
        Boolean isValid = true;
        if (Pattern.matches(rule, vatNumber)) {
            String rightDigits = vatNumber.right(9);
            Integer vatCheckValue = Integer.valueOf(vatNumber.right(1));
            Integer checkSum = 0;
            for (Integer index = 0; index < 8; index++) {
                checkSum += Integer.valueOf(rightDigits.charAt(index)) * (9 - index);
            }
            Integer checkValue = 11 - Math.mod(checkSum, 11);
            if ((checkValue > 9 && vatCheckValue != 0) || (checkValue <= 9 && vatCheckValue != checkValue)) {
                isValid = false;
            }
        } else {
            isValid = false;
        }

        return isValid;
    }
}