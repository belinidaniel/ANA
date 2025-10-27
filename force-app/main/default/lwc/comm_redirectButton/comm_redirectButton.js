/**
 * @file Manages the Redirect Button.
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Comm_redirectButton extends NavigationMixin(LightningElement) {
    @api redirectButton;
    @api redirectButtonLink;
    @api orientation;

    renderedCallback() {
        this.setOrientation();
    }

    /**
     * Set the Position configuration.
     */
    setOrientation() {
        const container = this.template.querySelector('.comm-redirect-button-container');

        if (this.orientation) {
            container.classList.add('comm-redirect-button__right');
        } else {
            container.classList.remove('comm-redirect-button__right');
        }
    }

    /**
     * Handle button click to redirect to the specified link.
     *
     * @param {Event} event - The click event.
     */
    handleRedirect(event) {
        event.stopPropagation(); // Stop the event from bubbling up
        if (this.redirectButtonLink) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.redirectButtonLink
                }
            });
        }
    }

    /**
     * Get the appropriate CSS class for button orientation.
     *
     * @returns {string} The CSS class based on the orientation.
     */
    get orientationClass() {
        return this.orientation ? 'comm-redirect-button__right' : '';
    }
}