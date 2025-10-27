/**
 * @file Class that manages comm_emailChange functionalities.
 */
import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { isInSitePreview } from 'c/siteUtils';
import { tokens } from 'c/constants';
import { emailChange } from 'c/i18n';
import validateEmailChange from '@salesforce/apex/COMM_LCC_EmailChange.validateEmailChange';
import basePath from '@salesforce/community/basePath';
import isGuest from '@salesforce/user/isGuest';

import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
const CMS_IMAGE = 'cms_image';

export default class Comm_emailChange extends NavigationMixin(LightningElement) {
    @api pageIllustration;

    pageIllustrationUrl;
    pageIllustrationTitle;

    isLoading = true;
    showForm = false;

    contentKeys = [];

    token = {
        emailChangeToken: tokens.EMAIL_CHANGE_ENCONDED_TOKEN
    };

    label = {
        confirmEmailSuccess: emailChange.CHANGE_EMAIL_SUCCESS,
        confirmEmailExpired: emailChange.CHANGE_EMAIL_EXPIRED,
        emailChangeTitle: emailChange.CHANGE_EMAIL_TITLE,
        goToLogin: emailChange.GO_TO_LOGIN
    };

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    connectedCallback() {
        if (this.pageIllustration) {
            this.contentKeys.push(this.pageIllustration);
        }
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
     * Handles the request from the wire service. Verifies Page Parameters and if it exist retrieve token.
     *
     * @param {object} currentPageReference - Object with the data received from request.
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        //If Site is in Preview, show invalid form
        if (isInSitePreview()) {
            this.isEmailChanged = false;
            this.showForm = true;
            this.isLoading = false;
        } else if (currentPageReference && currentPageReference.state) {
            const emailChangeToken = currentPageReference.state[this.token.emailChangeToken];
            //If Token Provided check if it's Valid
            if (emailChangeToken) {
                validateEmailChange({ token: emailChangeToken })
                    .then((result) => {
                        this.isEmailChanged = result;
                        //If User is Authenticated, navigate to Account Management with result of change.
                        if (!isGuest) {
                            this.navigateToAccountManagement(result);
                        } else {
                            //If User is Guest, show form indicating change result.
                            this.showForm = true;
                            this.isLoading = false;
                        }
                    })
                    .catch(() => {
                        this.isEmailChanged = false;
                        if (!isGuest) {
                            //If User is Authenticated, navigate to Account Management with change as failed.
                            this.navigateToAccountManagement(false);
                        } else {
                            //If User is Guest, show form indicating link is invalid.
                            this.showForm = true;
                            this.isLoading = false;
                        }
                    });
            } else if (this.isEmailChanged === undefined) {
                //If User is Authenticated, navigate to Account Management with change as failed.
                if (!isGuest) {
                    this.navigateToAccountManagement(false);
                } else {
                    //If User is Guest, show form indicating link is invalid
                    this.isEmailChanged = false;
                    this.showForm = true;
                    this.isLoading = false;
                }
            }
        }
    }

    /**
     * Navigate User to Login Page.
     */
    navigateToLogin() {
        //Navigate using webPage so startURL doesn't point to email change page
        const loginUrl = basePath + '/login';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: loginUrl
            }
        });
    }

    /**
     * Navigate User to Account Management Page.
     *
     * @param {boolean} changeResult - Email Change Result. True if success, false otherwise.
     */
    navigateToAccountManagement(changeResult) {
        this[NavigationMixin.Navigate](
            {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Account_Management__c'
                },
                state: {
                    emailChangeSuccess: changeResult.toString()
                }
            },
            true
        );
    }
}