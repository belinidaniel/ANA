/**
 * @author Ricardo Dias
 * @description Pricebook Entry repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias     23/02/2024        Original version
 * Daniel Lascas    10/04/2024       ECOMM-194: Added getCardPBEByIds method
 * Daniel Reto      01/05/2024       ECOMM-997: Added getPBEByProductCodeDataBaseQueryList method
 **/
public interface COMM_IREP_PricebookEntry extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Pricebook Entries by a set of Product Codes
     *
     * @param productCodesSet Set of Product Codes to query
     * @return List of Pricebook Entry Records found
     **/
    List<PricebookEntry> getPBEByProductCodeList(Set<String> productCodesSet);
    /**
     * @description Retrieve a list of Valid(Valid From <= NOW AND Valid To >= NOW) Active Pricebook Entries by a set of Product Codes and Pricebooks
     *
     * @param productCodesSet Set of Product Codes to query
     * @param pricebookIdSet Set of Pricebook Ids to query
     * @return List of Pricebook Entry Records found
     **/
    List<PricebookEntry> getPBEByProductCodeList(Set<String> productCodesSet, Set<Id> pricebookIdSet);
    /**
     * @description Retrieve a list of Active Pricebook Entries for Card Products by a set of Ids
     *
     * @param cardProductIds Set of Card Product Ids to query
     * @return List of Pricebook Entry Records found for Card Products
     **/
    List<PricebookEntry> getCardPBEByIds(Set<Id> cardProductIds);
    /**
     * @description Retrieve a list of Pricebook Entries by a set of Product Codes using Database.query()
     *
     * @param productCodesSet Set of Product Codes to query
     * @return List of Pricebook Entry Records found
     **/
    List<PricebookEntry> getPBEByProductCodeDataBaseQueryList(Set<String> productCodesSet);
    /**
     * @description Retrieve a list of Pricebook Entries by a set of Product Ids and Pricebook Ids
     *
     * @param productIds Set of Product Ids to query
     * @param pricebookIds Set of Pricebook Ids to query
     * @return List of Pricebook Entry Records found
     **/
    List<PricebookEntry> getPBEByProductAndPricebookIds(Set<Id> productIds, Set<Id> pricebookIds);
}