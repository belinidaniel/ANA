/**
 * @author Daniel Lascas
 * @description Test class for COMM_DO_VATNumberValidation
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    05/02/2022       Original Version
 **/
@isTest
private class COMM_DO_VATNumberValidationTest {
    private final static string DEFAULT_COUNTRY = 'PT'; //Portugal
    @isTest
    static void validateVATWithCountryCodeTest() {
        //Scenario: Number is a valid number and the country code is provided
        //Expected: The numbers should be identified as valid

        COMM_DO_VATNumberValidation vatValidation = COMM_DO_VATNumberValidation.getInstance();
        Boolean actualResult = vatValidation.isValid(DEFAULT_COUNTRY, '248500147', false);
        Assert.isTrue(actualResult, 'Expected VAT Number to be valid');

        //Scenario: Number is an invalid number and the country code is provided
        //Expected: The numbers should be identified as invalid
        Boolean actualResult2 = vatValidation.isValid('BE', 'BE1234567890', false);
        Assert.isFalse(actualResult2, 'Expected VAT Number to be invalid');

        Boolean actualResult3 = vatValidation.isValid(DEFAULT_COUNTRY, 'PT248500147', false);
        Assert.isFalse(actualResult3, 'Expected VAT Number to be invalid');

        Boolean actualResult4 = vatValidation.isValid(DEFAULT_COUNTRY, '248500148', false);
        Assert.isFalse(actualResult4, 'Expected VAT Number to be invalid');

        Boolean actualResult5 = vatValidation.isValid(DEFAULT_COUNTRY, 'PT111122111', false);
        Assert.isFalse(actualResult5, 'Expected VAT Number to be invalid');
    }

    @isTest
    static void validateVATWithDefaultRuleTest() {
        COMM_VATNumberRule__mdt defaultMdt = [
            SELECT Id, COMM_CountryShortCode__c, COMM_Rule__c
            FROM COMM_VATNumberRule__mdt
            WHERE COMM_CountryShortCode__c = :DEFAULT_COUNTRY
        ];
        //Scenario: Number is a valid number and the country code is not provided.
        //Expected: The numbers should be identified as valid and validated against the default rule
        COMM_DO_VATNumberValidation vatValidation = COMM_DO_VATNumberValidation.getInstance();
        if (defaultMdt != null) {
            vatValidation.setDefaultMetadata(defaultMdt);
        }
        Boolean actualResult = vatValidation.isValid(null, '248500147', false);
        Assert.isTrue(actualResult, 'Expected VAT Number to be valid');

        //Scenario: Number is an invalid number and the country code is not provided.
        //Expected: The numbers should be identified as invalid and validated against the default rule
        Boolean actualResult2 = vatValidation.isValid(null, '2485001470000', false);
        Assert.isFalse(actualResult2, 'Expected VAT Number to be invalid');
    }

    @isTest
    static void validateVATIsBlankTest() {
        //Scenario: Number is blank or null and blanks should be accepted as valid
        //Expected: The numbers should be identified as valid
        COMM_DO_VATNumberValidation vatValidation = COMM_DO_VATNumberValidation.getInstance();
        Boolean actualResult = vatValidation.isValid(DEFAULT_COUNTRY, '', true);
        Assert.isTrue(actualResult, 'Expected VAT Number to be valid');

        Boolean actualResult2 = vatValidation.isValid(DEFAULT_COUNTRY, null, true);
        Assert.isTrue(actualResult2, 'Expected VAT Number to be valid');

        //Scenario: Number is blank or null and blanks should not be accepted as valid
        //Expected: The numbers should be identified as invalid
        Boolean actualResult3 = vatValidation.isValid(DEFAULT_COUNTRY, '', false);
        Assert.isFalse(actualResult3, 'Expected VAT Number to be invalid');

        Boolean actualResult4 = vatValidation.isValid(DEFAULT_COUNTRY, null, false);
        Assert.isFalse(actualResult4, 'Expected VAT Number to be invalid');
    }
}