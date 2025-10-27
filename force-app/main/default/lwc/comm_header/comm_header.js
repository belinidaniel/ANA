/**
 * @file Class that manages comm_header functionalities.
 */

import { LightningElement, api, wire } from 'lwc';

import Cms from 'c/cms';
import isGuest from '@salesforce/user/isGuest';
import communityId from '@salesforce/community/Id';
import currentLanguage from '@salesforce/i18n/lang';
import basePath from '@salesforce/community/basePath';
import activeLanguages from '@salesforce/site/activeLanguages';
import getContentByContentKeys from '@salesforce/apex/CMSController.getContentByContentKeys';

const CMS_IMAGE = 'cms_image';

export default class Comm_header extends LightningElement {
    @api firstLogo;
    @api secondLogo;

    // Menu Navigation APIs
    @api linkSetMasterLabel;
    @api addHomeMenuItem = false;
    @api includeImageUrls = false;

    firstLogoUrl;
    firstLogoTitle;
    secondLogoUrl;
    secondLogoTitle;

    selectedLanguage;
    language = currentLanguage;

    contentKeys = [];

    data = {
        communityId: communityId,
        language: currentLanguage,
        managedContentType: CMS_IMAGE
    };

    connectedCallback() {
        if (this.firstLogo) {
            this.contentKeys.push(this.firstLogo);
        }
        if (this.secondLogo) {
            this.contentKeys.push(this.secondLogo);
        }
        this.getCurrentLanguage();
    }

    /**
     * Verify if is a guest user.
     *
     * @returns {boolean} True if is a guest user.
     */
    get isGuest() {
        return isGuest;
    }

    /**
     * Gets all languages defined in Experience Builder Site.
     *
     * @type {string}
     * @returns {object} - Current Language information.
     */
    get langOptions() {
        return (activeLanguages || []).map((item) => {
            let language = '';
            let isCurrentLanguage;

            if (item.code === 'en-US') {
                language = 'EN';
            } else if (item.code === 'pt-PT') {
                language = 'PT';
            } else if (item.code === 'es') {
                language = 'ES';
            }

            if (item.code === currentLanguage) {
                isCurrentLanguage = true;
            }

            return {
                value: item.code,
                label: item.label,
                language: language,
                isCurrentLanguage: isCurrentLanguage
            };
        });
    }

    /**
     * Gets the selected current language.
     *
     * @type {string}
     * @returns {string} - The selected language.
     */
    getCurrentLanguage() {
        if (currentLanguage === 'en-US') {
            this.selectedLanguage = 'EN';
        } else if (currentLanguage === 'es') {
            this.selectedLanguage = 'ES';
        } else {
            this.selectedLanguage = 'PT';
        }

        return this.selectedLanguage;
    }

    /**
     * Toggles the menu navigation display.
     */
    toggleMenu() {
        const button = this.template.querySelector('.comm-header__navigation-menu-toggle');

        button.classList.toggle('show');
    }

    /**
     * Toggles the multilanguage accordion display.
     */
    toggleAccordion() {
        const button = this.template.querySelector('.comm-header__button-language');

        if (button.contains('.show')) {
            this.hideAccordion();
        } else {
            this.showAccordion();
        }
    }

    /**
     * Shows the multilanguage accordion.
     */
    showAccordion() {
        const button = this.template.querySelector('.comm-header__button-language');
        button.classList.add('show');
    }

    /**
     * Hides the multilanguage accordion.
     */
    hideAccordion() {
        const button = this.template.querySelector('.comm-header__button-language');
        button.classList.remove('show');
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
     * Select Language of Experience Builder Site.
     *
     * @param {Event} evt - Represents an event which takes place in the DOM.
     */
    handleOnClickSelectLanguage(evt) {
        const selectedLanguageCode = evt.currentTarget.dataset.id;
        // locale is in base path and needs to be replaced with new locale
        const newBasePath = this.updateLocaleInBasePath(basePath, currentLanguage, selectedLanguageCode);
        const currentUrl = window.location.pathname;

        if (currentUrl) {
            const restOfUrl = currentUrl.substring(basePath.length);
            const urlParams = window.location.search;
            window.location.href = window.location.origin + newBasePath + restOfUrl + urlParams;
        }
    }

    /**
     * Select Language of Experience Builder Site.
     *
     * @param {string} path - Represents an event which takes place in the DOM.
     * @param {string} oldLocale - Represents an event which takes place in the DOM.
     * @param {string} newLocale - Represents an event which takes place in the DOM.
     * @returns {string} The new path with new language defined.
     */
    updateLocaleInBasePath(path, oldLocale, newLocale) {
        if (path.endsWith('/' + oldLocale)) {
            // replace with new locale
            return path.replace(new RegExp('/' + oldLocale + '$'), '/' + newLocale);
        }
        return path + '/' + newLocale;
    }
}