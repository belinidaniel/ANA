/**
 * @author Diogo Gonçalves
 * @description COMM_QRCodePrefixMdt__mdt util class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      18/10/2024       Original version
 **/

 public class COMM_REP_QRCodePrefixMdt implements COMM_IREP_QRCodePrefixMdt {
    /**
     * Get COMM_QRCodePrefix__mdt records by instanceName
     * @param instanceName
     * @return COMM_QRCodePrefix__mdt
     */
    public COMM_QRCodePrefix__mdt getQRCodePrefix(String instanceName){
        if (Test.isRunningTest()) {
            COMM_QRCodePrefix__mdt qrCodePrefix = new COMM_QRCodePrefix__mdt();
            qrCodePrefix.COMM_Prefix__c = 'GWP';
            return qrCodePrefix;
        }

        return COMM_QRCodePrefix__mdt.getInstance(instanceName);
    }
}