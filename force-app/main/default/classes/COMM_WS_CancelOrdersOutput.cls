/**
 * @author Daniel Reto
 * @description Model for full or partial cancellation of an order response.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_CancelOrdersOutput {
    global String errorMsg;
    global String errorCode;
    global Boolean success;
    global List<String> orderProductSummaryIds;
}