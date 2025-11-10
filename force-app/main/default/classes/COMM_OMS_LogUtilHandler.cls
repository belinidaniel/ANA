/**
 * @author Rui Salgado
 * @description COMM_OMS_Log__c Handler util class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/
public with sharing virtual class COMM_OMS_LogUtilHandler {
    /**
     * @description Creates errors from result and adds to the logs list
     * @param errors Errors
     */
    public static void createEmailErrorsAsLogs(Messaging.SendEmailError[] errors) {
        for (Database.Error error : errors) {
            COMM_OMS_LogUtil.createErrorLog(String.valueOf(error.getStatusCode()), error.getMessage());
        }
    }

    /**
     * @description Creates errors from result and adds to the logs list
     * @param errors Errors
     */
    public static void createConnectApiErrorsAsLogs(ConnectApi.ErrorResponse[] errors) {
        for (ConnectApi.ErrorResponse error : errors) {
            COMM_OMS_LogUtil.createErrorLog(error.errorCode, error.message);
        }
    }
}