/**
 * @author Diogo Gonçalves
 * @description COMM_OMS_ReservationEmailBCC__mdt repo class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  09/09/2024       Original version
 **/
public with sharing class COMM_REP_ReservationEmailBCCMdt extends FW_SobjectRep implements COMM_IREP_ReservationEmailBCCMdt {
    /**
     * Get all COMM_OMS_ReservationEmailBCC__mdt records
     * @return List<String>
     */
    public static List<String> getAllEmails() {
        Map<String, COMM_OMS_ReservationEmailBCC__mdt> bccEmailsMap;
        if (Test.isRunningTest()) {
            bccEmailsMap = new Map<String, COMM_OMS_ReservationEmailBCC__mdt>{
                'Test_Email' => new COMM_OMS_ReservationEmailBCC__mdt(COMM_Email__c = 'test@ana.pt')
            };
        } else {
            bccEmailsMap = COMM_OMS_ReservationEmailBCC__mdt.getAll();
        }
        return COMM_GEN_Utility.getTextFieldValues(bccEmailsMap.values(), 'COMM_Email__c');
    }
}