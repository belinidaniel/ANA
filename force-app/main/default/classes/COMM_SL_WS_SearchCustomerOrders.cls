/**
 * @author Daniel Reto
 * @description Class to support the Web Service to search for Orders data.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_SearchCustomerOrders {
    private static final String INVALID_ACCOUNTID_PARAMETER_ERROR = '\'accountId\' is a required parameter!';
    /**
     * @description Check if any Order record exists for the request filters.
     * @param COMM_WS_SearchOrdersInput inputRequest - Set of Filters to apply on the Order search
     * @return COMM_WS_SearchOrdersOutput output with list of Orders with the respective requested data
     */
    public COMM_WS_SearchOrdersOutput checkCustomerOrderExistence(COMM_WS_SearchOrdersInput inputRequest) {
        COMM_WS_SearchOrdersOutput outputRequest = new COMM_WS_SearchOrdersOutput();

        //check input request field values
        if (inputRequest.accountId == null) {
            throw new COMM_SL_WS_SearchCustomerOrdersException(INVALID_ACCOUNTID_PARAMETER_ERROR);
        }
        COMM_WS_SearchOrdersInput.checkInputRequestRules(inputRequest);

        String orderSummaryExtraFilter =
            'AccountId = \'' +
            inputRequest.accountId +
            '\'' +
            ((!String.IsEmpty(inputRequest.contactId)) ? (' AND BillToContactId = \'' + inputRequest.contactId + '\'') : '');

        // generate query with oupput required fields
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        List<OrderSummary> orderSummaryList = orderSummaryRep.getForSearchOrder(inputRequest, orderSummaryExtraFilter);

        COMM_WS_SearchOrdersOutput.buildOutputRequest(inputRequest, outputRequest, orderSummaryList);

        return outputRequest;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_SearchCustomerOrdersException extends Exception {
    }
}