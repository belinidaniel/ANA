/**
 * @file File that manages comm__accountInformation functionalities.
 */

import { accountInformation, global, input } from 'c/i18n';
import { patterns, validations } from 'c/constants';
import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { changeLanguage } from 'c/languageUtils';
import LANG from '@salesforce/i18n/lang';
import currentLanguage from '@salesforce/i18n/lang';

import basePath from '@salesforce/community/basePath';
import retrieveAccountDetails from '@salesforce/apex/COMM_LCC_AccountInformation.retrieveAccountDetails';
import updateAccountDetails from '@salesforce/apex/COMM_LCC_AccountInformation.updateAccountDetails';
import getCountryPicklistValues from '@salesforce/apex/COMM_LCC_AccountInformation.getCountryPicklistValues';
import changePassword from '@salesforce/apex/COMM_LCC_AccountInformation.changePassword';
import changeUserEmail from '@salesforce/apex/COMM_LCC_AccountInformation.changeEmail';
import deactivateAccount from '@salesforce/apex/COMM_LCC_AccountInformation.deactivateAccount';
import ToastContainer from 'lightning/toastContainer';
import siteInfo from '@salesforce/apex/COMM_LCC_Site.getExperienceId';
import validateVAT from '@salesforce/apex/COMM_LCC_AccountInformation.validateVAT';

// Constants
const SELECTOR = {
    modal: {
        deleteAccount: '.comm-account-information__delete-account-modal',
        changePassword: '.comm-account-information__change-pass-modal',
        changeEmail: '.comm-account-information__change-email-modal'
    },

    source: {
        deleteAccount: 'modal-delete-account',
        changePassword: 'modal-change-password',
        changeEmail: 'modal-change-email',
        submitInformation: 'submit-information'
    },

    input: {
        personalFirstName: 'personal-first-name',
        personalLastName: 'personal-last-name',
        personalPhoneCode: 'personal-phone-code',
        personalPhoneNumber: 'personal-phone-number',
        billingFirstName: 'billing-first-name',
        billingLastName: 'billing-last-name',
        billingVATNumber: 'billing-vat-number',
        billingAddress: 'billing-address-street',
        billingZipCode: 'billing-address-zipcode',
        billingCity: 'billing-address-city',
        billingCountry: 'billing-address-country',
        companyName: 'company-name',
        companyVATNumber: 'company-vat-number',
        companyAddress: 'company-address-street',
        companyZipCode: 'company-address-zipcode',
        companyCity: 'company-address-city',
        companyCountry: 'company-address-country',
        marketingConsent: 'marketing-consent',
        preferencialContact: 'preferencial-contact'
    },

    emailChange: {
        newEmail: 'new-email',
        confirmEmail: 'confirm-email',
        confirmButton: 'confirm-email-button'
    }
};

export default class Comm_accountInformation extends NavigationMixin(LightningElement) {
    //Controller to determine if Form shown is the one designed for Partners
    @api showPartnerForm;
    @api commerceLogoutLink;
    @api modalEmailLink;

    //Loading Spinner
    isLoading = false;

    // Modal Password properties
    changePassword = false;
    isChangePassword = true;

    // Modal Email properties
    isEmailConfirm = true;
    isEmailSent = false;
    isEmailChanged = false;
    newEmailValid = false;
    confirmEmailValid = false;
    newEmail;
    confirmEmail;
    changedEmailResultWasShown = false;

    // Modal Account properties
    deleteAccount = true;
    isAccountDeleted = false;
    showDeleteSpinner = false;

    pattern = {
        phoneCode: patterns.PHONE_CODE,
        mobilePhone: patterns.MOBILE_PHONE,
        name: patterns.NAME
    };

