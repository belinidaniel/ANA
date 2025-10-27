/**
 * @file File that manages comm_subscriptionPartnerRequest functionalities.
 */

import { patterns, validations } from 'c/constants';
import { subscriptionPartnerRequest, global, input } from 'c/i18n';
import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import submitCase from '@salesforce/apex/COMM_LCC_SubscriptionPartnerRequest.submitCase';
import getCaseRecord from '@salesforce/apex/COMM_LCC_SubscriptionPartnerRequest.getCaseRecord';
import getCountryPicklistValues from '@salesforce/apex/COMM_LCC_SubscriptionPartnerRequest.getCountryPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import { CurrentPageReference } from 'lightning/navigation';
import currentLanguage from '@salesforce/i18n/lang';
import validateVAT from '@salesforce/apex/COMM_LCC_SubscriptionPartnerRequest.validateVAT';

const FILE_JPEG = 'image/jpeg';
const FILE_PDF = 'application/pdf';

const CONSENT_VALUE_CHECKED = 'Yes';
const CONSENT_VALUE_UNCHECKED = 'No';

const SELECTOR = {
    input: {
        personalFirstName: 'personal-first-name',
        personalLastName: 'personal-last-name',
        personalVAT: 'personal-vat-number',
        personalAddress: 'personal-address-street',
        personalCity: 'personal-address-city',
        personalCountry: 'personal-address-country',
        personalZipCode: 'personal-address-zipcode',
        personalPhoneCode: 'personal-phone-code',
        personalPhoneNumber: 'personal-phone-number',
        personalEmail: 'personal-email-address',
        jobRole: 'job-role',
        vehicleBrand: 'vehicle-brand',
        vehicleModel: 'vehicle-model',
        vehicleLicense: 'vehicle-license',
        secondVehicleBrand: 'second-vehicle-brand',
        secondVehicleModel: 'second-vehicle-model',
        secondVehicleLicense: 'second-vehicle-license',
        fileUploader: 'file-uploader',
        privacyConsent: 'privacy-consent',
        licenseReadingConsent: 'license-reading-consent',
        marketingConsent: 'marketing-consent'
    }
};

export default class Comm_subscriptionPartnerRequest extends NavigationMixin(LightningElement) {
    pattern = {
        phoneCode: patterns.PHONE_CODE,
        mobilePhone: patterns.MOBILE_PHONE
    };

    validation = {
        vatCharLimit: validations.VAT_CHAR_LIMIT,
        privateBillingFirstNameCharLimit: validations.PRIVATEBILLING_FIRSTNAME_CHAR_LIMIT,
        privateBillingLastNameCharLimit: validations.PRIVATEBILLING_LASTNAME_CHAR_LIMIT,
        privateBillingAddressCharLimit: validations.PRIVATEBILLING_ADDRESS_CHAR_LIMIT,
        privateBillingPostalCodeCharLimit: validations.PRIVATEBILLING_POSTALCODE_CHAR_LIMIT,
        privateBillingCityCharLimit: validations.PRIVATEBILLING_CITY_CHAR_LIMIT
    };

