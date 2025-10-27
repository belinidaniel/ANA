/**
 * @author           Daniel Reto
 * @description      Order Item Summary SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      28/06/2024       Original version
 **/
public inherited sharing class COMM_DO_OrderItemSummary implements COMM_IDO_OrderItemSummary {
    //Case Status Picklist Values
    public final static string ORDERED_STATUS = 'ORDERED';
    public final static string FULFILLED_STATUS = 'FULFILLED';
    public final static string RETURNED_STATUS = 'RETURNED';

    /**
     * @description Get correct API values of Order Summay Status.
     * @param String statusCode - Status Code value
     * @return Integer with the correct Status Code API values
     */
    public static Integer getFilterStatusCodes(String statusCode) {
        Map<String, Integer> statusCodeMap = new Map<String, Integer>{
            COMM_DO_OrderItemSummary.ORDERED_STATUS => 1,
            COMM_DO_OrderItemSummary.FULFILLED_STATUS => 2,
            COMM_DO_OrderItemSummary.RETURNED_STATUS => 3
        };

        return statusCodeMap.get(statusCode);
    }
}