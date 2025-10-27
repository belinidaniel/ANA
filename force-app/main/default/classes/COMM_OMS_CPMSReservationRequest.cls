/**
 * @author Rui Salgado
 * @description CPMS Reservation Request model
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/

public with sharing class COMM_OMS_CPMSReservationRequest {
    public class Contact {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String telephone { get; set; }
        public String email { get; set; }
    }
    public class PrepaidFee {
        public Double amount { get; set; }
        public String currencyCode { get; set; }
    }
    public String cpms { get; set; }
    public String reservationId { get; set; }
    public String cpmsReservationId { get; set; }
    public String aeroportId { get; set; }
    public String carParkId { get; set; }
    //public Datetime validFrom { get; set; }
    //public Datetime validTo { get; set; }
    public String validFrom { get; set; }
    public String validTo { get; set; }
    public String barcodeType { get; set; }
    public String barcodeString { get; set; }
    public Contact contact { get; set; }
    public PrepaidFee prepaidFee { get; set; }

    public static List<COMM_OMS_CPMSReservationRequest> parse(String json) {
        return (List<COMM_OMS_CPMSReservationRequest>) System.JSON.deserialize(json, List<COMM_OMS_CPMSReservationRequest>.class);
    }
}