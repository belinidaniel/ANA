/**
 * @file Navigation Menu.
 */

import { global } from 'c/i18n';
import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getNavigationMenuItems from '@salesforce/apex/COMM_LCC_NavigationMenuItemsController.getNavigationMenuItems';

/**
 * This is a custom LWC navigation menu component.
 * Make sure the Guest user profile has access to the COMM_LCC_NavigationMenuItemsController apex class.
 */
export default class Comm_navigationMenu extends LightningElement {
    /**
     * The label or name of the nav menu linkset (NavigationMenuLinkSet.MasterLabel) exposed by the .js-meta.xml,
     * used to look up the NavigationMenuLinkSet.DeveloperName.
     */
    @api linkSetMasterLabel;

    /**
     * Include the Home menu item, if true.
     */
    @api addHomeMenuItem = false;

    /**
     * Include image URLs in the response, if true
     * useful for building a tile menu with images.
     */
    @api includeImageUrls = false;

    /**
     * The menu items when fetched by the NavigationItemsController.
     */
    @track menuItems = [];

    /**
     * If the items have been loaded.
     */
    @track isLoaded = false;

    /**
     * The error if it occurs.
     */
    @track error;

    timer;

    label = {
        seeMore: global.SEE_MORE
    };

    /**
     * The published state of the site, used to determine from which schema to
     * fetch the NavigationMenuItems.
     */
    publishStatus;

    @wire(getNavigationMenuItems, {
        navigationLinkSetMasterLabel: '$linkSetMasterLabel',
        publishStatus: '$publishStatus',
        addHomeMenuItem: '$addHomeMenuItem',
        includeImageUrl: '$includeImageUrls'
    })

    /**
     * Handles the request from the wire service.
     *
     * @param {object} object - Object with the data received from request.
     */
    wiredMenuItems({ error, data }) {
        if (data && !this.isLoaded) {
            this.menuItems = data.map((item, index) => {
                return {
                    target: item.actionValue,
                    id: index,
                    label: item.label.replaceAll('&#39;', "'").replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>'),
                    type: item.actionType,
                    subMenu: item.subMenu,
                    imageUrl: item.imageUrl,
                    windowName: item.target
                };
            });
            this.error = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.error = error;
            this.menuItems = [];
            this.isLoaded = true;
            console.error(`Navigation menu error: ${JSON.stringify(this.error)}`);
        }
    }

    @wire(CurrentPageReference)

    /**
     * Handles the request from the wire service.
     *
     * @param {object} currentPageReference - Object with the data received from request.
     */
    setCurrentPageReference(currentPageReference) {
        const app = currentPageReference && currentPageReference.state && currentPageReference.state.app;
        if (app === 'commeditor') {
            this.publishStatus = 'Draft';
        } else {
            this.publishStatus = 'Live';
        }
    }

    connectedCallback() {
        window.addEventListener('resize', this.onResize);
    }

    renderedCallback() {
        this.addHomeButton();
        this.detectOverflow();
    }

    /**
     * Detects Hidden menu Items and styles them accordingly.
     */
    detectOverflow() {
        const items = this.template.querySelectorAll('ul li');

        for (let i = 0; i < 2; i++) {
            for (let index = 0; index < items.length; index++) {
                const item = items[index];

                if (item.offsetTop > 0) {
                    item.classList.add('is-overflown');
                } else {
                    item.classList.remove('is-overflown');
                }
            }
        }
    }

    /**
     * Triggered on resize.
     */
    onResize = () => {
        clearTimeout(this.timer);

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timer = setTimeout(() => {
            this.detectOverflow();
        }, 300);
    };

    /**
     * Toggles visibility of hidden items.
     */
    toggleSeeMore() {
        const nav = this.template.querySelector('ul');

        if (nav) {
            nav.classList.toggle('is-overflow');
        }
    }

    /**
     * Toggles visibility of menu in mobile.
     */
    toggleMenu() {
        const menu = this.template.querySelector('.navbar');

        if (menu) {
            menu.classList.toggle('is-opened');
        }
    }

    /**
     * Hide See More visibility of menu in mobile.
     */
    hideSeeMore() {
        const nav = this.template.querySelector('ul');

        if (nav) {
            nav.classList.remove('is-overflow');
        }
    }

    /**
     * Hide visibility of menu.
     */
    hideMenu() {
        const menu = this.template.querySelector('.navbar');

        if (menu) {
            menu.classList.remove('is-opened');
            this.hideSeeMore();
        }
    }

    /**
     * Adds Home button icon when Home item is enabled.
     */
    addHomeButton() {
        const nav = this.template.querySelector('ul li:first-child');

        if (this.addHomeMenuItem && nav) {
            nav.classList.add('has-home-menu');
        } else {
            nav.classList.remove('has-home-menu');
        }
    }
}