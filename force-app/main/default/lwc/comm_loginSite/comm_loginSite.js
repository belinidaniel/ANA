/**
 * @file File that manages comm__login functionalities.
 */
import { login, global } from 'c/i18n';
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import currentLanguage from '@salesforce/i18n/lang';
import { changeLanguage } from 'c/languageUtils';
import { getLanguageCode } from 'c/languageUtils';

import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import siteLogin from '@salesforce/apex/COMM_LCC_Login.siteLogin';
import siteInfo from '@salesforce/apex/COMM_LCC_Site.getExperienceId';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
import getLoginKey from '@salesforce/apex/COMM_LCC_Login.getLoginKey';

import { getCriptoKeyFromData, encryptMessage } from 'c/cryptoUtils';

const CMS_IMAGE = 'cms_image';
const SUBSCRIPTION_TYPE = 'Subscription Portal';

export default class Comm_loginSite extends NavigationMixin(LightningElement) {
    @api siteType;
    @api subscriptionLink;
    @api pageIllustration;
    @api buttonLink;
    @api subscriptionPageLink;

    get isSubscription() {
        return this.siteType === SUBSCRIPTION_TYPE;
    }

    pageIllustrationUrl;
    pageIllustrationTitle;
    siteExperience = null;

    hasRendered = false;
    isFormError = false;
    isCredentialsLogin = false;
    isReservationLogin = false;
    isEnterKeyListenerAdded = false;

    contentKeys = [];

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    label = {
        or: global.OR,
        title: login.TITLE,
        email: global.EMAIL,
        login: global.LOGIN,
        region: global.REGION,
        backTo: login.BACK_TO,
        newHere: login.NEW_HERE,
        subtitle: login.SUBTITLE,
        password: global.PASSWORD,
        loginWith: login.LOGIN_WITH,
        postalCode: global.POSTAL_CODE,
        orderNumber: global.ORDER_NUMBER,
        createAccount: login.CREATE_ACCOUNT,
        errorFeedback: login.ERROR_FEEDBACK,
        forgotPassword: login.FORGOT_PASSWORD,
        withReservation: login.WITH_RESERVATION,
        withCredentials: login.WITH_CREDENTIALS,
        subscriptionAccess: login.SUBSCRIPTION_ACCESS
    };

    startUrl = '';
    isLoading = false;

