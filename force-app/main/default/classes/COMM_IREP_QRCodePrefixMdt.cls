/**
 * @author Diogo Gonçalves
 * @description COMM_QRCodePrefixMdt__mdt util interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      18/10/2024       Original version
 **/

 public interface COMM_IREP_QRCodePrefixMdt {
    /**
     * Get COMM_QRCodePrefix__mdt records by instanceName
     * @param instanceName
     * @return COMM_QRCodePrefix__mdt
     */
    COMM_QRCodePrefix__mdt getQRCodePrefix(String instanceName);
}