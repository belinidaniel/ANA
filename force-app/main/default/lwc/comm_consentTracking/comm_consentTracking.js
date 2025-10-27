/**
 * @file File that manages comm__accountInformation functionalities.
 */
import { consentTracking, global } from 'c/i18n';
import { NavigationMixin } from 'lightning/navigation';
import { getLanguageCode } from 'c/languageUtils';
import currentLanguage from '@salesforce/i18n/lang';
import communityPath from '@salesforce/community/basePath';

import { LightningElement, api } from 'lwc';

export default class Comm_consentTracking extends NavigationMixin(LightningElement) {
    @api cookieLink;

    showConsentTracking = true;
    // Filter community name from community path
    pathSegments = communityPath.split('/').filter((segment) => segment.length > 0);
    communityName = this.pathSegments.length > 0 ? this.pathSegments[0] : 'default';
    consentTracking = 'sf_consenttracking_' + this.communityName;

    label = {
        description: consentTracking.DESCRIPTION,
        cookiesPolicy: consentTracking.COOKIES_POLICY,
        accept: global.GLOBAL_BUTTON_YES,
        decline: global.GLOBAL_BUTTON_NO
    };

    connectedCallback() {
        this.checkCookie();
    }

    hideConsentOnClickAccept() {
        const expirationDate = new Date();
        expirationDate.setTime(expirationDate.getTime() + 24 * 60 * 60 * 1000); // Expires after 1 day
        let expires = 'expires=' + expirationDate.toUTCString();
        document.cookie = '=true; ' + expires + '; path=/';
        // Alternatively, use localStorage
        localStorage.setItem(this.consentTracking, 'true');
        this.showConsentTracking = !this.showConsentTracking;
    }

    hideConsentOnClickDecline() {
        this.showConsentTracking = !this.showConsentTracking;
    }

    checkCookie() {
        const cookieExists =
            document.cookie.split(';').some((item) => item.trim().startsWith(this.consentTracking + '=')) ||
            localStorage.getItem(this.consentTracking);

        if (cookieExists) {
            this.showConsentTracking = false;
        }
    }

    /**
     * Navigates to Cookie page.
     *
     * @param {Event} event - The event object from the click event.
     */
    navigateToPage(event) {
        event.preventDefault();
        const isExternalLink = this.cookieLink.startsWith('http://') || this.cookieLink.startsWith('https://');

        if (isExternalLink) {
            //Replace Default Language (pt_PT) in cookie link to current site language
            const cookieLinkWithLanguage = this.cookieLink.replaceAll('pt_PT', getLanguageCode(currentLanguage));
            window.location.href = cookieLinkWithLanguage;
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.cookieLink
                }
            });
        }
    }
}