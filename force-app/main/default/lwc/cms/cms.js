/**
 * @file Utils class that manages the cms content functionalities.
 */
export default class Cms {
    listOfManagedContentVersion = [];

    constructor(data) {
        this.listOfManagedContentVersion = data || [];
    }

    /**
     * Get the content given a content key.
     *
     * @param {string} contentKey - Managed content key to search.
     * @returns {object} Content if exists, undefined otherwise.
     */
    getContentByKey(contentKey) {
        const content = this.listOfManagedContentVersion.find((managedContentVersion) => managedContentVersion.contentKey === contentKey);

        return typeof content !== 'undefined' ? content : null;
    }

    /**
     * Get url of the managed content.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The url of the content, null in case of error.
     */
    getContentUrlByContent(content) {
        return content !== null && 'contentNodes' in content && 'source' in content.contentNodes ? content.contentNodes.source.url : null;
    }

    /**
     * Get title of the managed content.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The title of the content, null in case of error.
     */
    getContentTitleByContent(content) {
        return content !== null && 'contentNodes' in content && 'title' in content.contentNodes ? content.contentNodes.title.value : null;
    }

    /**
     * Get body associated to a managed content.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The body of the managed content, null in case of error.
     */
    getContentBodyByContent(content) {
        return content !== null && 'contentNodes' in content && 'body' in content.contentNodes ? content.contentNodes.body.value : null;
    }

    /**
     * Get published date associated to a managed content.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The published date of the managed content, null in case of error.
     */
    getContentPublishedDateByContent(content) {
        return content !== null ? content.publishedDate : null;
    }

    /**
     * Get url of the image.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The url of the content, null in case of error.
     */
    getUrlImage(content) {
        return content !== null && 'contentNodes' in content && 'image' in content.contentNodes ? content.contentNodes.image.url : null;
    }

    /**
     * Get image data given a managed content key.
     *
     * @param {string} contentKey - Managed content key.
     * @returns {object} Representing an image.
     */
    getImageByContentKey(contentKey) {
        const content = this.getContentByKey(contentKey);

        return {
            id: contentKey,
            url: this.getContentUrlByContent(content),
            title: this.getContentTitleByContent(content)
        };
    }

    /**
     * Get data given a managed content key.
     *
     * @param {string} contentKey - Managed content key.
     * @returns {object} Representing a blog.
     */
    getContentByContentKey(contentKey) {
        const content = this.getContentByKey(contentKey);

        return {
            id: content.contentKey,
            body: this.htmlDecode(this.getContentBodyByContent(content)),
            title: this.getContentTitleByContent(content)
        };
    }

    /**
     * Get images data given a list of managed content keys.
     *
     * @param {Array<string>} contentKeys - List of managed content keys.
     * @returns {Array<object>} List of images.
     */
    getImagesByContentKeys(contentKeys) {
        return contentKeys.map((contentKey) => {
            return this.getImageByContentKey(contentKey);
        });
    }

    /**
     * Get priority field value of the managed content.
     *
     * @param {object} content - Managed content.
     * @returns {string | null} The url of the content, null in case of error.
     */
    getContentDescription(content) {
        return content !== null && 'contentNodes' in content && 'description' in content.contentNodes ? content.contentNodes.description.value : '';
    }

    /**
     * Decode entities to be accept on HTML, e.g.: &lt to '<'.
     *
     * @param {string} input - String to be decoded.
     * @returns {string} - String decoded.
     */
    htmlDecode(input) {
        let e = document.createElement('span');
        /* eslint-disable-next-line */
        e.innerHTML = input;
        return e.childNodes[0].nodeValue;
    }

    /**
     * Get titles data given a manages content key.
     *
     * @param {string} contentKey - Managed content key.
     * @returns {object} - Content object.
     */
    getContentTitleByContentKey(contentKey) {
        const content = this.getContentByKey(contentKey);

        return {
            value: contentKey,
            label: this.getContentTitleByContent(content)
        };
    }

    /**
     * Get titles given a list of managed content keys.
     *
     * @param {Array<string>} contentKeys - List of managed content keys.
     * @returns {Array<object>} List of titles.
     */

    getContentTitles(contentKeys) {
        return contentKeys.map((contentKey) => {
            return this.getContentTitleByContentKey(contentKey);
        });
    }
}