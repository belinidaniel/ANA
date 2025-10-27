/**
 * @author Jose Passos
 * @description Model for reservation response.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos    11/03/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_ReservationOutput {
    public String actionRequestId;
    public String productId;
    public Double price;
    public Datetime startDate;
    public Datetime endDate;

    public static List<COMM_WS_ReservationOutput> parse(String json) {
        return (List<COMM_WS_ReservationOutput>) System.JSON.deserialize(json, List<COMM_WS_ReservationOutput>.class);
    }
}