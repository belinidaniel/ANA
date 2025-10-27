/**
 * @file Class that manages comm_individuaStaffRegistration functionalities.
 */
import { patterns, validations } from 'c/constants';
import { individualStaffRegistration, global, input } from 'c/i18n';
import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import submitCase from '@salesforce/apex/COMM_LCC_IndividualStaffRegistration.submitCase';
import getCountryPicklistValues from '@salesforce/apex/COMM_LCC_IndividualStaffRegistration.getCountryPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import { CurrentPageReference } from 'lightning/navigation';
import verifyPendingCases from '@salesforce/apex/COMM_LCC_IndividualStaffRegistration.verifyPendingCases';
import validateVAT from '@salesforce/apex/COMM_LCC_IndividualStaffRegistration.validateVAT';
import getUserInfo from '@salesforce/apex/COMM_LCC_IndividualStaffRegistration.getUserInfo';
import userId from '@salesforce/user/Id';

// Constants
const ACCOUNT_MANAGEMENT_PAGE_NAME = 'Account_Management__c';
const FILE_JPEG = 'image/jpeg';
const FILE_PDF = 'application/pdf';

const CONSENT_VALUE_CHECKED = 'Yes';
const CONSENT_VALUE_UNCHECKED = 'No';

const SELECTOR = {
    input: {
        personalFirstName: 'personal-first-name',
        personalLastName: 'personal-last-name',
        personalVAT: 'personal-vat-number',
        personalEmail: 'personal-email-address',
        personalPhoneCode: 'personal-phone-code',
        personalPhoneNumber: 'personal-phone-number',
        personalAddress: 'personal-address-street',
        personalZipCode: 'personal-address-zipcode',
        personalCity: 'personal-address-city',
        personalCountry: 'personal-address-country',
        jobRole: 'job-role',
        fileUploader: 'file-uploader',
        vehicleLicense: 'vehicle-license',
        vehicleBrand: 'vehicle-brand',
        vehicleModel: 'vehicle-model',
        secondVehicleLicense: 'second-vehicle-license',
        secondVehicleBrand: 'second-vehicle-brand',
        secondVehicleModel: 'second-vehicle-model',
        privacyConsent: 'privacy-consent',
        licenseReadingConsent: 'license-reading-consent',
        marketingConsent: 'marketing-consent'
    }
};