    validation = {
        vatCharLimit: validations.VAT_CHAR_LIMIT,
        personalFirstNameCharLimit: validations.PERSONAL_FIRSTNAME_CHAR_LIMIT,
        personalLastNameCharLimit: validations.PERSONAL_LASTNAME_CHAR_LIMIT,
        privateBillingFirstNameCharLimit: validations.PRIVATEBILLING_FIRSTNAME_CHAR_LIMIT,
        privateBillingLastNameCharLimit: validations.PRIVATEBILLING_LASTNAME_CHAR_LIMIT,
        privateBillingAddressCharLimit: validations.PRIVATEBILLING_ADDRESS_CHAR_LIMIT,
        privateBillingPostalCodeCharLimit: validations.PRIVATEBILLING_POSTALCODE_CHAR_LIMIT,
        privateBillingCityCharLimit: validations.PRIVATEBILLING_CITY_CHAR_LIMIT,
        companyBillingNameCharLimit: validations.COMPANYBILLING_NAME_CHAR_LIMIT,
        companyBillingAddressCharLimit: validations.COMPANYBILLING_ADDRESS_CHAR_LIMIT,
        companyBillingCityCharLimit: validations.COMPANYBILLING_CITY_CHAR_LIMIT,
        companyBillingPostalCodeCharLimit: validations.COMPANYBILLING_POSTALCODE_CHAR_LIMIT
    };