    label = {
        personalDataTitle: subscriptionPartnerRequest.PERSONAL_DATA_TITLE,
        billingDataFirstName: subscriptionPartnerRequest.BILLING_DATA_FIRST_NAME,
        billingDataLastName: subscriptionPartnerRequest.BILLING_DATA_LAST_NAME,
        billingDataNif: subscriptionPartnerRequest.BILLING_DATA_NIF,
        personalDataEmail: subscriptionPartnerRequest.PERSONAL_DATA_EMAIL,
        personalDataCode: subscriptionPartnerRequest.PERSONAL_DATA_CODE,
        personalDataMobile: subscriptionPartnerRequest.PERSONAL_DATA_MOBILE,
        billingDataAddress: subscriptionPartnerRequest.BILLING_DATA_ADDRESS,
        billingDataPostalCode: subscriptionPartnerRequest.BILLING_DATA_POSTAL_CODE,
        billingDataCity: subscriptionPartnerRequest.BILLING_DATA_CITY,
        billingDataCountry: subscriptionPartnerRequest.BILLING_DATA_COUNTRY,
        carTitle: subscriptionPartnerRequest.CAR_TITLE,
        carOne: subscriptionPartnerRequest.CAR_ONE,
        carPlate: subscriptionPartnerRequest.CAR_PLATE,
        carBrand: subscriptionPartnerRequest.CAR_BRAND,
        carModel: subscriptionPartnerRequest.CAR_MODEL,
        carTwo: subscriptionPartnerRequest.CAR_TWO,
        carTerms: subscriptionPartnerRequest.CAR_TERMS,
        carStaffTitle: subscriptionPartnerRequest.CAR_STAFF_TITLE,
        carStaffWorkFunction: subscriptionPartnerRequest.CAR_STAFF_WORK_FUNCTION,
        carStaffInfo1: subscriptionPartnerRequest.CAR_STAFF_INFO1,
        carStaffInfo2: subscriptionPartnerRequest.CAR_STAFF_INFO2,
        carStaffFirstTerms: subscriptionPartnerRequest.CAR_STAFF_FIRST_TERMS,
        carStaffSecondTerms: subscriptionPartnerRequest.CAR_STAFF_SECOND_TERMS,
        carStaffInfoThirdTerms: subscriptionPartnerRequest.CAR_STAFF_THIRD_TERMS,
        staffSubmitButton: subscriptionPartnerRequest.STAFF_SUBMIT_BUTTON,
        staffSubmitSentSuccess: subscriptionPartnerRequest.STAFF_SUBMIT_MESSAGE_SUCCESS,
        staffSubmitResponseSoon: subscriptionPartnerRequest.STAFF_SUBMIT_MESSAGE_RESPONSE,
        staffSubmitThankYou: subscriptionPartnerRequest.STAFF_SUBMIT_MESSAGE_THANKS,
        staffSubmitReturnButton: subscriptionPartnerRequest.STAFF_SUBMIT_RETURN_BUTTON,
        mainTitle: subscriptionPartnerRequest.PERSONAL_DATA_MAIN_TITLE,
        invalidVatErrorMessage: subscriptionPartnerRequest.INVALID_VAT_ERROR,
        errorToastTitle: global.TOAST_MESSAGE_ERROR_TITLE,
        successToastTitle: global.TOAST_MESSAGE_TITLE,
        successMessage: global.TOAST_MESSAGE_MESSAGE,
        formValidation: subscriptionPartnerRequest.FORM_VALIDATION,
        formFileValidation: subscriptionPartnerRequest.FORM_FILE_VALIDATION,
        subscriptionNotAvailable: subscriptionPartnerRequest.SUBSCRIPTION_NOT_AVAILABLE,
        subscriptionFormSuccess: subscriptionPartnerRequest.FORM_SUCCESS,
        newSubscription: subscriptionPartnerRequest.SUBSCRIPTION_NEW,
        phoneCodeErrorMessage: input.PHONE_CODE_ERROR_MESSAGE,
        nameErrorMessage: input.NAME_ERROR_MESSAGE
    };

    fillForm = false;
    formAlreadySubmitted = false;
    formSubmitted = false;

    fileUploaded = false;
    fileName = '';

    privacyConsentValue = false;
    licenseReadingConsentValue = false;
    marketingConsentValue = false;

    fieldValidated = false;
    fileValidated = false;

    currentPageReference = null;
    showToastMessage = false;

    countryOptions;

    urlParameters = '';

    recordData = {};

    disabled = false;

