/**
 * @file Class that manages comm_invoiceViewer functionalities.
 */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import getFileData from '@salesforce/apex/COMM_LCC_InvoiceViewer.getFileData';
import { global } from 'c/i18n';

export default class Comm_invoiceViewer extends LightningElement {
    @api recordId;
    isLoading = true;

    label = {
        toastPosition: global.TOAST_MESSAGE_POSITION_VARIANT
    };

    /**
     * Method invoked on quick action button press.
     * Calls server method to obtain fiscal document from SAP then opens obtained document in a new window.
     */
    @api invoke() {
        getFileData({ recordId: this.recordId })
            .then((result) => {
                var blob = this.base64toBlob(result, 'application/pdf');
                var blobURL = URL.createObjectURL(blob);
                window.open(blobURL);
            })
            .catch((error) => {
                console.log(error);

                //Prepare Toast Message and show error to User
                const toastContainer = ToastContainer.instance();
                toastContainer.maxShown = 1;
                toastContainer.toastPosition = this.label.toastPosition;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: error.body.message,
                        message: error.body.message,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Convert value in Base64 into a Blob.
     *
     * @param {string} base64Data - Data in Base64 to convert to Blob.
     * @param {string} contentType - Type of Content that is being converted into Blob.
     * @returns {Blob} Data in Blob format.
     */
    base64toBlob(base64Data, contentType) {
        contentType = contentType || '';
        const sliceSize = 1024;
        const byteCharacters = atob(base64Data);
        const bytesLength = byteCharacters.length;
        const slicesCount = Math.ceil(bytesLength / sliceSize);
        let byteArrays = new Array(slicesCount);

        for (let sliceIndex = 0; sliceIndex < slicesCount; ++sliceIndex) {
            const begin = sliceIndex * sliceSize;
            const end = Math.min(begin + sliceSize, bytesLength);

            let bytes = new Array(end - begin);
            for (let offset = begin, i = 0; offset < end; ++i, ++offset) {
                bytes[i] = byteCharacters[offset].charCodeAt(0);
            }
            byteArrays[sliceIndex] = new Uint8Array(bytes);
        }
        return new Blob(byteArrays, { type: contentType });
    }
}