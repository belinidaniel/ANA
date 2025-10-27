/**
 * @author Diogo Gonçalves
 * @description Pricebook repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  22/05/2024       Original version
 **/
public interface COMM_IREP_Pricebook extends FW_ISObjectRep {
    /**
     * @description Retrieve the standard pricebook
     *
     * @return standard pricebook object
     **/
    Pricebook2 getStandardPricebook();
}