export default class Comm_individualStaffRegistration extends NavigationMixin(LightningElement) {
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
        personalDataTitle: individualStaffRegistration.PERSONAL_DATA_TITLE,
        billingDataFirstName: individualStaffRegistration.BILLING_DATA_FIRST_NAME,
        billingDataLastName: individualStaffRegistration.BILLING_DATA_LAST_NAME,
        billingDataNif: individualStaffRegistration.BILLING_DATA_NIF,
        personalDataEmail: individualStaffRegistration.PERSONAL_DATA_EMAIL,
        personalDataCode: individualStaffRegistration.PERSONAL_DATA_CODE,
        personalDataMobile: individualStaffRegistration.PERSONAL_DATA_MOBILE,
        billingDataAddress: individualStaffRegistration.BILLING_DATA_ADDRESS,
        billingDataPostalCode: individualStaffRegistration.BILLING_DATA_POSTAL_CODE,
        billingDataCity: individualStaffRegistration.BILLING_DATA_CITY,
        billingDataCountry: individualStaffRegistration.BILLING_DATA_COUNTRY,
        carTitle: individualStaffRegistration.CAR_TITLE,
        carOne: individualStaffRegistration.CAR_ONE,
        carPlate: individualStaffRegistration.CAR_PLATE,
        carBrand: individualStaffRegistration.CAR_BRAND,
        carModel: individualStaffRegistration.CAR_MODEL,
        carTwo: individualStaffRegistration.CAR_TWO,
        carTerms: individualStaffRegistration.CAR_TERMS,
        carStaffTitle: individualStaffRegistration.CAR_STAFF_TITLE,
        carStaffWorkFunction: individualStaffRegistration.CAR_STAFF_WORK_FUNCTION,
        carStaffInfo1: individualStaffRegistration.CAR_STAFF_INFO1,
        carStaffInfo2: individualStaffRegistration.CAR_STAFF_INFO2,
        carStaffFirstTerms: individualStaffRegistration.CAR_STAFF_FIRST_TERMS,
        carStaffSecondTerms: individualStaffRegistration.CAR_STAFF_SECOND_TERMS,
        carStaffInfoThirdTerms: individualStaffRegistration.CAR_STAFF_THIRD_TERMS,
        staffSubmitButton: individualStaffRegistration.STAFF_SUBMIT_BUTTON,
        staffSubmitSentSuccess: individualStaffRegistration.STAFF_SUBMIT_MESSAGE_SUCCESS,
        staffSubmitResponseSoon: individualStaffRegistration.STAFF_SUBMIT_MESSAGE_RESPONSE,
        staffSubmitThankYou: individualStaffRegistration.STAFF_SUBMIT_MESSAGE_THANKS,
        staffSubmitReturnButton: individualStaffRegistration.STAFF_SUBMIT_RETURN_BUTTON,
        mainTitle: individualStaffRegistration.PERSONAL_DATA_MAIN_TITLE,
        invalidVatErrorMessage: individualStaffRegistration.INVALID_VAT_ERROR,
        successTitle: global.TOAST_MESSAGE_TITLE,
        successMessage: global.TOAST_MESSAGE_MESSAGE,
        errorToastTitle: global.TOAST_MESSAGE_ERROR_TITLE,
        toastPosition: global.TOAST_MESSAGE_POSITION_VARIANT,
        phoneCodeErrorMessage: input.PHONE_CODE_ERROR_MESSAGE,
        nameErrorMessage: input.NAME_ERROR_MESSAGE,
        requestInApproval: individualStaffRegistration.REQUEST_IN_APPROVAL,
        requestAlreadyExists: individualStaffRegistration.REQUEST_ALREADY_EXISTS,
        vatErrorMessage: input.VAT_ERROR_MESSAGE
    };

    @track userData = {};
    bindedUserId = null;

    fillForm = false;
    formSubmitted = false;

    fileUploaded = false;
    fileName = '';

    privacyConsentValue = false;
    licenseReadingConsentValue = false;
    marketingConsentValue = false;

    currentPageReference = null;
    showToastMessage = false;

    isDisabled = true;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if ('result' in currentPageReference.state && currentPageReference.state.result === 'success') {
            this.showToastMessage = true;
        }
    }

    @wire(getUserInfo, { userId: '$bindedUserId' })
    wiredUser({ error, data }) {
        if (data) {
            this.userData = JSON.parse(JSON.stringify(data));
            if (this.userData.Contact.Account.PersonMobilePhone) {
                this.userData.phoneCode = data.Contact.Account.PersonMobilePhone.split(' ')[0];
                this.userData.phone = data.Contact.Account.PersonMobilePhone.split(' ')[1];
            }
            
            
            this.error = undefined;
        } else if (error) {
            console.log(error);
            this.user = undefined;
        }
    }

    get fileUploaderText() {
        return this.fileUploaded ? this.fileName : this.label.carStaffInfo2;
    }

    get fileIconClass() {
        return this.fileUploaded ? 'comm-icon__cross' : 'comm-icon__upload';
    }

    countryOptions;
    isLoading = true;
    hasPendingCase = false;

    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxShown = 1;
        toastContainer.toastPosition = this.label.toastPosition;

        // Call Controller Method to obtain Picklist Valus for Country Input Selects.
        getCountryPicklistValues()
            .then((result) => {
                this.countryOptions = Object.entries(result).map(([value, label]) => ({ value, label }));
            })
            .catch((error) => {
                console.log(error);
            });

        //Call Controller Method to verify if user has a pending case.
        verifyPendingCases()
            .then((result) => {
                //Hide Form if User has Pending Case
                this.fillForm = !result;
                this.hasPendingCase = result;
            })
            .catch(() => {
                this.fillForm = true;
                this.hasPendingCase = false;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    renderedCallback() { 
        this.bindedUserId = userId;
    }

    /**
     * Enables the upload of a file.
     */
    handleUploaderClick() {
        this.template.querySelector('#file-input').click();
    }

    handleFileChange(event) {
        let uploader = event.target;
        let fileList = uploader.files;

        if (fileList.length) {
            let fileType = uploader.files.item(0).type;
            if (fileType === FILE_JPEG || fileType === FILE_PDF) {
                this.fileUploaded = true;
                this.fileName = uploader.files.item(0).name;
            } else {
                uploader.value = null;
                this.fileUploaded = false;
            }
        } else {
            this.fileUploaded = false;
        }
        this.isDisabled = !this.validateForm();
    }

    /**
     * Handles the event when one of the inputs change.
     *
     * @param {Event} event - The event containing the changed input.
     */
    handleInputChange(event) {
        const source = event.target.dataset.src;
        switch (source) {
            case SELECTOR.input.personalVAT: {
                //Clear invalid VAT error message on change (is validated before submiting)
                event.target.setCustomValidity('');
                break;
            }
            case SELECTOR.input.personalCountry: {
                const vatNumberInput = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']');
                //Clear invalid VAT error message on change (is validated before submiting)
                vatNumberInput.setCustomValidity('');
                break;
            }
            default:
                break;
        }
        this.isDisabled = !this.validateForm();
    }

    /**
     * Handles the event when one of the checkboxes change.
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
            default:
                break;
        }
        this.isDisabled = !this.validateForm();
    }

    /**
     * Handler for when User presses the Submit Button. Retrieves form data and sends it to controller to create Case if valid.
     *
     * @param {Event} event - The event to prevent page refresh.
     */
    async handleClick(event) {
        event.preventDefault();
        this.isLoading = true;
        window.scrollTo({ top: 0, behavior: 'smooth' });

        if (this.validateForm() && (await this.validateVATData())) {
            let caseData = {};

            //Retrieve Case Data From Form
            caseData.COMM_FirstName__c = this.template.querySelector('[data-src=' + SELECTOR.input.personalFirstName + ']').value;
            caseData.COMM_LastName__c = this.template.querySelector('[data-src=' + SELECTOR.input.personalLastName + ']').value;
            caseData.COMM_VATNumber__c = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']').value;
            caseData.SuppliedEmail = this.template.querySelector('[data-src=' + SELECTOR.input.personalEmail + ']').value;
            caseData.COMM_PhoneNumber__c =
                this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneCode + ']').value +
                ' ' +
                this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneNumber + ']').value;
            caseData.COMM_Address__Street__s = this.template.querySelector('[data-src=' + SELECTOR.input.personalAddress + ']').value;
            caseData.COMM_Address__PostalCode__s = this.template.querySelector('[data-src=' + SELECTOR.input.personalZipCode + ']').value;
            caseData.COMM_Address__City__s = this.template.querySelector('[data-src=' + SELECTOR.input.personalCity + ']').value;
            caseData.COMM_Address__CountryCode__s = this.template.querySelector('[data-src=' + SELECTOR.input.personalCountry + ']').value;

            //Retrieve Job, Vehicle Data and Consent
            caseData.COMM_JobRole__c = this.template.querySelector('[data-src=' + SELECTOR.input.jobRole + ']').value;

            caseData.COMM_LicensePlate__c = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleLicense + ']').value;
            caseData.COMM_VehicleBrand__c = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleBrand + ']').value;
            caseData.COMM_VehicleModel__c = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleModel + ']').value;
            caseData.COMM_SecondaryLicensePlate__c = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleLicense + ']').value;
            caseData.COMM_SecondaryVehicleBrand__c = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleBrand + ']').value;
            caseData.COMM_SecondaryVehicleModel__c = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleModel + ']').value;

            //Convert Checkbox values to values stored on back-end (True = Yes, False = No)
            caseData.COMM_PrivacyPolicyConsent__c = this.privacyConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;
            caseData.COMM_LicensePlateReadingConsent__c = this.licenseReadingConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;
            caseData.COMM_ConsentUseofDataforMarketing__c = this.marketingConsentValue ? CONSENT_VALUE_CHECKED : CONSENT_VALUE_UNCHECKED;

            let fileName;
            let fileData;

            //Load uploaded file
            let uploader = this.template.querySelector('[data-src=' + SELECTOR.input.fileUploader + ']');
            let uploadedFile = uploader.files.item(0);
            const fileReader = new FileReader();
            fileReader.onloadend = () => {
                fileName = uploadedFile.name;
                let result = fileReader.result;
                const base64 = 'base64,';
                const i = result.indexOf(base64) + base64.length;
                fileData = result.substring(i);

                //Call method to send prepared data to back-end.
                this.createCase(caseData, fileName, fileData);
            };
            fileReader.readAsDataURL(uploadedFile);
        } else {
            this.isLoading = false;
        }
    }

    /**
     * Validates current form input is valid for submission.
     *
     * @returns {boolean} True if form data is valid. False otherwise.
     */
    validateForm() {
        const firstName = this.template.querySelector('[data-src=' + SELECTOR.input.personalFirstName + ']').validity;
        const lastName = this.template.querySelector('[data-src=' + SELECTOR.input.personalLastName + ']').validity;
        const vatNumber = this.template.querySelector('[data-src=' + SELECTOR.input.personalVAT + ']').validity;
        const email = this.template.querySelector('[data-src=' + SELECTOR.input.personalEmail + ']').validity;
        const addressStreet = this.template.querySelector('[data-src=' + SELECTOR.input.personalAddress + ']').validity;
        const addressPostal = this.template.querySelector('[data-src=' + SELECTOR.input.personalZipCode + ']').validity;
        const addressCity = this.template.querySelector('[data-src=' + SELECTOR.input.personalCity + ']').validity;
        const addressCountry = this.template.querySelector('[data-src=' + SELECTOR.input.personalCountry + ']').value;

        const mobileCode = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneCode + ']').validity;
        const mobileNumber = this.template.querySelector('[data-src=' + SELECTOR.input.personalPhoneNumber + ']').validity;

        const jobRole = this.template.querySelector('[data-src=' + SELECTOR.input.jobRole + ']').validity;

        //File Validation. Passes if a File is uploaded and it's a JPEG or PDF.
        let fileUploader = this.template.querySelector('[data-src=' + SELECTOR.input.fileUploader + ']');
        const uploadValidation =
            fileUploader.files.length && (fileUploader.files.item(0).type === FILE_JPEG || fileUploader.files.item(0).type === FILE_PDF);

        const vehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleLicense + ']').validity;
        const vehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleBrand + ']').validity;
        const vehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.vehicleModel + ']').validity;
        const secondVehicleLicense = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleLicense + ']').validity;
        const secondVehicleBrand = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleBrand + ']').validity;
        const secondVehicleModel = this.template.querySelector('[data-src=' + SELECTOR.input.secondVehicleModel + ']').validity;

        const validationResult =
            firstName &&
            lastName &&
            vatNumber &&
            email &&
            addressStreet &&
            addressPostal &&
            addressCity &&
            addressCountry &&
            mobileCode &&
            mobileNumber &&
            jobRole &&
            uploadValidation &&
            vehicleLicense &&
            vehicleBrand &&
            vehicleModel &&
            secondVehicleLicense &&
            secondVehicleBrand &&
            secondVehicleModel &&
            this.privacyConsentValue &&
            this.licenseReadingConsentValue;

        return validationResult;
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
     * Call controller to create case with data provided.
     *
     * @param {object} caseData - Data from Form as a Case SObject.
     * @param {string} fileName - Name of the uploade file.
     * @param {string} fileData - Data of the uploaded file encoded into Base64.
     */
    createCase(caseData, fileName, fileData) {
        submitCase({ caseRecord: caseData, fileName: fileName, fileData: fileData })
            .then(() => {
                this.fillForm = false;
                this.formSubmitted = true;
            })
            .catch(() => {
                this.showToast('error', this.label.errorToastTitle);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handler for when User presses the button to navigate back to Account Management Page.
     */
    handleReturn() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: ACCOUNT_MANAGEMENT_PAGE_NAME
            }
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
}