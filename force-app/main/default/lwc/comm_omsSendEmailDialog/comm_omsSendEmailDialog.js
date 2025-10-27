/**
 * Modal controller for OMS.
 *
 * @file
 */
import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
export default class comm_OmsConfirmDialog extends LightningElement {
    _yesButtonClicked;
    _isModalOpen;
    @api text = 'Would you like to send the email to Customer?';
    @api title = 'Send Email to Customer';

    @api
    get yesButtonClicked() {
        return this._yesButtonClicked;
    }

    @api
    get isModalOpen() {
        return this._isModalOpen;
    }

    connectedCallback() {
        this.openModal();
    }

    openModal() {
        this._isModalOpen = true;
    }

    handleCancel() {
        this._isModalOpen = false;
        this._yesButtonClicked = false;
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleConfirm() {
        this._isModalOpen = false;
        this._yesButtonClicked = true;
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}