/**
 * @author Daniel Reto
 * @description Trigger worker that verifies if the Supplier Name for the Case
 * has a value, and fill ContactId with the respective ID.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/07/2024		Original version
 **/
public class COMM_TW_Case_FillContactFromSuppliedName {
    /**
     * @description Execute Trigger Worker Logic
     *
     * @param caseList List with the Case Records that are being created
     */
    public void execute(List<Case> caseList) {
        for (Case newCase : caseList) {
            if (newCase.SuppliedName != null && newCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COMM_AffiliateRequest').RecordTypeId) {
                newCase.ContactId = newCase.SuppliedName;
            }
        }
    }
}