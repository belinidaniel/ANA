/**
 * @file Class that manages comm_heroBanner functionalities.
 */
import { LightningElement, api, wire } from 'lwc';
import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';

const CMS_IMAGE = 'cms_image';

export default class Comm_heroBanner extends LightningElement {
    @api image;
    @api title;
    @api subtitle;
    @api textColor;

    imageUrl;
    imageTitle;

    contentKeys = [];

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_IMAGE
    };

    connectedCallback() {
        if (this.image) {
            this.contentKeys.push(this.image);
        }
    }

    renderedCallback() {
        this.setStyles();
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
            const bannerImageResource = cms.getImageByContentKey(this.image);

            this.imageUrl = bannerImageResource.url;
            this.imageTitle = bannerImageResource.title;
        } else if (error) {
            console.log(error);
        }
    }

    /**
     * Set the styles configuration.
     */
    setStyles() {
        const container = this.template.querySelector('span');
        const defaultColor = '#FFFFFF';

        container.style.setProperty('--text-color', this.textColor ?? defaultColor);
    }
}