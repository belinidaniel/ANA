/**
 * @file Class that manages comm_accordion functionalities.
 */

import { LightningElement, api, wire } from 'lwc';

import Cms from 'c/cms';
import LANG from '@salesforce/i18n/lang';
import communityId from '@salesforce/community/Id';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';

const CMS_ACCORDION = 'Accordion';

export default class Comm_accordion extends LightningElement {
    @api accordionContent;

    showBody = false;

    accordionContentTitle;
    accordionContentBody;

    contentKeys;

    data = {
        communityId: communityId,
        language: LANG,
        managedContentType: CMS_ACCORDION
    };

    connectedCallback() {
        if (this.accordionContent) {
            let content = this.contentKeys ? this.contentKeys : [];
            content.push(this.accordionContent);
            this.contentKeys = content;
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
    wiredGetContentText({ data, error }) {
        if (data) {
            const cms = new Cms(data);
            const accordionResource = cms.getContentByContentKey(this.accordionContent);

            this.accordionContentTitle = accordionResource.title;
            this.accordionContentBody = accordionResource.body;
        } else if (error) {
            console.log(error);
        }
    }

    /**
     * Toggles the accordion body display.
     */
    onClickToggleBody() {
        const accordion = this.template.querySelector('.comm-accordion');
        accordion.classList.toggle('show');
    }
}