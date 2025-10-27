/**
 * @file Utils for language.
 */

import { updateRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import basePath from '@salesforce/community/basePath';
import isGuest from '@salesforce/user/isGuest';

/**
 * Select Language of Experience Builder Site.
 *
 * @param {string} params - Represents an event which takes place in the DOM.
 * @param {string} oldLocale - Represents an event which takes place in the DOM.
 * @param {string} newLocale - Represents an event which takes place in the DOM.
 * @returns {string} The new path with new language defined.
 */
function updateLocaleInParams(params, oldLocale, newLocale) {
    //Replace - with _ (ex: en-US is converted into en_US)
    const previousLocale = oldLocale.replace('-', '_');
    const selectedLocale = newLocale.replace('-', '_');
    if (params.includes('language=' + previousLocale)) {
        // replace with new locale
        return params.replace(new RegExp('language=' + previousLocale), 'language=' + selectedLocale);
    }
    const languageParameter = params.includes('?') ? '&language=' : '?language=';
    return params + languageParameter + selectedLocale;
}

/**
 * Select Language.
 *
 * @param {string} language - The language code to switch to.
 * @param {string} currentLanguage - The current language code.
 */
function changeLanguage(language, currentLanguage) {
    const currentUrl = window.location.pathname;

    if (currentUrl) {
        const selectedLanguageCode = language;
        const urlParams = window.location.search;
        const newUrlParams = updateLocaleInParams(urlParams, currentLanguage, selectedLanguageCode);
        const restOfUrl = currentUrl.substring(basePath.length);
        // If User is Authenticated then switch his Language to the selected one.
        if (!isGuest) {
            const fields = {};
            fields.Id = userId;
            fields.LanguageLocaleKey = selectedLanguageCode.replace('-', '_');
            const userRecord = { fields };
            updateRecord(userRecord)
                .then(() => {
                    window.location.href = window.location.origin + basePath + restOfUrl + newUrlParams;
                })
                .catch((error) => {
                    console.log(error);
                });
        } else {
            window.location.href = window.location.origin + basePath + restOfUrl + newUrlParams;
        }
    }
}

/**
 * Method to obtain language code used in Commerce based on site's current language.
 *
 * @param {string} currentLanguage - The current language code.
 * @returns {string} Converted language code of current language.
 */
function getLanguageCode(currentLanguage) {
    //Convert Language Code to one used in Commerce
    switch (currentLanguage) {
        case 'en-US':
            return 'en';
        case 'pt-PT':
            return 'pt_PT';
        case 'es':
            return 'es';
        default:
            return currentLanguage.replace('-', '_');
    }
}

export { changeLanguage, updateLocaleInParams, getLanguageCode };