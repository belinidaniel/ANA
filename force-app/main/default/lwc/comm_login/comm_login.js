/**
 * @file File that manages comm__login functionalities.
 */
import { login, global } from 'c/i18n';
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import siteLogin from '@salesforce/apex/COMM_LCC_Login.siteLogin';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';

const CMS_IMAGE = 'cms_image';

export default class Comm_login extends NavigationMixin(LightningElement) {
    @api loginWithAD;
    @api pageIllustration;

    pageIllustrationUrl;
    pageIllustrationTitle;

    hasRendered = false;
    isFormError = false;
    isCredentialsLogin = false;
    isReservationLogin = false;

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

    // Get current state parameters.
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.startUrl = currentPageReference.state?.startURL;
        }
    }

    connectedCallback() {
        this.isCredentialsLogin = !this.loginWithAD;
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
     * Toggles forms visibility.
     */
    toggleLoginForm() {
        this.isCredentialsLogin = !this.isCredentialsLogin;
        this.isReservationLogin = !this.loginWithAD && !this.isCredentialsLogin;
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
     */
    handleOnClickLogin() {
        const email = this.template.querySelector("[data-name='email']").value;
        const password = this.template.querySelector("[data-name='password']").value;

        // Validates if the email and password input has values
        if (!email || !password) {
            return;
        }

        siteLogin({
            startUrl: this.startUrl,
            userData: {
                email: email,
                password: password
            }
        })
            .then((data) => {
                if (data) {
                    window.location.href = data;
                } else {
                    console.log('User not found');
                    this.isFormError = true;
                }
            })
            .catch((error) => {
                console.log(error);
                this.isFormError = true;
            });
    }
}