    label = {
        personalDataTitle: accountInformation.PERSONAL_DATA_TITLE,
        personalDataChangePass: accountInformation.PERSONAL_DATA_CHANGE_PASS,
        personalDataFirstName: accountInformation.PERSONAL_DATA_FIRST_NAME,
        personalDataLastName: accountInformation.PERSONAL_DATA_LAST_NAME,
        personalDataEmail: accountInformation.PERSONAL_DATA_EMAIL,
        personalDataCode: accountInformation.PERSONAL_DATA_CODE,
        personalDataMobile: accountInformation.PERSONAL_DATA_MOBILE,
        personalDataInfo: accountInformation.PERSONAL_DATA_INFO,
        personalDataChangeEmail: accountInformation.PERSONAL_DATA_CHANGE_EMAIL,
        billingDataTitle: accountInformation.BILLING_DATA_TITLE,
        billingDataFirstName: accountInformation.BILLING_DATA_FIRST_NAME,
        billingDataLastName: accountInformation.BILLING_DATA_LAST_NAME,
        billingDataNif: accountInformation.BILLING_DATA_NIF,
        billingDataAddress: accountInformation.BILLING_DATA_ADDRESS,
        billingDataPostalCode: accountInformation.BILLING_DATA_POSTAL_CODE,
        billingDataCity: accountInformation.BILLING_DATA_CITY,
        billingDataCountry: accountInformation.BILLING_DATA_COUNTRY,
        companyDataTitle: accountInformation.COMPANY_DATA_TITLE,
        companyDataTitleB2B: accountInformation.COMPANY_DATA_TITLE_B2B,
        companyDataName: accountInformation.COMPANY_DATA_NAME,
        companyDataEmail: accountInformation.COMPANY_DATA_EMAIL,
        companyDataNif: accountInformation.COMPANY_DATA_NIF,
        companyDataAddress: accountInformation.COMPANY_DATA_ADDRESS,
        companyDataPostalCode: accountInformation.COMPANY_DATA_POSTAL_CODE,
        companyDataCity: accountInformation.COMPANY_DATA_CITY,
        companyDataCountry: accountInformation.COMPANY_DATA_COUNTRY,
        marketingDataTitle: accountInformation.MARKETING_DATA_TITLE,
        marketingDataInfo: accountInformation.MARKETING_DATA_INFO,
        contactDataTitle: accountInformation.CONTACT_DATA_TITLE,
        contactDataEmail: accountInformation.CONTACT_DATA_EMAIL,
        contactDataMobile: accountInformation.CONTACT_DATA_MOBILE,
        staffDataInfo: accountInformation.STAFF_DATA_INFO,
        staffDataButton: accountInformation.STAFF_DATA_BUTTON,
        dataSaveButton: accountInformation.DATA_SAVE_BUTTON,
        dataSaveSuccessMessage: accountInformation.DATA_SAVE_SUCCESS_MESSAGE,
        dataDeleteAccountButton: accountInformation.DATA_DELETE_ACCOUNT_BUTTON,
        modalDeleteAccountTitle: accountInformation.MODAL_DELETE_ACCOUNT_TITLE,
        modalDeleteAccountInfo: accountInformation.MODAL_DELETE_ACCOUNT_INFO,
        deleteAccountYesButton: accountInformation.MODAL_DELETE_ACCOUNT_BUTTON_YES,
        deleteAccountNoButton: accountInformation.MODAL_DELETE_ACCOUNT_BUTTON_NO,
        deleteAccountInfo1: accountInformation.MODAL_DELETE_ACCOUNT_INFO_1,
        deleteAccountInfo2: accountInformation.MODAL_DELETE_ACCOUNT_INFO_2,
        deleteAccountInfo3: accountInformation.MODAL_DELETE_ACCOUNT_INFO_3,
        deleteAccountInfo4: accountInformation.MODAL_DELETE_ACCOUNT_INFO_4,
        deleteAccountInfo5: accountInformation.MODAL_DELETE_ACCOUNT_INFO_5,
        modalChangePassTitle: accountInformation.MODAL_CHANGE_PASS_TITLE,
        modalChangePassInfo1: accountInformation.MODAL_CHANGE_PASS_INFO1,
        modalChangePassInfo2: accountInformation.MODAL_CHANGE_PASS_INFO2,
        modalChangePassYesButton: accountInformation.MODAL_CHANGE_PASS_YES_BUTTON,
        modalChangePassNoButton: accountInformation.MODAL_CHANGE_PASS_NO_BUTTTON,
        modalChangePassSentMail1: accountInformation.MODAL_CHANGE_PASS_SENT_MAIL1,
        modalChangePassSentMail2: accountInformation.MODAL_CHANGE_PASS_SENT_MAIL2,
        modalChangeEmailTitle: accountInformation.MODAL_CHANGE_EMAIL_TITLE,
        modalChangeEmailInfo: accountInformation.MODAL_CHANGE_EMAIL_INFO,
        modalChangeEmailNew: accountInformation.MODAL_CHANGE_EMAIL_NEW,
        modalChangeEmailNewConfirm: accountInformation.MODAL_CHANGE_EMAIL_CONFIRM_NEW,
        modalChangeEmailButtonConfirm: accountInformation.MODAL_CHANGE_EMAIL_BUTTON_CONFIRM,
        modalConfirmEmailInfo: accountInformation.MODAL_CONFIRM_EMAIL_INFO,
        modalConfirmEmailNew: accountInformation.MODAL_CONFIRM_EMAIL_NEW,
        modalConfirmEmailConfirmNew: accountInformation.MODAL_CONFIRM_EMAIL_CONFIRM_NEW,
        modalConfirmEmailButtonConfirm: accountInformation.MODAL_CONFIRM_EMAIL_BUTTON_CONFIRM,
        modalConfirmEmailEmailSent1: accountInformation.MODAL_CONFIRM_EMAIL_SENT1,
        modalConfirmEmailEmailSent2: accountInformation.MODAL_CONFIRM_EMAIL_SENT2,
        modalConfirmEmailSuccess: accountInformation.MODAL_CONFIRM_EMAIL_SUCCESS,
        modalConfirmEmailExpired: accountInformation.MODAL_CONFIRM_EMAIL_EXPIRED,
        carTitle: accountInformation.CAR_TITLE,
        carOne: accountInformation.CAR_ONE,
        carPlate: accountInformation.CAR_PLATE,
        carBrand: accountInformation.CAR_BRAND,
        carModel: accountInformation.CAR_MODEL,
        carTwo: accountInformation.CAR_TWO,
        carTerms: accountInformation.CAR_TERMS,
        carStaffTitle: accountInformation.CAR_STAFF_TITLE,
        carStaffWorkFunction: accountInformation.CAR_STAFF_WORK_FUNCTION,
        carStaffInfo1: accountInformation.CAR_STAFF_INFO1,
        carStaffInfo2: accountInformation.CAR_STAFF_INFO2,
        carStaffFirstTerms: accountInformation.CAR_STAFF_FIRST_TERMS,
        carStaffSecondTerms: accountInformation.CAR_STAFF_SECOND_TERMS,
        carStaffInfoThirdTerms: accountInformation.CAR_STAFF_THIRD_TERMS,
        staffSubmitButton: accountInformation.STAFF_SUBMIT_BUTTON,
        requestInApproval: accountInformation.REQUEST_IN_APPROVAL,
        requestAlreadyExists: accountInformation.REQUEST_ALREADY_EXISTS,
        mainTitle: accountInformation.MAIN_TITLE,
        dataDeactivateAccountButton: accountInformation.DATA_DEACTIVATE_ACCOUNT_BUTTON,
        modalDeactivateAccountTitle: accountInformation.MODAL_DEACTIVATE_ACCOUNT_TITLE,
        modalDeactivateAccountInfo: accountInformation.MODAL_DEACTIVATE_ACCOUNT_INFO,
        deactivateAccountYesButton: accountInformation.MODAL_DEACTIVATE_ACCOUNT_BUTTON_YES,
        deactivateAccountNoButton: accountInformation.MODAL_DEACTIVATE_ACCOUNT_BUTTON_NO,
        deactivateAccountInfo1: accountInformation.MODAL_DEACTIVATE_ACCOUNT_INFO_1,
        invalidVatErrorMessage: accountInformation.INVALID_VAT_ERROR,
        successToastTitle: global.TOAST_MESSAGE_TITLE,
        successToastMessage: global.TOAST_MESSAGE_MESSAGE,
        errorToastTitle: global.TOAST_MESSAGE_ERROR_TITLE,
        toastPosition: global.TOAST_MESSAGE_POSITION_VARIANT,
        deactivateAccountInfo2: accountInformation.MODAL_DEACTIVATE_ACCOUNT_INFO_2,
        phoneCodeErrorMessage: input.PHONE_CODE_ERROR_MESSAGE,
        nameErrorMessage: input.NAME_ERROR_MESSAGE,
        vatErrorMessage: input.VAT_ERROR_MESSAGE
    };

