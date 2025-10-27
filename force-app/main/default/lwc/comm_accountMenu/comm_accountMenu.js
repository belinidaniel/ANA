/**
 * @file Class that manages comm_accountMenu functionalities.
 */
import { header, global } from 'c/i18n';
import { getRecord } from 'lightning/uiRecordApi';
import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getLanguageCode } from 'c/languageUtils';
import currentLanguage from '@salesforce/i18n/lang';

import UserId from '@salesforce/user/Id';
import Id from '@salesforce/community/Id';
import isGuest from '@salesforce/user/isGuest';
import basePath from '@salesforce/community/basePath';
import UserLastName from '@salesforce/schema/User.LastName';
import UserFirstName from '@salesforce/schema/User.FirstName';
import UserProfile from '@salesforce/schema/User.Profile.Name';
import switchAccount from '@salesforce/apex/COMM_LCC_ExternalManagedAccount.switchAccount';
import getEffectiveAccountId from '@salesforce/apex/COMM_LCC_ExternalManagedAccount.getEffectiveAccountId';
import getExternalManagedAccounts from '@salesforce/apex/COMM_LCC_ExternalManagedAccount.getExternalManagedAccounts';

// Constant
const COSTUMER_PROFILE = 'Customers';

export default class Comm_accountMenu extends NavigationMixin(LightningElement) {
    @api myReservationsLink;
    @api commerceLogoutLink;
    communityId = Id;
    _managedAccounts = []; // List of managed accounts by the user
    selectedEffectiveAccountId; // AccountId of the account Switched
    disableSelectButton = true; // Initially disabled
    username = '';
    initials = '';
    value = '';
    effectiveAccountId;
    isCustomer = false;

    label = {
        accountDetails: header.ACCOUNT_DETAILS,
        switchAccount: header.SWITCH_ACCOUNT,
        logout: header.LOGOUT,
        modalTitle: header.MODAL_TITLE,
        modalSubtitle: header.MODAL_SUBTITLE,
        confirm: global.CONFIRM,
        cancel: global.CANCEL,
        myReservations: header.MY_RESERVATIONS
    };

    /**
     * Verify if is a guest user.
     *
     * @returns {boolean} True if is a guest user.
     */
    get isGuest() {
        return isGuest;
    }

    /**
     * Get the logout link.
     *
     * @returns {string} The logout link.
     */
    get logoutLink() {
        const sitePrefix = basePath.replace(/\s$/i, '');
        return `${sitePrefix}/secur/logout.jsp?`;
    }

    /**
     * Getter for options.
     * Returns the list of account options.
     *
     * @type {Array<object>}
     */
    get managedAccounts() {
        return this._managedAccounts;
    }

    /**
     * Setter for options.
     * Returns the list of account options.
     *
     * @type {Array<object>}
     */
    set managedAccounts(data) {
        this._managedAccounts = data;
    }

    connectedCallback() {
        // Get Effective Account Id.
        getEffectiveAccountId({ userId: UserId })
            .then((data) => {
                if (data) {
                    this.effectiveAccountId = data;
                }
                // Get External Managed Accounts of User.
                return getExternalManagedAccounts({ communityId: this.communityId });
            })
            .then((data) => {
                if (data) {
                    this._managedAccounts = data.map((account) => ({ label: account.accountName, value: account.accountId }));
                }
            })
            .catch((error) => {
                console.log(error);
            });
    }

    // Wire adapter to fetch current user's information
    @wire(getRecord, { recordId: UserId, fields: [UserFirstName, UserLastName, UserProfile] })

    /**
     * Get Current USer Information and Set to display  in Lightning Component.
     *
     * @param {object} object - Object with the data received from request.
     */
    wiredCurrentUserInfo({ error, data }) {
        if (data) {
            this.firstName = data.fields.FirstName.value;
            this.lastName = data.fields.LastName.value;
            this.isCustomer = data.fields.Profile.value.fields.Name.value === COSTUMER_PROFILE;

            // Set user Name  as full name
            this.username = this.firstName + ' ' + this.lastName;
            this.setInitials();
        } else {
            console.log(error);
        }
    }

    /**
     * Handles the selection of an account.
     *
     * @param {Event} event - The event containing the selected account value.
     */
    handleOnChangeAccountSwitcher(event) {
        this.selectedEffectiveAccountId = event.detail.value;
    }

    /**
     * Handles the click event on the select button.
     * Update effectiveAccountId of User , after chose the Account.
     */
    handleOnClickConfirmAccount() {
        this._managedAccounts.find((option) => option.value === this.selectedEffectiveAccountId);

        // Update effectiveAccountId of User , after chose the Account
        switchAccount({ accountId: this.selectedEffectiveAccountId, userId: UserId })
            .then(() => {
                this.effectiveAccountId = this.selectedEffectiveAccountId;
                this.closeModal();
                window.location.reload();
            })
            .catch((error) => {
                console.log(error);
            });
    }

    /**
     * Set current account name's initials.
     */
    setInitials() {
        const name = this.username;

        if (name !== null) {
            const nameArray = name.split(' ');
            const firstName = nameArray[0].charAt(0).toUpperCase();
            const lastName = nameArray[nameArray.length - 1].charAt(0).toUpperCase();
            this.initials = firstName + lastName;
        }
    }

    /**
     * Toggles the account menu accordion display.
     */
    toggleAccordion() {
        const button = this.template.querySelector('.comm-header__button-account');

        if (button && button !== null && button.contains('.show')) {
            this.hideAccordion();
        } else {
            this.showAccordion();
        }
    }

    /**
     * Shows the account menu accordion.
     *
     */
    showAccordion() {
        const button = this.template.querySelector('.comm-header__button-account');

        if (button) button.classList.add('show');
    }

    /**
     * Hides the account menu accordion.
     */
    hideAccordion() {
        const button = this.template.querySelector('.comm-header__button-account');

        if (button && button !== null && button.classList.contains('show')) button.classList.remove('show');
    }

    /**
     * Open modal.
     *
     */
    openModal() {
        this.template.querySelector('c-comm_modal').open();
        this.hideAccordion();
    }

    /**
     * Close modal.
     *
     */
    closeModal() {
        this.template.querySelector('c-comm_modal').close();
    }

    /**
     * Redirect User to Account Management Page.
     */
    redirectToAccount() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Account_Management__c'
            }
        });
    }

    /**
     * Redirect User to My Reservations.
     *
     * @param {Event} event - The event to prevent the page to be oppened on another tab.
     */
    redirectToMyReservations(event) {
        event.preventDefault();
        if (this.myReservationsLink) {
            //Replace Default Language (pt_PT) in reservation link to current site language
            const reservationLinkWithLanguage = this.myReservationsLink.replaceAll('pt_PT', getLanguageCode(currentLanguage));
            window.location.href = reservationLinkWithLanguage;
        }
    }

    /**
     * If user type is Customer redirects to Commerce Logout Link
     * Else Redirects to Login Page using Logout Action.
     */
    redirectToLogout() {
        if (this.isCustomer) {
            //Replace language in logout link to pass language
            let logoutLinkWithLanguage = this.commerceLogoutLink?.replaceAll('pt_PT', getLanguageCode(currentLanguage));
            window.location.replace(logoutLinkWithLanguage);
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__loginPage',
                attributes: {
                    actionName: 'logout'
                }
            });
        }
    }
}