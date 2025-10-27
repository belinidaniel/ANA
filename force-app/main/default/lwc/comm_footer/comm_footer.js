/**
 * @file File that manages comm__footer functionalities.
 */

import { LightningElement, api, wire } from 'lwc';
import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import { global } from 'c/i18n';
import communityId from '@salesforce/community/Id';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
import { NavigationMixin } from 'lightning/navigation';
import { getLanguageCode } from 'c/languageUtils';
import currentLanguage from '@salesforce/i18n/lang';

const CMS_IMAGE = 'cms_image';
export default class Comm_footer extends NavigationMixin(LightningElement) {
    @api mainLogo;
    @api secondLogo;
    @api firstSectionTitle;
    @api secondSectionTitle;
    @api firstSectionLink1Label;
    @api firstSectionLink1Url;
    @api firstSectionLink2Label;
    @api firstSectionLink2Url;
    @api firstSectionLink3Label;
    @api firstSectionLink3Url;
    @api secondSectionLink1Label;
    @api secondSectionLink1Url;
    @api secondSectionLink2Label;
    @api secondSectionLink2Url;
    @api secondSectionLink3Label;
    @api secondSectionLink3Url;
    @api copyright;
    @api logoLink;

    mainLogoResourceUrl;
    secondLogoResourceUrl;

    contentKeys = [];

    label = {
        homepage: global.HOMEPAGE
    };

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    connectedCallback() {
        if (this.mainLogo) {
            this.contentKeys.push(this.mainLogo);
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
            const mainLogoResource = cms.getImageByContentKey(this.mainLogo);
            const secondLogoResource = cms.getImageByContentKey(this.secondLogo);

            this.mainLogoResourceUrl = mainLogoResource.url;
            this.secondLogoResourceUrl = secondLogoResource.url;
        } else if (error) {
            console.log(error);
        }
    }

    /**
     * Navigates to url.
     *
     * @param {Event} event - The event to pick the correct Url for each link.
     */
    navigateToPage(event) {
        event.preventDefault();
        const url = event.target.dataset.href;
        const isExternalLink = url.startsWith('http://') || url.startsWith('https://');
        this.isLoading = true;

        if (isExternalLink) {
            //Verify if url contains portuguese language code.
            //If it has then replace language code with current language.
            //If not then add code to end of external redirect link.
            const redirectLink = url.includes('pt_PT')
                ? url.replaceAll('pt_PT', getLanguageCode(currentLanguage))
                : url + getLanguageCode(currentLanguage);
            window.location.href = redirectLink;
        } else {
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