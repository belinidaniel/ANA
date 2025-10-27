/* eslint-disable @lwc/lwc/no-inner-html */
/**
 * @file Insert elements to the DOM.
 */
import { LightningElement, api } from 'lwc';

export default class DomManual extends LightningElement {
    @api button;
    @api classes;
    @api checkbox;
    @api htmlString;
    @api input;
    @api text;

    /**
     * Append to the div element the html string from the parent component.
     */
    renderedCallback() {
        this.template.querySelector('div').innerHTML = this.decodeEntity(this.htmlString);
    }

    /**
     * Handles on change event and send data to the parent component.
     *
     * @param {Event} event - DOM event.
     */
    handleOnChange(event) {
        let el = null;

        if (this.input) {
            el = this.template.querySelector('input');
        }

        let eventDetail = this.getDataAttributes(el);
        eventDetail.push({ value: event.target.value });

        this.dispatchEvent(
            new CustomEvent('event', {
                detail: eventDetail
            })
        );
    }

    /**
     * Handles on click event. Get the data attributes of the type of
     * HTML element and send them to the parent component.
     */
    handleOnClick() {
        let el = null;

        if (this.button) {
            el = this.template.querySelector('button');

            this.dispatchEvent(
                new CustomEvent('event', {
                    detail: this.getDataAttributes(el)
                })
            );
        }
    }

    /**
     * Get data attributes from element.
     *
     * @param {Element} el - Target element.
     * @returns {Array<object>} List of data attributes.
     */
    getDataAttributes(el) {
        let attrs = [];

        if (el) {
            // Cycle over each attribute on the element
            for (let i = 0; i < el.attributes.length; i++) {
                // Store reference to current attr
                const attr = el.attributes[i];
                // If attribute nodeName starts with 'data-'
                if (/^data-/.test(attr.nodeName)) {
                    const dataAttr = attr.nodeName.replace(/^data-/, '');
                    const dataAttrValue = attr.nodeValue;

                    const attrObj = {};
                    attrObj[dataAttr] = dataAttrValue;

                    attrs.push(attrObj);
                }
            }
        }

        return attrs;
    }

    /**
     * Decodes a html string.
     *
     * @param {string} inputStr - The html string to be decoded.
     * @returns {string} The html string decoded.
     */
    decodeEntity(inputStr) {
        const textarea = document.createElement('textarea');
        textarea.innerHTML = inputStr;
        return textarea.value;
    }
}