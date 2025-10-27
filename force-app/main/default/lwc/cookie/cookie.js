/* eslint-disable */

/**
 * Set a new cookie.
 *
 * @param {string} cname - The cookie name.
 * @param {string} cvalue  - The cookie value.
 * @param {number} exminutes - Number of minutes.
 */
const setCookie = (cname, cvalue, exminutes) => {
    const d = new Date();
    d.setTime(d.getTime() + exminutes * 60 * 1000);
    const expires = 'expires=' + d.toUTCString();
    document.cookie = cname + '=' + cvalue + ';' + expires + ';path=/';
};

/**
 * Get the cookie value.
 *
 * @param {string} cname - The cookie name.
 * @returns {string} The cookie value.
 */
const getCookie = (cname) => {
    const name = cname + '=';
    const ca = document.cookie.split(';');
    for (let i = 0; i < ca.length; i++) {
        let c = ca[i];

        while (c.charAt(0) === ' ') {
            c = c.substring(1);
        }

        if (c.indexOf(name) === 0) {
            return c.substring(name.length, c.length);
        }
    }
    return null;
};

/**
 * Erase a cookie.
 *
 * @param {string} cname - The cookie name.
 */
const deleteCookie = (cname) => {
    const d = new Date();
    d.setTime(d.getTime() + -1 * 60 * 1000);
    const expires = 'expires=' + d.toUTCString();
    document.cookie = cname + '=;' + expires + ';path=/';
};

export { setCookie, getCookie, deleteCookie };