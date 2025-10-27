/**
 * @file File that manages comm__register functionalities.
 */
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { global, register, input } from 'c/i18n';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import isGuest from '@salesforce/user/isGuest';
import basePath from '@salesforce/community/basePath';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
import registerUser from '@salesforce/apex/COMM_SL_SelfRegisterHandler.registerUser';
import validateEmailExpiration from '@salesforce/apex/COMM_SL_RegistrationEmailExpiration.validateEmailExpiration';
import { patterns, validations } from 'c/constants';

const CMS_IMAGE = 'cms_image';

export default class Comm_register extends NavigationMixin(LightningElement) {
    @api pageIllustration;

    pageIllustrationUrl;
    pageIllustrationTitle;

    hasRendered = false;
    isCredentialsRegister = false;
    isEmailValidation = false;
    isAccountCreated = false;
    isAccountCreatedFailed = false;
    isPasswordValid = false;
    renderedFinished = false;
    isEnterKeyListenerAdded = false;

    errorFeedback;

    firstName;
    lastName;
    email;
    password;
    passwordConfirmation;

    contentKeys = [];

    pattern = {
        name: patterns.NAME
    };

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    validation = {
        personalFirstNameCharLimit: validations.PERSONAL_FIRSTNAME_CHAR_LIMIT,
        personalLastNameCharLimit: validations.PERSONAL_LASTNAME_CHAR_LIMIT
    };

    label = {
        or: global.OR,
        login: global.LOGIN,
        email: global.EMAIL,
        title: register.TITLE,
        register: global.REGISTER,
        newHere: register.NEW_HERE,
        lastName: global.LAST_NAME,
        subtitle: register.SUBTITLE,
        firstName: global.FIRST_NAME,
        goToLogin: register.GO_TO_LOGIN,
        viewOrders: register.VIEW_ORDERS,
        orderNumber: global.ORDER_NUMBER,
        registerWith: register.REGISTER_WITH,
        createAccount: register.CREATE_ACCOUNT,
        accountCreated: register.ACCOUNT_CREATED,
        emailValidation: register.EMAIL_VALIDATION,
        subscriptionAccess: register.SUBSCRIPTION_ACCESS,
        alreadyHaveAccount: register.ALREADY_HAVE_ACCOUNT,
        accountCreatedDescription: register.ACCOUNT_CREATED_DESCRIPTION,
        emailValidationDescription1: register.EMAIL_VALIDATION_DESCRIPTION_1,
        emailValidationDescription2: register.EMAIL_VALIDATION_DESCRIPTION_2,
        ValidationFailed: register.VALIDATION_FAILED,
        RegistrationFailed: register.REGISTRATION_FAILED,
        password: register.REGISTER_PASSWORD,
        confirmPassword: register.REGISTER_CONFIRM_PASSWORD,
        phoneCodeErrorMessage: input.PHONE_CODE_ERROR_MESSAGE,
        nameErrorMessage: input.NAME_ERROR_MESSAGE
    };

