({
    /**
     * Method invoked on quick action button press.
     * Calls server method to obtain fiscal document from SAP then opens obtained document in a new window.
     */
    invoke: function (component) {
        var action = component.get('c.getFileData'); // Apex method name
        action.setParams({ recordId: component.get('v.recordId') });

        // Set up the callback
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                var blob = this.base64toBlob(result, 'application/pdf');
                var blobURL = URL.createObjectURL(blob);
                window.open(blobURL);
                // Close the action panel
                var dismissActionPanel = $A.get('e.force:closeQuickAction');
                dismissActionPanel.fire();
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var errorMessage = errors && errors[0] && errors[0].message ? errors[0].message : 'Unknown error';

                // Show error toast to the user
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    title: errorMessage,
                    message: errorMessage,
                    type: 'error',
                    mode: 'dismissable'
                });
                toastEvent.fire();

                // Close the action panel
                var dismissActionPanel = $A.get('e.force:closeQuickAction');
                dismissActionPanel.fire();
            }
            component.set('v.isLoading', false);
        });

        // Enqueue the action
        $A.enqueueAction(action);
    },

    /**
     * Convert value in Base64 into a Blob.
     *
     * @param {string} base64Data - Data in Base64 to convert to Blob.
     * @param {string} contentType - Type of Content that is being converted into Blob.
     * @returns {Blob} Data in Blob format.
     */
    base64toBlob: function (base64Data, contentType) {
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
});