/**
 * @file File that manages comm_screenFlowReadOnlyField functionalities.
 * It will display the chosen field as Ready Only on a Screen Flow Form
 */

import { LightningElement, api } from 'lwc';

export default class Comm_screenFlowReadOnlyField extends LightningElement {
    @api fieldLabel;
    @api fieldValue;
    @api fieldType;
    @api fieldLevelHelp;

   isCheckboxField = false;

   connectedCallback() {
        if (this.fieldType != null && (this.fieldType=='toggle' ||  this.fieldType=='checkbox' )) {
            this.isCheckboxField = true;
        }
    }
}