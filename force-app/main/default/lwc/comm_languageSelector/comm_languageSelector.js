/**
 * @file Manages the language selctor component.
 */
import { LightningElement } from 'lwc';

import currentLanguage from '@salesforce/i18n/lang';
import basePath from '@salesforce/community/basePath';
import activeLanguages from '@salesforce/site/activeLanguages';
import isGuest from '@salesforce/user/isGuest';
import { updateLocaleInParams } from 'c/languageUtils';
import verifyUserLanguage from '@salesforce/apex/COMM_LCC_LanguageSelector.verifyUserLanguage';
import updateUserLanguage from '@salesforce/apex/COMM_LCC_LanguageSelector.updateUserLanguage';

export default class Comm_languageSelector extends LightningElement {
    selectedLanguage;
    language = currentLanguage;

    connectedCallback() {
        this.getCurrentLanguage();
        this.verifyLanguage();
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
     * Check if User is Authenticated and his current language is different from Site's Language.
     * If he is then refresh page.
     */
    verifyLanguage() {
        if (!isGuest) {
            const siteCurrentLanguage = new URLSearchParams(window.location.search).get('language');
            verifyUserLanguage({ siteLanguage: siteCurrentLanguage }).then((result) => {
                if (result) {
                    window.location.reload();
                }
            });
        }
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

    /**
     * Select Language of Experience Builder Site.
     *
     * @param {Event} evt - Represents an event which takes place in the DOM.
     */
    handleOnClickSelectLanguage(evt) {
        // locale is in base path and needs to be replaced with new locale
        const currentUrl = window.location.pathname;

        if (currentUrl) {
            const selectedLanguageCode = evt.currentTarget.dataset.id;
            const urlParams = window.location.search;
            const newUrlParams = updateLocaleInParams(urlParams, currentLanguage, selectedLanguageCode);
            const restOfUrl = currentUrl.substring(basePath.length);
            if (!isGuest) {
                //If User is Authenticated then update his Language to the selected one then refresh page.
                updateUserLanguage({ siteLanguage: selectedLanguageCode.replace('-', '_') }).then(() => {
                    window.location.href = window.location.origin + basePath + restOfUrl + newUrlParams;
                });
            } else {
                window.location.href = window.location.origin + basePath + restOfUrl + newUrlParams;
            }
        }
    }
}