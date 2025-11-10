/**
 * @author Rui Salgado
 * @description CPMS Reservation Response model
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/
public with sharing class COMM_OMS_CPMSReservationResponse {
    public String reservationId { get; set; }
    public String cpmsReservationId { get; set; }
    public String barcodeType { get; set; }
    public String barcodeString { get; set; }
    public String resultCode { get; set; }
    public String resultDesc { get; set; }

    public static List<COMM_OMS_CPMSReservationResponse> parse(String json) {
        return (List<COMM_OMS_CPMSReservationResponse>) System.JSON.deserialize(json, List<COMM_OMS_CPMSReservationResponse>.class);
    }
}