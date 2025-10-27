/**
 * @file Manages the logos component.
 */
import { LightningElement, api, wire } from 'lwc';

import Cms from 'c/cms';
import communityId from '@salesforce/community/Id';
import currentLanguage from '@salesforce/i18n/lang';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
import { NavigationMixin } from 'lightning/navigation';
import { getLanguageCode } from 'c/languageUtils';

const CMS_IMAGE = 'cms_image';

export default class Comm_logos extends NavigationMixin(LightningElement) {
    @api firstLogo;
    @api secondLogo;
    @api logoLink;

    firstLogoUrl;
    firstLogoTitle;
    secondLogoUrl;
    secondLogoTitle;
    contentKeys = [];
    data = {
        communityId: communityId,
        language: currentLanguage,
        managedContentType: CMS_IMAGE
    };
    language = currentLanguage;

    connectedCallback() {
        if (this.firstLogo) {
            this.contentKeys.push(this.firstLogo);
        }
        if (this.secondLogo) {
            this.contentKeys.push(this.secondLogo);
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
            const bannerFirstLogoResource = cms.getImageByContentKey(this.firstLogo);
            const bannerSecondLogoResource = cms.getImageByContentKey(this.secondLogo);

            this.firstLogoUrl = bannerFirstLogoResource.url;
            this.firstLogoTitle = bannerFirstLogoResource.title;
            this.secondLogoUrl = bannerSecondLogoResource.url;
            this.secondLogoTitle = bannerSecondLogoResource.title;
        } else if (error) {
            console.log(error);
        }
    }

    /**
     * Navigates to Home page.
     *
     * @param {Event} event - The event object from the click event.
     */
    navigateToHome(event) {
        event.preventDefault();
        const isExternalLink = this.logoLink.startsWith('http://') || this.logoLink.startsWith('https://');
        this.isLoading = true;

        if (isExternalLink) {
            //Verify if logos link contains portuguese language code.
            //If it has then replace language code with current language.
            //If not then add code to end of external redirect link.
            const redirectLink = this.logoLink.includes('pt_PT')
                ? this.logoLink.replaceAll('pt_PT', getLanguageCode(currentLanguage))
                : this.logoLink + getLanguageCode(currentLanguage);
            window.location.href = redirectLink;
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.logoLink
                }
            });
        }
    }
}