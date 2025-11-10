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
public class COMM_REP_ProductSetting extends FW_SobjectRep implements COMM_IREP_ProductSetting{

    /**
     * @description Get all records marked as Essential for Core on the COMM_ProductSetting__c.
     *
     * @return List with all records marked as Essential for Core on the COMM_ProductSetting__c
     */
    public List<COMM_ProductSetting__c> getCoreEssentialFields(){
        return [SELECT Name,COMM_FieldName__c,COMM_CoreEssential__c, COMM_CommerceMappingAttribute__c,
                COMM_EligibleProductType__c, COMM_FieldAPIName__c
                FROM COMM_ProductSetting__c
                WHERE COMM_CoreEssential__c = TRUE
                WITH USER_MODE];
    }
    
    /**
     * @description Get all records marked as Essential for Commerce on the COMM_ProductSetting__c.
     *
     * @return List with all records marked as Essential for Commerce on the COMM_ProductSetting__c
     */
    public List<COMM_ProductSetting__c> getCommerceEssentialFields(){
        return [SELECT Name,COMM_FieldName__c, COMM_CommerceEssential__c, COMM_CommerceMappingAttribute__c,
                COMM_EligibleProductType__c, COMM_FieldAPIName__c
                FROM COMM_ProductSetting__c
                WHERE COMM_CommerceEssential__c = TRUE
				WITH USER_MODE];
    }
    
    /**
     * @description Get the values of the custom field from COMM_ProductSetting__c.
     *
     * @return List with all records with the values of the custom field from COMM_ProductSetting__c
     */
    public List<COMM_ProductSetting__c> getFieldAPINames(){
        return [SELECT Id,
                COMM_FieldAPIName__c
                FROM COMM_ProductSetting__c
                WITH USER_MODE];
    }
}