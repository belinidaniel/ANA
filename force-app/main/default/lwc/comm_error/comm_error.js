/**
 * @file Class that manages comm_error functionalities.
 */
import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import { NavigationMixin } from 'lightning/navigation';
import { error } from 'c/i18n';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';
import { LightningElement, api, wire } from 'lwc';

const CMS_IMAGE = 'cms_image';

export default class Comm_error extends NavigationMixin(LightningElement) {
    @api buttonLink;
    @api image;
    @api buttonLabel;

    imageUrl;
    imageTitle;

    contentKeys = [];

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    label = {
        title: error.ERROR_PAGE_TITLE,
        subtitle: error.ERROR_PAGE_SUBTITLE,
        error: error.ERROR_PAGE_404
    };

    connectedCallback() {
        if (this.image) {
            this.contentKeys.push(this.image);
        }
    }

    /* eslint-disable */
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
            const bannerimageResource = cms.getImageByContentKey(this.image);

            this.imageUrl = bannerimageResource.url;
            this.imageTitle = bannerimageResource.title;
        } else if (error) {
            console.log(error);
        }
    }
    /* eslint-enable */

    /**
     * Navigates to Home page.
     */
    navigateToPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.buttonLink
            }
        });
    }
}