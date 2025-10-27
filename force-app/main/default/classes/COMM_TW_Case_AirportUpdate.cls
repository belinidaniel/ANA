/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the multi-picklist COMM_Airport__c
 * was changed. If it was copy value to COMM_AirportTextList__c to update sharing.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    11/07/2024		ECOMM-1602: CR-33
 **/
public with sharing class COMM_TW_Case_AirportUpdate {
    /**
     * @description Execute Trigger Worker Logic.
     *
     * @param newCaseList List with the Case Records in after context.
     * @param oldCaseMap Map with the Case Records in before context.
     */
    public void execute(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        for (Case newCase : newCaseList) {
            //Verify Airport Field Changed
            if (COMM_GEN_Utility.isChangedField(newCase, oldCaseMap, Case.COMM_Airport__c)) {
                newCase.COMM_AirportTextList__c = newCase.COMM_Airport__c;
            }
        }
    }
}