    // Get current state parameters.
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.startUrl = currentPageReference.state?.startURL;
        }
    }

    /**
     * Returns URL used to call Google SSO Login Service.
     * Start URL is provided so User is redirected to calling service (ex: Commerce) at the end.
     *
     * @returns {string} Url for Google SSO service.
     */
    get googleService() {
        return '/services/auth/sso/Google' + (this.startUrl ? '?startURL=' + this.startUrl : '');
    }

    /**
     * Returns URL used to call Facebook SSO Login Service.
     * Start URL is provided so User is redirected to calling service (ex: Commerce) at the end.
     *
     * @returns {string} Url for Facebook SSO service.
     */
    get facebookService() {
        return '/services/auth/sso/Facebook' + (this.startUrl ? '?startURL=' + this.startUrl : '');
    }

    /**
     * Returns URL for Subscription Portal.
     *
     * @returns {string} Url for the subscriptions portal with language parameter.
     */
    get subscriptionUrl() {
        const subscriptionLink = this.subscriptionPageLink ? this.subscriptionPageLink + '/s/login/?language=' : '/subscriptions/s/login/?language=';
        return subscriptionLink + currentLanguage.replace('-', '_');
    }

    secretKey;
    initCrypto = false;

    connectedCallback() {
        this.isCredentialsLogin = !this.isSubscription;
        if (this.pageIllustration) {
            this.contentKeys.push(this.pageIllustration);
        }
        //Ask Key from Server
        getLoginKey().then((result) => {
            this.obtainKey(result);
        });
    }

    /**
     * Method to convert key data from server into a Crypto AES Key to encrypt data.
     *
     * @param {*} data Key data to convert into a Crypto AES Key.
     */
    async obtainKey(data) {
        this.secretKey = await getCriptoKeyFromData(data);
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.getLanguageFromCommerce();
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
            if (this.isCredentialsLogin) {
                this.handleOnClickLogin();
            } else if (this.isReservationLogin) {
                event.target.dataset.href = this.buttonLink;
                this.navigateToMyOrders(event);
            }
        }
    };

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
    toggleLoginForm() {
        this.isFormError = false;
        this.isCredentialsLogin = !this.isCredentialsLogin;
        this.isReservationLogin = !this.isSubscription && !this.isCredentialsLogin;
        this.hasRendered = false;
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

    /**
     * Validate user credentials and sign in into the portal.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    async handleOnClickLogin(event) {
        event.preventDefault();
        const emailInput = this.template.querySelector("[data-name='email']");
        const passwordInput = this.template.querySelector("[data-name='password']");

        const email = emailInput.value;
        const password = passwordInput.value;

        // Validates if the email and password input has values
        if (!email || !password) {
            emailInput.reportValidity();
            passwordInput.reportValidity();
            return;
        }

        this.isLoading = true;

        //Verify if Login is being called in Commerce Context. If it is then login normally with selected language.
        //Redirect will recall login service after login to ensure login is performed with selected language.
        if (!this.startUrl || this.startUrl?.includes('/setup/secur/RemoteAccessAuthorizationPage')) {
            const siteCurrentLanguage = new URLSearchParams(window.location.search)?.get('language');
            this.startUrl = window.location.pathname?.replace('login/', '') + '?language=' + siteCurrentLanguage;
        }

        const dataMessage = await encryptMessage(
            JSON.stringify({
                email: email,
                password: password,
                timestamp: new Date().toJSON()
            }),
            this.secretKey
        );
        siteLogin({
            startUrl: this.startUrl,
            payload: dataMessage
        })
            .then((data) => {
                if (data) {
                    window.location.href = data;
                } else {
                    this.isFormError = true;
                }
            })
            .catch(() => {
                this.isFormError = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Navigates to Register page.
     * Passes Start URL so it isn't lost during registration process.
     */
    navigateToRegister() {
        this.isLoading = true;
        //Named Page is used to ensure startURL parameter is passed
        this[NavigationMixin.Navigate](
            {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Register'
                },
                state: {
                    startURL: this.startUrl
                }
            },
            true
        );
    }

    /**
     * Navigates to Forgot Password page.
     * Passes Start URL so it isn't lost during change process.
     */
    navigateToForgotPassword() {
        this.isLoading = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Forgot_Password'
            },
            state: {
                startURL: this.startUrl
            }
        });
    }

    /**
     * Navigates to external link page (commerce orders).
     *
     * @param {Event} event - The event to prevent the redirect.
     */
    navigateToMyOrders(event) {
        const emailInput = this.template.querySelector("[data-name='email']");
        const orderNumberInput = this.template.querySelector("[data-name='order']");
        const postalCodeInput = this.template.querySelector("[data-name='postalCode']");
        const regionInput = this.template.querySelector("[data-name='region']");

        const inputs = [emailInput, orderNumberInput, postalCodeInput, regionInput];
        var validFields = false;

        const url = event.target.dataset.href;
        const isExternalLink = url.startsWith('http://') || url.startsWith('https://');

        // 1. Validate fields.
        inputs.forEach((input) => {
            if (!input.value) {
                input.reportValidity();
                validFields = false;
                event.preventDefault();
            } else {
                validFields = true;
            }
        });

        if (validFields) {
            // 2. Generates the URL with parameters and redirects.
            if (isExternalLink) {
                // 2.1 Add the correct language to link.
                let redirectLink = url.includes('pt_PT')
                    ? url.replaceAll('pt_PT', getLanguageCode(currentLanguage))
                    : url + getLanguageCode(currentLanguage);

                redirectLink += '/orderguest';

                // 2.2 Add parameters to link.
                const urlObj = new URL(redirectLink);
                urlObj.searchParams.append('orderNumber', orderNumberInput.value);
                urlObj.searchParams.append('email', emailInput.value);
                urlObj.searchParams.append('zipCode', postalCodeInput.value);

                window.location.href = urlObj.toString();
            } else {
                // 3. Fallback scenario for internal navigation.
                if (url) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: url
                        }
                    });
                }
            }
        }
    }
}