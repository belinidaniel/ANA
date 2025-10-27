/**
 * @file File that manages comm__forgotPassword functionalities.
 */
import { forgotPassword } from 'c/i18n';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { tokens } from 'c/constants';

import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';

import resetPassword from '@salesforce/apex/COMM_LCC_Login.resetPassword';
import changePassword from '@salesforce/apex/COMM_LCC_Login.changePassword';
import validateResetToken from '@salesforce/apex/COMM_LCC_Login.validateResetToken';
import { getCriptoKeyFromData, encryptMessage } from 'c/cryptoUtils';
import getResetKey from '@salesforce/apex/COMM_LCC_Login.getResetKey';

const CMS_IMAGE = 'cms_image';

export default class Comm_forgotPassword extends NavigationMixin(LightningElement) {
    @api pageIllustration;

    pageIllustrationUrl;
    pageIllustrationTitle;

    hasRendered = false;
    isFormError = false;

    isEmailInput = true;
    isEmailSent = false;
    isPasswordReset = false;
    isPasswordDefined = false;

    userId;
    userEmail;
    userFirstName;
    userLastName;
    emailInput = '';
    errorMessage;
    isChangePassword = false;

    password;
    passwordConfirmation;

    contentKeys = [];

    token = {
        forgotPassToken: tokens.USER_ENCONDED_TOKEN,
        changePassToken: tokens.CHANGE_PASS_ENCONDED_TOKEN
    };

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    label = {
        reset: forgotPassword.RESET,
        confirm: forgotPassword.CONFIRM,
        success: forgotPassword.SUCCESS,
        goToLogin: forgotPassword.GO_TO_LOGIN,
        emailSent: forgotPassword.EMAIL_SENT,
        emailInput: forgotPassword.EMAIL_INPUT,
        emailVerify: forgotPassword.EMAIL_VERIFY,
        newPassword: forgotPassword.NEW_PASSWORD,
        buttonRecover: forgotPassword.BUTTON_RECOVER,
        recoverPassword: forgotPassword.RECOVER_PASSWORD,
        changePassword: forgotPassword.CHANGE_PASSWORD,
        confirmationChange: forgotPassword.CONFIRMATION_CHANGE
    };

    isLoading = true;
    finishInitialLoad = false;

    connectedCallback() {
        if (this.pageIllustration) {
            this.contentKeys.push(this.pageIllustration);
        }
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.reveal();
            this.hasRendered = true;
        }
    }

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
     * Return Title shown to User.
     * Title depends if context is for Forgot Password or Change Password.
     *
     * @returns {string} Title to show to User.
     */
    get titleText() {
        return this.isChangePassword ? this.label.changePassword : this.label.recoverPassword;
    }

    /**
     * Handles password change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handlePasswordChange(event) {
        this.password = event.detail.value;
    }

    /**
     * Handles password confirmation change getting its value.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handlePasswordConfirmationChange(event) {
        this.passwordConfirmation = event.detail.value;
    }

    /**
     * Navigates to Login page.
     */
    navigateToLogin() {
        this[NavigationMixin.Navigate](
            {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Login'
                },
                state: {
                    startURL: this.startUrl
                }
            },
            true
        );
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
    wiredGetContentImages({ data, error }) {
        if (data) {
            const cms = new Cms(data);
            const resource = cms.getImageByContentKey(this.pageIllustration);

            this.pageIllustrationUrl = resource.url;
            this.pageIllustrationTitle = resource.title;
        } else if (error) {
            console.log(error);
        }
    }

    startUrl = '';

    @wire(CurrentPageReference)
    /**
     * Handles the request from the wire service. Verifies Page Parameters and if it exist retrieve token.
     *
     * @param {object} currentPageReference - Object with the data received from request.
     */
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            //Retrieve Tokens from URL
            this.startUrl = currentPageReference.state?.startURL;
            this.isChangePassword = currentPageReference.state && currentPageReference.state[this.token.changePassToken];
            const urlToken = this.isChangePassword
                ? currentPageReference.state[this.token.changePassToken]
                : currentPageReference.state[this.token.forgotPassToken];
            //If Token Provided check if it's Valid
            if (urlToken) {
                validateResetToken({ token: urlToken })
                    .then((result) => {
                        this.userId = result[0];
                        this.userEmail = result[1];
                        this.userFirstName = result[2];
                        this.userLastName = result[3];
                        this.isEmailInput = false;
                        this.isPasswordReset = true;

                        //Ask Key from Server
                        getResetKey().then((resultKey) => {
                            this.obtainKey(resultKey);
                        });
                    })
                    .catch((error) => {
                        this.isFormError = true;
                        this.errorMessage = error.body.message;
                    })
                    .finally(() => {
                        //Set Loading as finished once token is validated
                        this.finishInitialLoad = true;
                        this.isLoading = false;
                    });
            } else {
                //Set Loading as finished if there is no token to be valid
                this.finishInitialLoad = true;
                this.isLoading = false;
            }
        } else {
            //Set Loading as finished if no Page Refence exist
            this.finishInitialLoad = true;
            this.isLoading = false;
        }
    }

    secretKey;

    /**
     * Method to convert key data from server into a Crypto AES Key to encrypt data.
     *
     * @param {*} data Key data to convert into a Crypto AES Key.
     */
    async obtainKey(data) {
        this.secretKey = await getCriptoKeyFromData(data);
    }

    // Get current state parameters.
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.startUrl = currentPageReference.state?.startURL;
        }
    }

    /**
     * Handles the password validation change.
     * Set's the submit button as enabled/disabled depending if password passes all rules.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handlePassValidation(event) {
        let validation = event.detail.value;
        let passButton = this.template.querySelector("[data-name='submit_pass']");
        passButton.disabled = !validation;
    }

    /**
     * Handles the Forgot Password Process.
     * Calls controller method to initiate Forgot Password logic.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleOnClickResetPassword(event) {
        event.preventDefault();

        const emailComponent = this.template.querySelector("[data-id='email-input']");
        const emailValid = emailComponent.reportValidity();
        if (!emailValid) {
            return;
        }
        this.emailInput = emailComponent.value;

        this.isLoading = true;
        resetPassword({ email: this.emailInput, startUrl: this.startUrl })
            .then(() => {
                this.isEmailInput = false;
                this.isEmailSent = true;
                this.isFormError = false;
            })
            .catch(() => {
                this.isEmailInput = false;
                this.isEmailSent = true;
                this.isFormError = false;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handles the Set Password Process.
     * Calls controller method to change User Password.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    async handleOnClickChangePassword(event) {
        event.preventDefault();
        const dataMessage = await encryptMessage(
            JSON.stringify({
                userId: this.userId,
                password: this.password,
                timestamp: new Date().toJSON()
            }),
            this.secretKey
        );

        if (this.password === this.passwordConfirmation) {
            changePassword({ payload: dataMessage })
                .then(() => {
                    this.isPasswordReset = false;
                    this.isPasswordDefined = true;
                    this.isFormError = false;
                })
                .catch((error) => {
                    this.isFormError = true;
                    this.errorMessage = error.body.message;
                });
        }
    }
}