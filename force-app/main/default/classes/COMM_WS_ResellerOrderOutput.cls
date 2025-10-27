/**
 * @author Diogo Gonçalves
 * @description Model for Create Reseller Order response
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      06/05/2024       Original version
 **/
public class COMM_WS_ResellerOrderOutput {
    public String orderId { get; set; }

    public COMM_WS_ResellerOrderOutput(String orderId) {
        this.orderId = orderId;
    }
}