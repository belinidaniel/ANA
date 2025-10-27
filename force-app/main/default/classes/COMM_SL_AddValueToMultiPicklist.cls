/**
 * @author Daniel Lascas
 * @description Service Layer class to add a value to a multipicklist.
 * For use in Flows.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/04/2024       ECOMM-369: Original version
 **/
public with sharing class COMM_SL_AddValueToMultiPicklist {
    /**
     * @description Invocable Method for use in Flows. Used to add a value to a multi-picklist
     *
     * @param wrapperList Input Wrapper to receive from Flow
     * @return Updated Multi-picklist value
     */
    @InvocableMethod(
        label='Add value to multi-picklist'
        description='Action to add a value to a multi-picklist and return it as text'
        category='Custom Actions'
    )
    public static List<String> addValueToMultiPicklist(List<InputWrapper> wrapperList) {
        if (wrapperList != null && !wrapperList.isEmpty()) {
            String valueToAdd = wrapperList[0].valueToAdd;
            //Convert Multi-picklist to Set to ensure no duplicate values
            Set<String> multiPicklistValue = new Set<String>(wrapperList[0].multiPicklistValue.split(';'));
            //Add Value then convert list to multi-picklist value
            multiPicklistValue.add(valueToAdd);
            return new List<String>{ String.join(multiPicklistValue, ';') };
        }
        return new List<String>{ '' };
    }

    /**
     * @description Wrapper for Input to receive from Flow
     * @param valueToAdd Value to add to multi-picklist
     * @param multiPicklistValue Current Value of Multi-Picklist to be updated
     */
    public class InputWrapper {
        @InvocableVariable
        public String valueToAdd;
        @InvocableVariable
        public String multiPicklistValue;
    }
}