/**
 * @file File that manages comm__input functionalities.
 */

import { LightningElement, api } from 'lwc';

export default class Comm_input extends LightningElement {
    @api type;
    @api label;
    @api value;
    @api pattern;
    @api isRequired;
    @api isDisabled;
    @api checked;
    @api options;
    @api srcData;
    @api messageWhenPatternMismatch;
    @api maxLength;

    /**
     * Returns the result of checking if the current input is valid.
     *
     * @returns {boolean} True if current input is valid, false otherwise.
     */
    @api get validity() {
        if (this.isTypeSelect) {
            return this.template.querySelector('lightning-combobox').checkValidity();
        } else if (this.isTypeTextarea) {
            return this.template.querySelector('lightning-textarea').checkValidity();
        }
        return this.template.querySelector('lightning-input').checkValidity();
    }

    /**
     * Sets Custom Validation Message to appear.
     *
     * @param {string} errorMessage - Error Message to appear in component.
     */
    @api setCustomValidity(errorMessage) {
        let inputComponent;
        if (this.isTypeSelect) {
            inputComponent = this.template.querySelector('lightning-combobox');
        } else if (this.isTypeTextarea) {
            inputComponent = this.template.querySelector('lightning-textarea');
        } else {
            inputComponent = this.template.querySelector('lightning-input');
        }
        inputComponent.setCustomValidity(errorMessage);
        inputComponent.reportValidity();
    }

    /**
     * Method to verify if current input is valid, if it isn't show error messages.
     *
     * @returns {boolean} True if current input is valid, false otherwise.
     */
    @api
    reportValidity() {
        let inputComponent;
        if (this.isTypeSelect) {
            inputComponent = this.template.querySelector('lightning-combobox');
        } else if (this.isTypeTextarea) {
            inputComponent = this.template.querySelector('lightning-textarea');
        } else {
            inputComponent = this.template.querySelector('lightning-input');
        }
        return inputComponent.reportValidity();
    }

    @api
    get className() {
        return this._className;
    }
    set className(data) {
        this._className = data;
    }

    isTypePassword = false;
    isTypeSelect = false;
    isTypeTextarea = false;

    connectedCallback() {
        if (this.type === 'password') {
            this.isTypePassword = true;
        } else if (this.type === 'select') {
            this.isTypeSelect = true;
        } else if (this.type === 'textarea') {
            this.isTypeTextarea = true;
        }

        window.addEventListener('beforeunload', this.emptyValue);
    }

    renderedCallback() {
        if (this.value !== undefined) {
            this.setActive();
        }
    }

    emptyValue = () => {
        const inputFields = this.template.querySelector('lightning-input') || this.template.querySelector('lightning-textarea');

        if (inputFields && inputFields.value) {
            inputFields.value = '';
        }
    };

    /**
     * Handles input field focus.
     */
    handleFocus() {
        this.setActive();
    }

    /**
     * Checks if input field has value and toggles its state.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    handleOnChange(event) {
        const value = event.target.value;

        if (value === '') {
            this.unsetActive();
        } else {
            this.setActive();
        }

        this.triggerChangeEvent(event);
    }

    handleOnBlur(event) {
        const value = event.target.value;

        if (value === '') {
            this.unsetActive();
        } else {
            this.setActive();
        }

        this.triggerChangeEvent(event);
    }

    /**
     * Sets 'active' class on input for label placement manipulation.
     */
    setActive() {
        const inputFields = this.template.querySelector('lightning-input') || this.template.querySelector('lightning-textarea');

        if (inputFields && inputFields !== null && inputFields !== '') {
            inputFields.classList.add('active');
        }
    }

    /**
     * Unsets 'active' class on input for label placement manipulation.
     */
    unsetActive() {
        const input = this.template.querySelector('.comm-form__input') || this.template.querySelector('lightning-textarea');

        if (input && input !== null && input.classList.contains('active')) {
            input.classList.remove('active');
        }
    }

    /**
     * Toggles password input type to make the value visible.
     */
    togglePasswordVisibility() {
        const icon = this.template.querySelector('.comm-icon__eye-stricked');

        if (this.type === 'password') {
            this.type = 'text'; // eslint-disable-line
            icon.classList.add('is-text');
        } else {
            this.type = 'password'; // eslint-disable-line
            icon.classList.remove('is-text');
        }
    }

    /**
     * Handles Input change with a custom event.
     *
     * @param {Event} event - Event taking place in the DOM.
     */
    triggerChangeEvent(event) {
        /* eslint-disable */
        this.value = event.target.value;
        const checkedValue = event.target.checked;

        const onChangeEvent = new CustomEvent('change', {
            detail: {
                value: this.value,
                checked: checkedValue
            }
        });

        this.dispatchEvent(onChangeEvent);
        /* eslint-enable */
    }

    _className = 'comm-form__input';
}