/**
 * @author Jose Passos
 * @description OCI exception class to get the error message linked to the OCI error code
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 **/
public inherited sharing class COMM_WS_OCIException extends Exception {
    public String errorCode { get; set; }

    /**
     * Contructor to translate the erroCode to the respective errorMessage
     * @param String errorCode
     * @param String errordetails - additional details to append to error message
     */
    public COMM_WS_OCIException(String errorCode, String errordetails) {
        this(COMM_OCI_Constants.OCI_ERROR_CODES.get(errorCode));
        this.errorCode = errorCode;
        if (errordetails != null) {
            this.setMessage(this.getMessage() + ' ' + errordetails);
        }
    }
}