/**
 * @author Daniel Reto
 * @description Model for full or partial cancellation of an order request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_CancelOrdersInput {
    global String accountId;
    global String email;
    global String orderNumber;
    global String orderSummaryId;
    global Boolean partial;
    global List<String> orderProductSummaryIds;

    public static COMM_WS_CancelOrdersInput parse(String json) {
        return (COMM_WS_CancelOrdersInput) System.JSON.deserialize(json, COMM_WS_CancelOrdersInput.class);
    }
}