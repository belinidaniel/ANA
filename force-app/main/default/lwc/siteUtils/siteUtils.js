/**
 * @file Utils for community site.
 */

/**
 * Verify if Component is running under Experience Builder or site preview context.
 *
 * @returns {boolean} True if running in Experience Builder, False otherwise.
 */
function isInSitePreview() {
    const url = document.URL;

    return (
        url &&
        (url.indexOf('sitepreview') > 0 ||
            url.indexOf('livepreview') > 0 ||
            url.indexOf('live-preview') > 0 ||
            url.indexOf('.builder.') > 0 ||
            url.indexOf('.preview.') > 0)
    );
}

export { isInSitePreview };