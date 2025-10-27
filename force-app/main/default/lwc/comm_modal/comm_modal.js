/**
 * @file Class that manages comm_modal functionalities.
 */
import { LightningElement, api } from 'lwc';

export default class Comm_modal extends LightningElement {
    @api modalTitle;

    isModalOpen = false;

    /**
     * Open the modal.
     */
    @api open() {
        this.isModalOpen = true;
        document.body.style.overflow = 'hidden';
    }

    /**
     * Close the modal.
     */
    @api close() {
        this.isModalOpen = false;
        document.body.style.overflow = 'auto';
        this.dispatchEvent(new CustomEvent('close'));
    }
}