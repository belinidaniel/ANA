/**
 * @file Resolve the CMS paths.
 */
import { getPathPrefix } from 'lightning/configProvider'; // Provides the path prefix to Core resources, like CMS

/**
 * Regular expressions for CMS resources and for static B2B image resources -
 * specifically the "no image" image - that we want to handle as though they were CMS resources.
 */
const cmsResourceUrlPattern = /^\/cms\//;
const b2bStaticImageResourcePattern = /^\/img\//;
const urlResource = /^\/http\//;

/**
 * Resolves a URL for a resource that may (or may not) be hosted by Salesforce CMS.
 *
 * @param {string} url - A URL of a resource. This may - or may not - be a Salesforce-hosted CMS resource.
 * @returns {string} If represents a CMS-hosted resource, then a resolved CMS resource URL otherwise, the unaltered url.
 */
export function resolve(url) {
    // If the URL is a CMS URL, transform it; otherwise, leave it alone.
    if ((cmsResourceUrlPattern.test(url) || b2bStaticImageResourcePattern.test(url)) && !urlResource.test(url)) {
        url = `${getPathPrefix()}${url}`;
    }

    return url;
}