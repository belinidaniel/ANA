/* eslint-disable */

/**
 * @file File that manages comm_passwordValidator functionalities.
 */
import { passwordValidator } from 'c/i18n';
import { LightningElement, api } from 'lwc';
import { validations } from 'c/constants';

export default class Comm_passwordValidator extends LightningElement {
    validation = {
        passEmailNameCharLimit: validations.PASS_CONTAINS_EMAIL_OR_NAME_CHARS
    };

    _password = '';
    _passwordConfirmation = '';
    _firstName = '';
    _lastName = '';
    _email = '';

    /**
     * Handles password value.
     */
    @api
    set password(value) {
        this._password = value;
        this.handlePasswordChange();
    }

    get password() {
        return this._password;
    }

    /**
     * Handles password confirmation value.
     */
    @api
    set passwordConfirmation(value) {
        this._passwordConfirmation = value;
        this.handlePasswordChange();
    }

    get passwordConfirmation() {
        return this._passwordConfirmation;
    }

    /**
     * Handles email value.
     */
    @api
    set email(value) {
        this._email = value;
        this.handlePasswordChange();
    }

    get email() {
        return this._email;
    }

    /**
     * Handles first name value.
     */
    @api
    set firstName(value) {
        this._firstName = value;
        this.handlePasswordChange();
    }

    get firstName() {
        return this._firstName;
    }

    /**
     * Handles last name value.
     */
    @api
    set lastName(value) {
        this._lastName = value;
        this.handlePasswordChange();
    }

    get lastName() {
        return this._lastName;
    }

    passwordValidation = false;

    rules = [/^.{9,}$/, /(?=.*[a-z])/, /(?=.*[A-Z])/, /(?=.*[0-9])/, /[`!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~]/, '', ''];

    label = {
        title: passwordValidator.TITLE,
        range: passwordValidator.RANGE,
        number: passwordValidator.NUMBER,
        identical: passwordValidator.IDENTICAL,
        upperCase: passwordValidator.UPPERCASE,
        lowerCase: passwordValidator.LOWERCASE,
        specialCharacter: passwordValidator.SPECIAL_CHARACTER,
        notContainEmailOrName: passwordValidator.NOT_CONTAIN_EMAIL_OR_NAME
    };

    connectedCallback() {
        // Setting initial values
        this._password = this.password || '';
        this._passwordConfirmation = this.passwordConfirmation || '';
        this._email = this.email || '';
        this._firstName = this.firstName || '';
        this._lastName = this.lastName || '';
    }

    renderedCallback() {
        // Ensure the DOM is fully rendered before handling password change
        this.handlePasswordChange();
    }

    /**
     * Handles password change to apply validations.
     */
    handlePasswordChange() {
        const requirements = this.template.querySelectorAll('.comm-password-validator__requirements > li');

        let validCounter = 0;
        if (this.password != null) {
            this.rules.forEach((rule, i) => {
                if (i < 5 && rule.test(this.password)) {
                    requirements[i].classList.add('is-valid');
                    validCounter++;
                } else if (i == 5 && this.password === this.passwordConfirmation && this.password !== '') {
                    requirements[i].classList.add('is-valid');
                    validCounter++;
                } else if (
                    i == 6 &&
                    !this.hasRepeats(this.password, this.email) &&
                    !this.hasRepeats(this.password, this.firstName) &&
                    !this.hasRepeats(this.password, this.lastName)
                ) {
                    //Verify 6th rule. Password doesn't contain part (5 characters) of email, first or last name
                    requirements[i].classList.add('is-valid');
                    validCounter++;
                } else {
                    requirements[i].classList.remove('is-valid');
                }
            });
        }

        //Verify if Password Validation was changed. Sends event to Parent informing of change.
        let validationResult = validCounter === this.rules.length;
        if (this.passwordValidation != validationResult) {
            this.dispatchEvent(
                new CustomEvent('validation', {
                    detail: {
                        value: validationResult
                    }
                })
            );
            this.passwordValidation = validationResult;
        }
    }

    /**
     * Method to verify if a string contains substring of 5 characters of another.
     *
     * @param {string} value String to verify if it has a substring of another.
     * @param {string} compare String to compare against.
     * @returns True if string contains a subscring of the other. False otherwise.
     */
    hasRepeats(value, compare) {
        let repeatFound = false;
        //If compare string doesn't have value or is empty then pass validation
        if (compare) {
            const charLimit = this.validation.passEmailNameCharLimit;
            const maxLimit = compare.length > charLimit ? compare.length - charLimit : 0;
            for (let index = 0; index <= maxLimit; index++) {
                //Validation is Case Insensitive
                repeatFound = value.toLowerCase().includes(compare.substring(index, index + charLimit).toLowerCase());
                if (repeatFound) {
                    break;
                }
            }
        }
        return repeatFound;
    }
}