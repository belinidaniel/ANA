/**
 * @author Diogo Gonçalves
 * @description Reseller Order exception class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  06/05/2024       Original version
 **/
public inherited sharing class COMM_SL_ResellerOrderException extends Exception {
    public String errorCode { get; set; }

    public COMM_SL_ResellerOrderException(String errorCode, String errorMessage) {
        this(errorMessage);
        this.errorCode = errorCode;
    }
}