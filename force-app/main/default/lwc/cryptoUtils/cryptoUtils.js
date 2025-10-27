/**
 * @file Utils with methods used with Crypto Module.
 */

/**
 * Method to convert an ArrayBuffer value to base64.
 *
 * @param {*} buffer Value to be converted.
 * @returns {*} Converted value.
 */
function arrayBufferToBase64(buffer) {
    let binary = '';
    const bytes = new Uint8Array(buffer);
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary);
}

/**
 * Method to convert a base64 value to an ArrayBuffer.
 *
 * @param {*} base64 Value to be converted.
 * @returns {*} Converted value.
 */
function base64ToArrayBuffer(base64) {
    var binaryString = atob(base64);
    var bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

/**
 * Method to convert key data from server into a Crypto AES Key to encrypt data.
 *
 * @param {*} data Key data to convert into a Crypto AES Key.
 * @returns {Promise} Promise with the Cripto AES Key.
 */
function getCriptoKeyFromData(data) {
    return crypto.subtle.importKey('raw', this.base64ToArrayBuffer(data), 'AES-CBC', false, ['encrypt']);
}

/**
 * Method to encrypt a message using an Crypto AES Key.
 *
 * @param {*} message Message to be encrypted.
 * @param {*} aesKey Crypto AES Key used to encrypt message.
 * @returns {string} Encrypted Message.
 */
async function encryptMessage(message, aesKey) {
    const newIv = window.crypto.getRandomValues(new Uint8Array(16));
    let encryptedMessage = await window.crypto.subtle.encrypt(
        {
            name: 'AES-CBC',
            iv: newIv
        },
        aesKey,
        new TextEncoder().encode(message)
    );

    // Combine the IV and encrypted data
    const combined = new Uint8Array(newIv.byteLength + encryptedMessage.byteLength);
    combined.set(newIv);
    combined.set(new Uint8Array(encryptedMessage), newIv.byteLength);

    // Convert to base64 for transmission
    return this.arrayBufferToBase64(combined);
}

export { arrayBufferToBase64, base64ToArrayBuffer, getCriptoKeyFromData, encryptMessage };