    countryOptions;
    accountData = {};
    isDisabled = true;
    siteExperience = null;
    isDisabledButtonModal = true;
    preferMobileContact = false;
    isAffiliate = 'false';

    /**
     * Update the Section class based on showPartnerForm flag.
     */
    updateSectionClass() {
        const section = this.template.querySelector('.comm-account-information__personal-data');
        if (section && this.showPartnerForm) {
            section.classList.add('comm-account-information__personal-data-partner');
        } else {
            section.classList.remove('comm-account-information__personal-data-partner');
        }
    }

    renderedCallback() {
        this.updateSectionClass();
        this.emailChangedModal();
        this.getLanguageFromCommerce();
        this.setAffiliateData();
    }

    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxShown = 1;
        toastContainer.toastPosition = this.label.toastPosition;
        // Call Controller Method to obtain Picklist Valus for Country Input Selects
        getCountryPicklistValues()
            .then((result) => {
                this.countryOptions = Object.entries(result).map(([value, label]) => ({ value, label }));
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            });
        // Call Controller Method to retrieve Information of User's Account
        retrieveAccountDetails()
            .then((result) => {
                this.accountData = result;
                this.preferMobileContact = result.preferencialContact;
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            });
    }

    /**
     * Set accountData.isAffiliate to true.
     */
    setAffiliateData() {
        if (this.accountData.isAffiliate) {
            this.isAffiliate = 'true';
        }
    }

    /**
     * Gets language from commerce.
     */
    getLanguageFromCommerce() {
        if (LANG !== null) {
            siteInfo()
                .then((data) => {
                    if (data) {
                        this.siteExperience = data;

                        if (this.siteExperience === 'pt') {
                            this.siteExperience = 'pt_PT';
                        } else if (this.siteExperience === 'en') {
                            this.siteExperience = 'en_US';
                        } else {
                            this.siteExperience = 'es';
                        }

                        const storedLanguage = sessionStorage.getItem('siteExperience');
                        if (storedLanguage !== this.siteExperience) {
                            sessionStorage.setItem('siteExperience', this.siteExperience);
                            changeLanguage(this.siteExperience, currentLanguage);
                        }
                    }
                })
                .catch(() => {
                    this.siteExperience = LANG;
                });
        }
    }

    @wire(CurrentPageReference)
    /**
     * Handles the request from the wire service. Verifies Page Parameters and if it exist retrieve token.
     *
     * @param {object} currentPageReference - Object with the data received from request.
     */
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            this.startUrl = currentPageReference.state?.startURL;
            const emailChangeToken = currentPageReference.state?.emailChangeSuccess;
            //Check Email Change Token value
            if (emailChangeToken) {
                this.isEmailConfirm = false;
                this.isEmailChanged = emailChangeToken === 'true';
                this.isEmailInvalid = !this.isEmailChanged;
            }
        }
    }

    /**
     * Opens Email Changed Modal if it was set to open.
     */
    emailChangedModal() {
        if ((this.isEmailChanged || this.isEmailInvalid) && !this.changedEmailResultWasShown) {
            //Open modal and set control variable to true to prevent reopening on rerender
            this.template.querySelector(SELECTOR.modal.changeEmail).open();
            this.changedEmailResultWasShown = true;
        }
    }

    /**
     * Control Variable getter. Used when identifying required fields.
     *
     * @returns {boolean} True if B2B, false if B2C.
     */
    get isB2B() {
        return !this.accountData.isB2C;
    }

    /**
     * This getter returns a `mailto:` link using the email address stored in `this.modalEmailLink`.
     *
     * @returns {string} The formatted mailto link.
     */
    get modalEmailLinkHref() {
        return `mailto:${this.modalEmailLink}`;
    }

    /**
     * Control Variable getter. Used when identifying required contact fields.
     *
     * @returns {boolean} True if Customer, false otherwise.
     */
    get isCustomer() {
        return !this.showPartnerForm;
    }

    /**
     * Control Variable getter. Used when identifying disabled contact fields.
     *
     * @returns {boolean} True if Partner Admin, false otherwise.
     */
    get isPartner() {
        return this.showPartnerForm;
    }

    /**
     * Obtain the Label used for the Company Billing Data Section (different depending if B2B or B2C).
     *
     * @returns {string} Section label.
     */
    get companyDataSectionTitle() {
        return this.isB2B ? this.label.companyDataTitleB2B : this.label.companyDataTitle;
    }

    changedAccountData = {};

    /**
     * Handles to Open the modal.
     *
     * @param {Event} event - The event containing the selected modal.
     */
    handleOnClick(event) {
        const source = event.target.dataset.src;
        switch (source) {
            case SELECTOR.source.deleteAccount:
                //Set Modal Delete Account properties  to default then open modal
                this.deleteAccount = true;
                this.isAccountDeleted = false;
                this.template.querySelector(SELECTOR.modal.deleteAccount).open();
                break;
            case SELECTOR.source.changeEmail:
                //Set Modal Change Email properties  to default then open modal
                this.isEmailConfirm = true;
                this.isEmailSent = false;
                this.isEmailChanged = false;
                this.isEmailInvalid = false;
                this.template.querySelector(SELECTOR.modal.changeEmail).open();
                break;
            case SELECTOR.source.changePassword:
                //Set Modal Change Password properties  to default then open modal
                this.changePassword = false;
                this.isChangePassword = true;
                this.template.querySelector(SELECTOR.modal.changePassword).open();
                break;
            case SELECTOR.source.submitInformation:
                this.submitInformation();
                break;
            default:
                break;
        }
        this.isDisabled = true;
    }

    /**
     * Handles the event when one of the input forms change.
     *
     * @param {Event} event - The event containing the changed input.
     */
    handleOnChange(event) {
        const source = event.target.dataset.src;

        switch (source) {
            case SELECTOR.input.personalFirstName:
                this.changedAccountData.personalFirstName = event.target.value;
                break;
            case SELECTOR.input.personalLastName:
                this.changedAccountData.personalLastName = event.target.value;
                break;
            case SELECTOR.input.personalPhoneCode:
                this.changedAccountData.personalPhoneCode = event.target.value;
                break;
            case SELECTOR.input.personalPhoneNumber:
                this.changedAccountData.personalPhoneNumber = event.target.value;
                break;
            case SELECTOR.input.billingFirstName:
                this.changedAccountData.billingFirstName = event.target.value;
                break;
            case SELECTOR.input.billingLastName:
                this.changedAccountData.billingLastName = event.target.value;
                break;
            case SELECTOR.input.billingVATNumber: {
                this.changedAccountData.billingVATNumber = event.target.value;
                //Clear invalid VAT error message on change (is validated before submiting)
                event.target.setCustomValidity('');
                break;
            }
            case SELECTOR.input.billingAddress:
                this.changedAccountData.billingAddress = event.target.value;
                break;
            case SELECTOR.input.billingZipCode:
                this.changedAccountData.billingZipCode = event.target.value;
                break;
            case SELECTOR.input.billingCity:
                this.changedAccountData.billingCity = event.target.value;
                break;
            case SELECTOR.input.billingCountry: {
                this.changedAccountData.billingCountry = event.target.value;
                //Clear invalid VAT error message on change (is validated before submiting)
                this.template.querySelector('[data-src=' + SELECTOR.input.billingVATNumber + ']').setCustomValidity('');
                break;
            }
            case SELECTOR.input.companyName:
                this.changedAccountData.companyName = event.target.value;
                break;
            case SELECTOR.input.companyVATNumber: {
                this.changedAccountData.companyVATNumber = event.target.value;
                //Clear invalid VAT error message on change (is validated before submiting)
                event.target.setCustomValidity('');
                break;
            }
            case SELECTOR.input.companyAddress:
                this.changedAccountData.companyAddress = event.target.value;
                break;
            case SELECTOR.input.companyZipCode:
                this.changedAccountData.companyZipCode = event.target.value;
                break;
            case SELECTOR.input.companyCity:
                this.changedAccountData.companyCity = event.target.value;
                break;
            case SELECTOR.input.companyCountry: {
                this.changedAccountData.companyCountry = event.target.value;
                //Clear invalid VAT error message on change (is validated before submiting)
                this.template.querySelector('[data-src=' + SELECTOR.input.companyVATNumber + ']').setCustomValidity('');
                break;
            }
            case SELECTOR.input.marketingConsent:
                this.changedAccountData.marketingConsent = event.detail.checked;
                break;
            case SELECTOR.input.preferencialContact:
                this.changedAccountData.preferencialContact = event.target.checked;
                this.preferMobileContact = event.target.checked;
                break;
            default:
                break;
        }
        this.isDisabled = !this.validateData();
    }

    /**
     * Handles the event when one email input change.
     *
     * @param {Event} event - The event containing the changed input.
     */
    handleOnEmailChange(event) {
        const source = event.target.dataset.src;
        switch (source) {
            case SELECTOR.emailChange.newEmail:
                this.newEmail = event.target.value;
                this.newEmailValid = event.target.validity;
                break;
            case SELECTOR.emailChange.confirmEmail:
                this.confirmEmail = event.target.value;
                this.confirmEmailValid = event.target.validity;
                break;
            default:
                break;
        }
        this.isDisabledButtonModal = !this.validateEmail();
    }

    /**
     * Submit's data to the controller.
     */
    async submitInformation() {
        this.isLoading = true;
        if (this.validateData() && (await this.validateVATData())) {
            //If First or Last Name was changed but not both, then include both to the changed data JSON
            if (this.changedAccountData.personalFirstName == null && this.changedAccountData.personalLastName != null) {
                this.changedAccountData.personalFirstName = this.accountData.personalFirstName;
            } else if (this.changedAccountData.personalFirstName != null && this.changedAccountData.personalLastName == null) {
                this.changedAccountData.personalLastName = this.accountData.personalLastName;
            }
            //If Phone Number or Phone Code was changed but not both, then include both to the changed data JSON
            if (this.changedAccountData.personalPhoneNumber == null && this.changedAccountData.personalPhoneCode != null) {
                this.changedAccountData.personalPhoneNumber = this.accountData.personalPhoneNumber;
            } else if (this.changedAccountData.personalPhoneNumber != null && this.changedAccountData.personalPhoneCode == null) {
                this.changedAccountData.personalPhoneCode = this.accountData.personalPhoneCode;
            }

            this.changedAccountData.isB2C = this.accountData.isB2C;
            this.changedAccountData.isAffiliate = this.accountData.isAffiliate;
            this.changedAccountData.accountId = this.accountData.accountId;
            this.changedAccountData.contactId = this.accountData.contactId;

            updateAccountDetails({ accountDataJSON: this.changedAccountData })
                .then(() => {
                    this.showToast('success', this.label.successToastTitle);
                })
                .catch(() => {
                    this.showToast('error', this.label.errorToastTitle);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.isLoading = false;
        }
    }

    /**
     * Validates if the data on the form is valid. Checks if required fields are filled and their values are valid.
     *
     * @returns {boolean} True if data is valid, false otherwise.
     */
    validateData() {
        const isB2C = this.accountData.isB2C;

        //Obtain Form Values
        //Personal Data Section
        const personalFirstName = this.template.querySelector('[data-src=' + SELECTOR.input.personalFirstName + ']').validity;
        const personalLastName = this.template.querySelector('[data-src=' + SELECTOR.input.personalLastName + ']').validity;
        const personalPhoneCode = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneCode + ']').validity;
        const personalPhoneNumber = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneNumber + ']').validity;

        //For B2B, Billing and Company Billing Information cannot be changed so validity is skipped for these fields
        let billingDataValidity;
        if (isB2C) {
            //Billing Data Section
            const billingFirstName = this.template.querySelector('[data-src=' + SELECTOR.input.billingFirstName + ']').validity;
            const billingLastName = this.template.querySelector('[data-src=' + SELECTOR.input.billingLastName + ']').validity;
            const billingAddress = this.template.querySelector('[data-src=' + SELECTOR.input.billingAddress + ']').validity;
            const billingZipCode = this.template.querySelector('[data-src=' + SELECTOR.input.billingZipCode + ']').validity;
            const billingCity = this.template.querySelector('[data-src=' + SELECTOR.input.billingCity + ']').validity;
            const billingCountry = this.template.querySelector('[data-src=' + SELECTOR.input.billingCountry + ']').validity;
            const billingVATNumber = this.template.querySelector('[data-src=' + SELECTOR.input.billingVATNumber + ']').validity;

            //Company Billing Data Section
            const companyName = this.template.querySelector('[data-src=' + SELECTOR.input.companyName + ']').validity;
            const companyVATNumber = this.template.querySelector('[data-src=' + SELECTOR.input.companyVATNumber + ']').validity;
            const companyAddress = this.template.querySelector('[data-src=' + SELECTOR.input.companyAddress + ']').validity;
            const companyZipCode = this.template.querySelector('[data-src=' + SELECTOR.input.companyZipCode + ']').validity;
            const companyCity = this.template.querySelector('[data-src=' + SELECTOR.input.companyCity + ']').validity;
            const companyCountry = this.template.querySelector('[data-src=' + SELECTOR.input.companyCountry + ']').validity;

            billingDataValidity =
                billingFirstName &&
                billingLastName &&
                billingVATNumber &&
                billingAddress &&
                billingZipCode &&
                billingCity &&
                billingCountry &&
                companyName &&
                companyVATNumber &&
                companyAddress &&
                companyZipCode &&
                companyCity &&
                companyCountry;
        } else {
            billingDataValidity = true;
        }

        return personalFirstName && personalLastName && personalPhoneCode && personalPhoneNumber && billingDataValidity;
    }

    /**
     * Validates if VAT Number fields on the form are valid. If they are invalid, input is set to show invalid vat error message.
     *
     * @returns {Promise<boolean>} True if vat numbers are valid, false otherwise.
     */
    async validateVATData() {
        const isB2C = this.accountData.isB2C;
        //For B2B, Billing and Company Billing Information cannot be changed so VAT validity is skipped
        if (isB2C) {
            const billingCountry = this.template.querySelector('[data-src=' + SELECTOR.input.billingCountry + ']').value;
            const billingVATNumberForm = this.template.querySelector('[data-src=' + SELECTOR.input.billingVATNumber + ']');

            //Company Billing Data Section
            const companyVATNumberForm = this.template.querySelector('[data-src=' + SELECTOR.input.companyVATNumber + ']');
            const companyCountry = this.template.querySelector('[data-src=' + SELECTOR.input.companyCountry + ']').value;

            let billingValidation;
            let companyValidation;

            //Call Controller to validate Billing VAT Number.
            await validateVAT({ vatToValidate: billingVATNumberForm.value, countryCode: billingCountry })
                .then((result) => {
                    //Update Input to show error if validation returns false
                    billingValidation = result;
                    if (!billingValidation) {
                        billingVATNumberForm.setCustomValidity(this.label.invalidVatErrorMessage);
                    }
                })
                .catch(() => {
                    billingVATNumberForm.setCustomValidity(this.label.invalidVatErrorMessage);
                    billingValidation = false;
                });

            //Company Billing is Opcional so validate only if VAT was filled
            if (companyVATNumberForm.value) {
                await validateVAT({ vatToValidate: companyVATNumberForm.value, countryCode: companyCountry })
                    .then((result) => {
                        //Update Input to show error if validation returns false
                        companyValidation = result;
                        if (!companyValidation) {
                            companyVATNumberForm.setCustomValidity(this.label.invalidVatErrorMessage);
                        }
                    })
                    .catch(() => {
                        companyVATNumberForm.setCustomValidity(this.label.invalidVatErrorMessage);
                        companyValidation = false;
                    });
            } else {
                companyValidation = true;
            }

            return billingValidation && companyValidation;
        }
        return true;
    }

    /**
     * Close modals.
     */
    closeModal() {
        this.template.querySelector(`${SELECTOR.modal.deleteAccount}`).close();
        this.template.querySelector(`${SELECTOR.modal.changePassword}`).close();
    }

    /**
     * Calls method to change user password from controller.
     */
    handleChangePassConfirm() {
        changePassword()
            .then(() => {
                this.isChangePassword = false;
                this.changePassword = true;
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            });
    }

    /**
     * Handles change email. Validates user input and if valid calls method to change user email from controller.
     */
    handleChangeEmailConfirm() {
        //Verify that new email was inserted, is a valid (pattern), is different from user's current email and confirm email is the same as new email
        if (this.validateEmail() && this.newEmail === this.confirmEmail && this.newEmail !== this.accountData.personalEmail) {
            changeUserEmail({ newEmail: this.newEmail })
                .then(() => {
                    this.isEmailConfirm = false;
                    this.isEmailSent = true;
                })
                .catch(() => {
                    this.showToast('error', this.label.errorToastTitle);
                });
        } else {
            this.showToast('error', this.label.errorToastTitle);
        }
    }

    /**
     * Validates if the data on the new email form is valid.
     *
     * @returns {boolean} True if new email input is valid, false otherwise.
     */
    validateEmail() {
        return this.newEmail && this.newEmailValid && this.confirmEmailValid && this.confirmEmail;
    }

    /**
     * Handle Delete Account Modal closure event. Logout user if account was deleted.
     */
    handleDeleteClose() {
        //If Account was deleted and user type is customer redirects to Commerce Logout Link
        if (this.isAccountDeleted && this.isCustomer) {
            window.location.replace(this.commerceLogoutLink);
        }
        //If Account was Deleted and user is not Customer then call logout action and redirect to Site's Login Page
        else if (this.isAccountDeleted) {
            window.location.replace('/secur/logout.jsp?retUrl=' + basePath + '%2Flogin');
        }
    }

    /**
     * Handles account deletion. Calls method from controller to initiate
     * deletion and sets user to logout when closing modal or going back.
     */
    handleDeleteAccountConfirm() {
        this.showDeleteSpinner = true;
        deactivateAccount()
            .then(() => {
                this.deleteAccount = false;
                this.isAccountDeleted = true;
                //If user type is customer redirects to Commerce Logout Link, if not set User to redirect user to Login Page
                window.onpopstate = () => {
                    if (this.isCustomer) {
                        window.location.replace(this.commerceLogoutLink);
                    } else {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__loginPage',
                            attributes: {
                                actionName: 'login'
                            }
                        });
                    }
                };
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            })
            .finally(() => {
                this.showDeleteSpinner = false;
            });
    }

    /**
     * Shows a toast message.
     *
     * @param {string} variant - The variant of the toast message (e.g., 'success', 'error').
     * @param {string} message - The message to be displayed in the toast.
     */
    showToast(variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: message,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

    /**
     * Handler for when User presses the button to navigate to Individual Staff Form Page.
     */
    navigateToIndividualStaffForm() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Individual_Staff_Subscription_Request__c'
            }
        });
    }
}