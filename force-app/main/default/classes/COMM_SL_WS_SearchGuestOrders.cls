/**
 * @author Daniel Reto
 * @description Class to support the Web Service to search for guest Orders data.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_SearchGuestOrders {
    private static final String INVALID_EMAIL_PARAMETER_ERROR = '\'email\' is a required parameter!';
    private static final String INVALID_ZIPCODE_PARAMETER_ERROR = '\'zipCode\' is a required parameter!';
    private static final String INVALID_ORDERNUMBER_PARAMETER_ERROR = '\'orderNumber\' is a required parameter!';
    /**
     * @description Check if any Order record exists for the request filters.
     * @param COMM_WS_SearchOrdersInput inputRequest - Set of Filters to apply on the Order search
     * @return COMM_WS_SearchOrdersOutput output with list of Orders with the respective requested data
     */
    public COMM_WS_SearchOrdersOutput checkGuestOrderExistence(COMM_WS_SearchOrdersInput inputRequest) {
        COMM_WS_SearchOrdersOutput outputRequest = new COMM_WS_SearchOrdersOutput();

        //check input request field values
        if(inputRequest.email == null){
            throw new COMM_SL_WS_SearchGuestOrdersException(INVALID_EMAIL_PARAMETER_ERROR);
        }
        if(inputRequest.zipCode == null){
            throw new COMM_SL_WS_SearchGuestOrdersException(INVALID_ZIPCODE_PARAMETER_ERROR);
        }
        if(inputRequest.orderNumber == null){
            throw new COMM_SL_WS_SearchGuestOrdersException(INVALID_ORDERNUMBER_PARAMETER_ERROR);
        }
        COMM_WS_SearchOrdersInput.checkInputRequestRules(inputRequest);

        String orderSummaryExtraFilter = 'BillingEmailAddress = \'' + inputRequest.email + '\' AND BillingPostalCode = \'' + inputRequest.zipCode + '\'';

        // generate query with oupput required fields
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        List<OrderSummary> orderSummaryList = orderSummaryRep.getForSearchOrder(inputRequest, orderSummaryExtraFilter);

        COMM_WS_SearchOrdersOutput.buildOutputRequest(inputRequest, outputRequest, orderSummaryList);

        return outputRequest;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_SearchGuestOrdersException extends Exception {
    }
}