    currentPageReference = null;
    showToastMessage = false;
    isLoading = false;
    startUrl = '';
    goToCheckout = false;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if ('result' in currentPageReference.state && currentPageReference.state.result === 'success') {
            this.showToastMessage = true;
        }
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId || null;
            let states = currentPageReference.state;
            this.startUrl = states.startURL;
            this.goToCheckout = states?.target === 'checkout';
        }
    }

    //Return True if Redirection is Required (User is Authenticated and Site isn't in Preview Mode)
    get redirectionRequired() {
        return !isGuest && !this.isInSitePreview();
    }

    connectedCallback() {
        if (this.redirectionRequired) {
            this.navigateToHome();
        } else {
            const toastContainer = ToastContainer.instance();
            toastContainer.maxShown = 1;
            toastContainer.toastPosition = 'top-center';
            if (this.pageIllustration) {
                this.contentKeys.push(this.pageIllustration);
            }
            if (!window.location.href.includes('dXNlcklk')) {
                this.renderedFinished = true;
                this.isCredentialsRegister = true;
                return;
            }
            validateEmailExpiration({ pageReference: window.location.href })
                .then(() => {
                    this.isAccountCreated = true;
                })
                .catch(() => {
                    this.isAccountCreatedFailed = true;
                })
                .finally(() => {
                    this.renderedFinished = true;
                });
        }
    }

    renderedCallback() {
        if (this.showToastMessage) {
            this.showNotification();
            this.showToastMessage = false;
        }
        if (!this.hasRendered) {
            this.reveal();
            this.hasRendered = true;
        }
        if (!this.isEnterKeyListenerAdded) {
            this.template.addEventListener('keydown', this.handleEnterKeyPress);
            this.isEnterKeyListenerAdded = true;
        }
    }

    /**
     * Add event listener for Enter key.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleEnterKeyPress = (event) => {
        if (event.key === 'Enter') {
            const submitButton = this.template.querySelector('.comm-registration-submit');
            if (!submitButton.disabled) {
                this.handleRegistration(event);
            }
        }
    };

    /**
     * Adds display animation for the forms.
     */
    reveal() {
        const form = this.template.querySelector('form');

        if (form) {
            form.animate([{ opacity: 0 }, { opacity: 1 }], 1000);
        }
    }

    /**
     * Toggles forms visibility.
     */
    toggleRegisterForm() {
        this.isCredentialsRegister = !this.isCredentialsRegister;
        this.hasRendered = false;
    }

    /**
     * Handles the information from comm_passwordValidator.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleValidation(event) {
        const eventValue = event.detail.value;
        if (eventValue) {
            this.isPasswordValid = true;
        } else {
            this.isPasswordValid = false;
        }

        this.enableSubmitButton();
    }

    /**
     * Handles password change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleFirstNameChange(event) {
        this.firstName = event.detail.value;
        this.enableSubmitButton();
    }

    /**
     * Handles password change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleLastNameChange(event) {
        this.lastName = event.detail.value;
        this.enableSubmitButton();
    }

    /**
     * Handles password change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleEmailChange(event) {
        this.email = event.detail.value;
        this.enableSubmitButton();
    }

    /**
     * Handles password change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handlePasswordChange(event) {
        this.password = event.detail.value;
        this.enableSubmitButton();
    }

    /**
     * Handles password confirmation change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handlePasswordConfirmationChange(event) {
        this.passwordConfirmation = event.detail.value;
        this.enableSubmitButton();
    }

    /**
     * Enables and disables the button.
     */
    enableSubmitButton() {
        if (this.firstName && this.lastName && this.email && this.password && this.passwordConfirmation && this.isPasswordValid) {
            this.template.querySelector('.comm-registration-submit').disabled = false;
        } else {
            this.template.querySelector('.comm-registration-submit').disabled = true;
        }
    }

    /**
     * Sends inputs to class.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleRegistration(event) {
        event.preventDefault();
        const inputs = this.template.querySelectorAll('c-comm_input');
        let isValid = true;

        inputs.forEach((inputRegistration) => {
            if (!inputRegistration.reportValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            return;
        }

        if (!this.isPasswordValid || !this.firstName || !this.lastName || !this.email || !this.password || !this.passwordConfirmation) {
            this.showToast('error', this.label.RegistrationFailed);
            return;
        }

        this.isFormError = false;
        this.isLoading = true;

        // Send attributes to registerUser method of class COMM_SL_SelfRegisterHandler
        registerUser({
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            password: this.password,
            siteLanguage: this.data.language,
            redirectUrl: this.startUrl,
            goToCheckout: this.goToCheckout
        })
            .then(() => {
                this.isCredentialsRegister = false;
                this.isEmailValidation = true;
            })
            .catch(() => {
                this.showToast('error', this.label.RegistrationFailed);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Navigates to Login page.
     */
    navigateToLogin() {
        this.isLoading = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Login'
            },
            state: {
                startURL: this.startUrl
            }
        });
    }

    @wire(getContentByContentKeys, {
        data: '$data',
        contentKeys: '$contentKeys'
    })

    /**
     * Handles the request from the wire service.
     *
     * @param {object} object - Object with the data received from request.
     */
    wiredGetContentImages({ data }) {
        if (data) {
            const cms = new Cms(data);
            const resource = cms.getImageByContentKey(this.pageIllustration);

            this.pageIllustrationUrl = resource.url;
            this.pageIllustrationTitle = resource.title;
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

    /**
     * Navigates to Home.
     */
    navigateToHome() {
        const siteUrl = basePath.replace('/login', '');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: siteUrl
            }
        });
    }

    /**
     * Verify if Component is running under Experience Builder or site preview context.
     *
     * @returns {boolean} True if running in Experience Builder, False otherwise.
     */
    isInSitePreview() {
        let url = document.URL;

        return (
            url.indexOf('sitepreview') > 0 ||
            url.indexOf('livepreview') > 0 ||
            url.indexOf('live-preview') > 0 ||
            url.indexOf('live.') > 0 ||
            url.indexOf('.builder.') > 0 ||
            url.indexOf('.preview.') > 0
        );
    }
}