    isLoading = false;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if ('result' in currentPageReference.state && currentPageReference.state.result === 'success') {
            this.showToastMessage = true;
        }
    }

    get fileUploadedText() {
        return this.fileUploaded ? this.fileName : this.label.carStaffInfo2;
    }

    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxShown = 1;
        toastContainer.toastPosition = 'top-center';

        const urlSearchParams = new URL(document.location).searchParams;
        this.urlParameters = decodeURIComponent(urlSearchParams);

        //Call Controller Method to obtain record identifier and record data
        getCaseRecord({ urlParameters: this.urlParameters })
            .then((resultFromGetCaseRecor) => {
                this.recordData = resultFromGetCaseRecor;
                if(resultFromGetCaseRecor.status != 'Pending Form'){
                    this.formAlreadySubmitted = true;
                    this.disabled = true;
                } else {
                    this.fillForm = true;
                }
            })
            .catch(() => {
                this.disabled = true;
                this.formAlreadySubmitted = true;
                this.showToast('error', this.label.errorToastTitle);
            });

        //Call Controller Method to obtain Picklist Values for Country Input Selects
        getCountryPicklistValues()
            .then((result) => {
                this.countryOptions = Object.entries(result).map(([value, label]) => ({ value, label }));
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            });
    }

    /**
     * Control variable getter. Used to identify Personal Information related fields to disable.
     *
     * @returns {boolean} True if Case is a Subsctription Information change request or Card Loss/Damage, false otherwise.
     */
    get isPersonalInformationDisabled() {
        return this.recordData.recordTypeDeveloperName === 'COMM_ChangeSubscriptionInformation' ||
            this.recordData.recordTypeDeveloperName === 'COMM_NewCardDueToDamageLoss'
            ? true
            : false;
    }

    /**
     * Control variable getter. Used to identify Vehicle Information related fields to disable.
     *
     * @returns {boolean} True if Case is a Subsctription Information change request or Card Loss/Damage, false otherwise.
     */
    get isVehicleInformationDisabled() {
        return this.recordData.recordTypeDeveloperName === 'COMM_NewCardDueToDamageLoss' ? true : false;
    }

    /**
     * Handler for when User submit file on form.
     */
    handleUploaderClick() {
        const uploader = this.template.querySelector('[data-src=' + SELECTOR.input.fileUploader + ']');
        let fileList = uploader.files;
        let fileType = fileList.length > 0 ? uploader.files.item(0).type : '';

        if (fileType === FILE_JPEG || fileType === FILE_PDF) {
            this.fileUploaded = true;
            this.fileName = uploader.files.item(0).name;
        } else {
            uploader.files = null;
            this.fileUploaded = false;
        }
    }

    /**
     * Handler for when User presses the Submit Button. Retrieves form data and sends it to controller to create Case if valid.
     */
    async handleSubmit() {
        if (this.validateForm() && (await this.validateVATData())) {
            let recordData = {};

            recordData.recordId = this.recordData.recordId;
            recordData.airport = this.recordData.airport;
            recordData.personalFirstName = this.template.querySelector('[data-src=' + SELECTOR.input.personalFirstName + ']').value;
            recordData.personalLastName = this.template.querySelector('[data-src=' + SELECTOR.input.personalLastName + ']').value;
            recordData.personalVAT = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']').value;
            recordData.personalEmail = this.template.querySelector('[data-src=' + SELECTOR.input.personalEmail + ']').value;
            recordData.personalPhoneNumber =
                this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneCode + ']').value +
                ' ' +
                this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneNumber + ']').value;
            recordData.personalAddress = this.template.querySelector('[data-src=' + SELECTOR.input.personalAddress + ']').value;
            recordData.personalZipCode = this.template.querySelector('[data-src=' + SELECTOR.input.personalZipCode + ']').value;
            recordData.personalCity = this.template.querySelector('[data-src=' + SELECTOR.input.personalCity + ']').value;
            recordData.personalCountry = this.template.querySelector('[data-src=' + SELECTOR.input.personalCountry + ']').value;
            recordData.jobRole = this.template.querySelector('[data-src=' + SELECTOR.input.jobRole + ']').value;
            recordData.vehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleLicense + ']').value;
            recordData.vehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleBrand + ']').value;
            recordData.vehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleModel + ']').value;
            recordData.secondVehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleLicense + ']').value;
            recordData.secondVehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleBrand + ']').value;
            recordData.secondVehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleModel + ']').value;
            recordData.privacyConsent = this.privacyConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;
            recordData.licenseReadingConsent = this.licenseReadingConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;
            recordData.marketingConsent = this.marketingConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;
            //Obtain Current Site Language and store it (ex: pt-PT)
            recordData.formLanguage = currentLanguage.replace('-', '_');

            let fileName;
            let fileData;

            let uploader = this.template.querySelector('[data-src=' + SELECTOR.input.fileUploader + ']');
            let uploadedFile = uploader.files.item(0);
            const fileReader = new FileReader();
            fileReader.onloadend = () => {
                fileName = uploadedFile.name;
                let result = fileReader.result;
                const base64 = 'base64,';
                const i = result.indexOf(base64) + base64.length;
                fileData = result.substring(i);

                this.updateCase(recordData, fileName, fileData);
            };

            fileReader.readAsDataURL(uploadedFile);
        } else {
            if (this.fieldValidated && !this.fileValidated) {
                this.showToast('error', this.label.formFileValidation);
            } else {
                this.showToast('error', this.label.formValidation);
            }
        }
    }

    /**
     * Validates current form input is valid for submission.
     *
     * @returns {boolean} Flagging if form information is valid for submission.
     */
    validateForm() {
        let personalFirstName = this.template.querySelector('[data-src=' + SELECTOR.input.personalFirstName + ']').validity;
        let personalLastName = this.template.querySelector('[data-src=' + SELECTOR.input.personalLastName + ']').validity;
        let personalVAT = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']').validity;
        let personalEmail = this.template.querySelector('[data-src=' + SELECTOR.input.personalEmail + ']').validity;
        let personalMobileCode = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneCode + ']').validity;
        let personalMobileNumber = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneNumber + ']').validity;
        let personalAddress = this.template.querySelector('[data-src=' + SELECTOR.input.personalAddress + ']').validity;
        let personalZipCode = this.template.querySelector('[data-src=' + SELECTOR.input.personalZipCode + ']').validity;
        let personalCity = this.template.querySelector('[data-src=' + SELECTOR.input.personalCity + ']').validity;
        let personalCountry = this.template.querySelector('[data-src=' + SELECTOR.input.personalCountry + ']').validity;
        let jobRole = this.template.querySelector('[data-src=' + SELECTOR.input.jobRole + ']').validity;
        let vehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleLicense + ']').validity;
        let vehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleBrand + ']').validity;
        let vehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleModel + ']').validity;
        let secondVehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleLicense + ']').validity;
        let secondVehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleBrand + ']').validity;
        let secondVehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleModel + ']').validity;
        let uploadedFile = this.template.querySelector('[data-src=' + SELECTOR.input.fileUploader + ']').files.item(0) === null ? false : true;

        this.fieldValidated =
            personalFirstName &&
            personalLastName &&
            personalVAT &&
            personalEmail &&
            personalMobileCode &&
            personalMobileNumber &&
            personalAddress &&
            personalZipCode &&
            personalCity &&
            personalCountry &&
            jobRole &&
            vehicleLicense &&
            vehicleBrand &&
            vehicleModel &&
            secondVehicleLicense &&
            secondVehicleBrand &&
            secondVehicleModel &&
            this.privacyConsentValue &&
            this.licenseReadingConsentValue;

        this.fileValidated = uploadedFile;

        let isValidForm = this.fieldValidated && this.fileValidated;

        return isValidForm;
    }

    /**
     * Validates if VAT Number fields on the form are valid. If they are invalid, input is set to show invalid vat error message.
     * Due to validation being done on controller (through imperative calls), async/await is used to ensure validation is finished before continuing logic.
     *
     * @returns {Promise<boolean>} True if vat numbers are valid, false otherwise.
     */
    async validateVATData() {
        const addressCountry = this.template.querySelector('[data-src=' + SELECTOR.input.personalCountry + ']').value;
        const vatNumberInput = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']');

        let validatioResult;

        //Call Controller to validate Billing VAT Number.
        await validateVAT({ vatToValidate: vatNumberInput.value, countryCode: addressCountry })
            .then((result) => {
                //Update Input to show error if validation returns false
                validatioResult = result;
                if (!validatioResult) {
                    vatNumberInput.setCustomValidity(this.label.invalidVatErrorMessage);
                }
            })
            .catch(() => {
                vatNumberInput.setCustomValidity(this.label.invalidVatErrorMessage);
                validatioResult = false;
            });

        return validatioResult;
    }

    /**
     * Call controller to update case with data provided.
     *
     * @param {object} recordData - Data from Form as a Case Object.
     * @param {string} fileName - Name of the uploaded file.
     * @param {string} fileData - Data of the uploaded file encoded into Base64.
     */
    updateCase(recordData, fileName, fileData) {
        this.isLoading = true;
        submitCase({ recordData: recordData, fileName: fileName, fileData: fileData })
            .then(() => {
                this.disabled = true;
                this.fillForm = false;
                this.formSubmitted = true;
                this.isLoading = false;
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handles the event when one of the input forms change.
     *
     * @param {Event} event - The event containing the changed input.
     */
    handleOnChange(event) {
        const source = event.target.dataset.src;

        switch (source) {
            case SELECTOR.input.privacyConsent:
                this.privacyConsentValue = event.detail.checked;
                break;
            case SELECTOR.input.licenseReadingConsent:
                this.licenseReadingConsentValue = event.detail.checked;
                break;
            case SELECTOR.input.marketingConsent:
                this.marketingConsentValue = event.detail.checked;
                break;
            case SELECTOR.input.personalVAT: {
                //Clear invalid VAT error message on change (is validated before submiting)
                event.target.setCustomValidity('');
                break;
            }
            case SELECTOR.input.personalCountry: {
                //Clear invalid VAT error message on change (is validated before submiting)
                this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']').setCustomValidity('');
                break;
            }
            default:
                break;
        }
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
}