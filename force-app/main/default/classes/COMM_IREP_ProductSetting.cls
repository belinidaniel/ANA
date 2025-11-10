/**
 * @author Ruben Rodrigues
 * @description COMM_ProductSetting__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues    21/05/2024       Original version
 **/
public interface COMM_IREP_ProductSetting extends FW_ISObjectRep{

    /**
     * @description Get ProductSetting records
     *
     * @return Result List with ProductSetting records to process
     */
    List<COMM_ProductSetting__c> getCoreEssentialFields();
    List<COMM_ProductSetting__c> getCommerceEssentialFields();
    List<COMM_ProductSetting__c> getFieldAPINames();
}