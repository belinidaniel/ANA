/**
 * @file Manages the Automatically Redirect User function.
 */
import { LightningElement, api } from 'lwc';

export default class Comm_redirectBackground extends LightningElement {
    @api redirectLink;
    isLoading = false;

    connectedCallback() {
        //Redirect User if Site isn't running as a Preview (ex: Experience Builder)
        if (!this.isInSitePreview() && this.redirectLink) {
            this.handleRedirect();
        }
    }

    /**
     * Handle redirect to the specified link.
     */
    handleRedirect() {
        this.isLoading = true;

        //Verify if Param has target and is set to checkout. If it is then replace commerce target endpoint from home (3) to checkout (2).
        const target = new URLSearchParams(window.location.search)?.get('target');
        const urlRedirection =
            target === 'checkout' ? this.redirectLink.replace('oauthLoginTargetEndPoint=3', 'oauthLoginTargetEndPoint=2') : this.redirectLink;
        window.location.replace(urlRedirection);
    }

    /**
     * Verify if Component is running under Experience Builder or site preview context.
     *
     * @returns {boolean} True if running in Experience Builder, False otherwise.
     */
    isInSitePreview() {
        const url = document.URL;

        return (
            url &&
            (url.indexOf('sitepreview') > 0 ||
                url.indexOf('livepreview') > 0 ||
                url.indexOf('live-preview') > 0 ||
                url.indexOf('live.') > 0 ||
                url.indexOf('.builder.') > 0 ||
                url.indexOf('.preview.') > 0)
        );
    }
}