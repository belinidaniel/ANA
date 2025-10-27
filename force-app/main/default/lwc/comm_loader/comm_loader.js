/**
 * @file Class that manages comm_loader functionalities.
 */
import { LightningElement, api } from 'lwc';

const SHOW_LOADER = 'comm-loader';
const HIDE_LOADER = 'comm-loader comm-loader__hidden';

export default class Comm_loader extends LightningElement {
    /**
     * Represents whether the loader is displayed or not.
     *
     * @returns {string} Class to display.
     */
    @api
    get isLoading() {
        return this._isLoading;
    }
    set isLoading(data) {
        this._isLoading = data === true ? SHOW_LOADER : HIDE_LOADER;
    }

    _isLoading = HIDE_LOADER;
}