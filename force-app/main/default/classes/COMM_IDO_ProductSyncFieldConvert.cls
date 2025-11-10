/**
 * @author Daniel Lascas
 * @description COMM_ProductSynchronizationFieldConvert__mdt Domain object interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/04/2024       ECOMM-808: Original version
 **/
public interface COMM_IDO_ProductSyncFieldConvert {
    /**
     * @description Verify if Map contains values to be converted based on Custom Metadata
     *
     * @param valueMap Map to verify if it contains values to be converted
     * @return Map with converted values
     */
    Map<String, Object> verifyValueConversion(Map<String, Object> valueMap);
}