/**
 * @author Daniel Reto
 * @description Model for search Customer and Guest orders request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_SearchOrdersInput {
    global String accountId;
    global String contactId;
    global Integer page;
    global Integer pageSize;
    global Date orderStartDate;
    global Date orderEndDate;
    global Date reservationStartDate;
    global Date reservationEndDate;
    global String orderNumber;
    global String affiliateNumber;
    global String licensePlate;
    global String secondaryLicensePlate;
    global List<String> productTypes;
    global List<String> airports;
    global List<Integer> status;
    global String email;
    global String zipCode;

    public static COMM_WS_SearchOrdersInput parse(String json) {
        return (COMM_WS_SearchOrdersInput) System.JSON.deserialize(json, COMM_WS_SearchOrdersInput.class);
    }

    private static final String INVALID_ORDERDATE_PARAMETER_ERROR = 'When \'orderStartDate\' or \'orderEndDate\' are set, both parameters are required!';
    private static final String INVALID_ORDERSTARTDATE_PARAMETER_ERROR = '\'orderStartDate\' must be equal or greater than \'orderEndDate\'!';
    private static final String INVALID_RESERVATIONDATE_PARAMETER_ERROR = 'When \'reservationStartDate\' or \'reservationEndDate\' are set, both parameters are required!';
    private static final String INVALID_RESERVATIONSTARTDATE_PARAMETER_ERROR = '\'reservationStartDate\' must be equal or greater than \'reservationEndDate\'!';
    /**
     * @description Check Input request exceptions.
     * @param  COMM_WS_SearchOrdersInput inputRequest - Input request received
     */
    public static void checkInputRequestRules(COMM_WS_SearchOrdersInput inputRequest) {
        if (
            (inputRequest.orderStartDate == null && inputRequest.orderEndDate != null) ||
            (inputRequest.orderStartDate != null &&
            inputRequest.orderEndDate == null)
        ) {
            throw new COMM_SL_WS_SearchCustomerOrdersException(INVALID_ORDERDATE_PARAMETER_ERROR);
        }
        if (inputRequest.orderStartDate > inputRequest.orderEndDate) {
            throw new COMM_SL_WS_SearchCustomerOrdersException(INVALID_ORDERSTARTDATE_PARAMETER_ERROR);
        }
        if (
            (inputRequest.reservationStartDate == null && inputRequest.reservationEndDate != null) ||
            (inputRequest.reservationStartDate != null &&
            inputRequest.reservationEndDate == null)
        ) {
            throw new COMM_SL_WS_SearchCustomerOrdersException(INVALID_RESERVATIONDATE_PARAMETER_ERROR);
        }
        if (inputRequest.reservationStartDate > inputRequest.reservationEndDate) {
            throw new COMM_SL_WS_SearchCustomerOrdersException(INVALID_RESERVATIONSTARTDATE_PARAMETER_ERROR);
        }
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_SearchCustomerOrdersException extends Exception {
    }
}