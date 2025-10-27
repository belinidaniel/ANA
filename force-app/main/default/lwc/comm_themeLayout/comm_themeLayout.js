/* eslint-disable */

/**
 * @file Class that manages comm_themeLayout functionalities. Renders the global theme layout.
 */

import { LightningElement } from 'lwc';
import { accessibility } from 'c/i18n';

/**
 * @slot header
 * @slot main
 * @slot footer
 */
export default class Comm_themeLayout extends LightningElement {
    label = {
        header: accessibility.HEADER,
        main: accessibility.MAIN,
        footer: accessibility.FOOTER
    };

    /**
     * Function to open 'Section' by pressing 'Tab'.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    showSkipLinks(event) {
        const container = this.template.querySelector('.comm-theme__skip-links');
        if (event.key == 'Tab') {
            container.classList.add('show');
        }
    }

    /**
     * Function to close 'Section'.
     */
    closeSkipLinks() {
        const container = this.template.querySelector('.comm-theme__skip-links');
        container.classList.remove('show');
    }
}