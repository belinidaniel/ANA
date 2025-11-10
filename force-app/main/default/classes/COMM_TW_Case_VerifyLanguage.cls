/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if the language selected for the Case
 * is a value used in Salesforce (ex: Commerce used en_PT, Salesforce is en_US)
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    25/03/2024		Original version
 **/
public class COMM_TW_Case_VerifyLanguage {
    private COMM_IDO_LanguageMapping languageDO;

    /**
     * @description Class Constructor to initiate REP Classes
     */
    public COMM_TW_Case_VerifyLanguage() {
        this.languageDO = new COMM_DO_LanguageMapping();
    }

    @TestVisible
    private COMM_TW_Case_VerifyLanguage(COMM_IDO_LanguageMapping languageDO) {
        this.languageDO = languageDO;
    }

    /**
     * @description Execute Trigger Worker Logic
     *
     * @param caseList List with the Case Records that are being created
     */
    public void execute(List<Case> caseList) {
        for (Case newCase : caseList) {
            if (newCase.COMM_Language__c != null) {
                newCase.COMM_Language__c = languageDO.getSalesforceLanguage(newCase.COMM_Language__c);
            }
        }
    }
}