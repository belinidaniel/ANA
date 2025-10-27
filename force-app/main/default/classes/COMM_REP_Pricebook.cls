/**
 * @author Diogo Gonçalves
 * @description Pricebook repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    25/03/2024       Original version
 **/
public inherited sharing class COMM_REP_Pricebook extends FW_SobjectRep implements COMM_IREP_Pricebook {
    /**
     * @description Retrieve the standard pricebook
     *
     * @return standard pricebook object
     **/
    public Pricebook2 getStandardPricebook() {
        List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE WITH USER_MODE];
        if (!standardPricebooks.isEmpty()) {
            return standardPricebooks[0];
        } else {
            return null;
        }
    }
}