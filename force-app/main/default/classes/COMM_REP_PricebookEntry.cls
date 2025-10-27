/**
 * @author Ricardo Dias
 * @description Pricebook Entry repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date                Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias     23/02/2024          Original version
 * Ricardo Dias     08/04/2024          Update getPBEByProductCodeList where clause
 * Daniel Lascas    10/04/2024          ECOMM-194: Added getCardPBEByIds method
 * Daniel Reto      01/05/2024          ECOMM-997: Added getPBEByProductCodeDataBaseQueryList method
 * Daniel Reto      29/05/2024          PDM warning messages fix
 **/
public inherited sharing class COMM_REP_PricebookEntry extends FW_SobjectRep implements COMM_IREP_PricebookEntry {
    public static final String publicType = COMM_GEN_Utility.TYPE_PUBLIC;

    /**
     * @description Retrieve a list of Valid(Valid From <= NOW AND Valid To >= NOW) Active Pricebook Entries by a set of Product Codes
     *
     * @param productCodesSet Set of Product Codes to query
     * @return List of Pricebook Entry Records found
     **/
    public List<PricebookEntry> getPBEByProductCodeList(Set<String> productCodesSet) {
        return [
            SELECT
                Id,
                ProductCode,
                Pricebook2.Id,
                Pricebook2.IsStandard,
                Pricebook2.Name,
                UnitPrice,
                Product2Id,
                Pricebook2.COMM_ValidFrom__c,
                Pricebook2.COMM_ValidTo__c,
                Product2.COMM_Tax__c,
                Product2.Family,
                Product2.Name,
                Product2.COMM_Periodicity__c,
                Product2.ProductCode,
                Product2.COMM_SubCategory__c,
                Product2.COMM_Airport__c,
                Pricebook2Id,
                COMM_First15MinuteUnit__c,
                COMM_Second15MinuteUnit__c,
                COMM_Third15MinuteUnit__c,
                COMM_Remaining15MinuteUnit__c,
                COMM_FirstPeriodStartDay__c,
                COMM_FirstPeriodEndDay__c,
                COMM_FirstPeriodDailyMaximum__c,
                COMM_SecondPeriodStartDay__c,
                COMM_SecondPeriodEndDay__c,
                COMM_SecondPeriodDailyMaximum__c,
                COMM_ThirdPeriodStartDay__c,
                COMM_ThirdPeriodEndDay__c,
                COMM_ThirdPeriodDailyMaximum__c,
                COMM_FourthPeriodStartDay__c,
                COMM_FourthPeriodEndDay__c,
                COMM_FourthPeriodDailyMaximum__c
            FROM PricebookEntry
            WHERE
                ProductCode IN :productCodesSet
                AND IsActive = TRUE
                AND Pricebook2.Type__c INCLUDES (:COMM_GEN_Utility.TYPE_PUBLIC)
                AND Pricebook2.IsActive = TRUE
                AND Pricebook2.COMM_ValidFrom__c <= :system.now()
                AND Pricebook2.COMM_ValidTo__c >= :system.now()
            WITH USER_MODE
            ORDER BY Pricebook2.IsStandard ASC, Pricebook2.COMM_ValidFrom__c DESC
        ];
    }

    /**
     * @description Retrieve a list of Valid(Valid From <= NOW AND Valid To >= NOW) Active Pricebook Entries by a set of Product Codes and Pricebooks
     *
     * @param productCodesSet Set of Product Codes to query
     * @param pricebookIdSet Set of Pricebook Ids to query
     * @return List of Pricebook Entry Records found
     **/
    public List<PricebookEntry> getPBEByProductCodeList(Set<String> productCodesSet, Set<Id> pricebookIdSet) {
        return [
            SELECT
                Id,
                ProductCode,
                Pricebook2.Id,
                Pricebook2.IsStandard,
                Pricebook2.Name,
                UnitPrice,
                Product2Id,
                Pricebook2.COMM_ValidFrom__c,
                Pricebook2.COMM_ValidTo__c,
                Product2.COMM_Tax__c,
                Product2.Family,
                Product2.Name,
                Product2.COMM_Periodicity__c,
                Product2.ProductCode,
                Product2.COMM_SubCategory__c,
                Product2.COMM_Airport__c,
                Pricebook2Id,
                COMM_First15MinuteUnit__c,
                COMM_Second15MinuteUnit__c,
                COMM_Third15MinuteUnit__c,
                COMM_Remaining15MinuteUnit__c,
                COMM_FirstPeriodStartDay__c,
                COMM_FirstPeriodEndDay__c,
                COMM_FirstPeriodDailyMaximum__c,
                COMM_SecondPeriodStartDay__c,
                COMM_SecondPeriodEndDay__c,
                COMM_SecondPeriodDailyMaximum__c,
                COMM_ThirdPeriodStartDay__c,
                COMM_ThirdPeriodEndDay__c,
                COMM_ThirdPeriodDailyMaximum__c,
                COMM_FourthPeriodStartDay__c,
                COMM_FourthPeriodEndDay__c,
                COMM_FourthPeriodDailyMaximum__c
            FROM PricebookEntry
            WHERE
                ProductCode IN :productCodesSet
                AND IsActive = TRUE
                AND Pricebook2Id IN: pricebookIdSet
                AND Pricebook2.Type__c INCLUDES (:COMM_GEN_Utility.TYPE_RESELLER)
                AND Pricebook2.IsActive = TRUE
                AND Pricebook2.COMM_ValidFrom__c <= :system.now()
                AND Pricebook2.COMM_ValidTo__c >= :system.now()
            WITH USER_MODE
            ORDER BY Pricebook2.IsStandard ASC, Pricebook2.COMM_ValidFrom__c DESC
        ];
    }

    /**
     * @description Retrieve a list of Active Pricebook Entries for Card Products by a set of Ids
     *
     * @param cardProductIds Set of Card Product Ids to query
     * @return List of Pricebook Entry Records found for Card Products
     **/
    public List<PricebookEntry> getCardPBEByIds(Set<Id> cardProductIds) {
        return [
            SELECT Id, UnitPrice, Product2Id
            FROM PricebookEntry
            WHERE
                Product2Id IN :cardProductIds
                AND Product2.Family = :COMM_DO_Product2.CATEGORY_CARD
                AND IsActive = TRUE
                AND Pricebook2.IsActive = TRUE
                AND Pricebook2.IsStandard = TRUE
            WITH USER_MODE
        ];
    }

    /**
     * @description Retrieve a list of Valid(Valid From <= NOW AND Valid To >= NOW) Active Pricebook Entries by a set of Product Codes
     * using Database.query()
     *
     * @param productCodesSet Set of Product Codes to query
     * @return List of Pricebook Entry Records found
     **/
    public List<PricebookEntry> getPBEByProductCodeDataBaseQueryList(Set<String> productCodesSet) {
        String query =
            'SELECT ' +
            'Id, ' +
            'COMM_FirstPeriodStartDay__c, ' +
            'COMM_FirstPeriodEndDay__c, ' +
            'COMM_FirstPeriodDailyMaximum__c, ' +
            'COMM_SecondPeriodStartDay__c, ' +
            'COMM_SecondPeriodEndDay__c, ' +
            'COMM_SecondPeriodDailyMaximum__c, ' +
            'COMM_ThirdPeriodStartDay__c, ' +
            'COMM_ThirdPeriodEndDay__c, ' +
            'COMM_ThirdPeriodDailyMaximum__c, ' +
            'COMM_FourthPeriodStartDay__c, ' +
            'COMM_FourthPeriodEndDay__c, ' +
            'COMM_FourthPeriodDailyMaximum__c, ' +
            'COMM_First15MinuteUnit__c, ' +
            'COMM_Second15MinuteUnit__c, ' +
            'COMM_Third15MinuteUnit__c, ' +
            'COMM_Remaining15MinuteUnit__c, ' +
            'Pricebook2.Id, ' +
            'Pricebook2.IsStandard, ' +
            'Pricebook2.Name, ' +
            'Product2Id, ' +
            'Product2.COMM_Periodicity__c, ' +
            'toLabel(Product2.COMM_Periodicity__c) productPeriodicityLabel, ' +
            'Product2.Family, ' +
            'Product2.Name, ' +
            'ProductCode, ' +
            'UnitPrice ' +
            'FROM ' +
            'PricebookEntry ' +
            'WHERE ' +
            'ProductCode IN :productCodesSet ' +
            'AND IsActive = TRUE ' +
            'AND Pricebook2.Type__c = :publicType ' +
            'AND Pricebook2.IsActive = TRUE ' +
            'AND Pricebook2.COMM_ValidFrom__c <= ' +
            system.now().format('yyyy-MM-dd\'T\'HH:mm:ssXXX') +
            ' AND Pricebook2.COMM_ValidTo__c >= ' +
            system.now().format('yyyy-MM-dd\'T\'HH:mm:ssXXX') +
            ' WITH USER_MODE ' +
            'ORDER BY Pricebook2.IsStandard ASC, Pricebook2.COMM_ValidFrom__c DESC';

        return (List<PricebookEntry>) Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Retrieve a list of Pricebook Entries by a set of Product Ids and Pricebook Ids
     *
     * @param productIds Set of Product Ids to query
     * @param pricebookIds Set of Pricebook Ids to query
     * @return List of Pricebook Entry Records found
     **/
    public List<PricebookEntry> getPBEByProductAndPricebookIds(Set<Id> productIds, Set<Id> pricebookIds) {
        return [
            SELECT
                Id,
                UnitPrice,
                Product2Id,
                Product2.Family,
                ProductCode,
                Pricebook2Id,
                Pricebook2.IsStandard,
                COMM_First15MinuteUnit__c,
                COMM_Second15MinuteUnit__c,
                COMM_Third15MinuteUnit__c,
                COMM_Remaining15MinuteUnit__c,
                COMM_FirstPeriodStartDay__c,
                COMM_FirstPeriodEndDay__c,
                COMM_FirstPeriodDailyMaximum__c,
                COMM_SecondPeriodStartDay__c,
                COMM_SecondPeriodEndDay__c,
                COMM_SecondPeriodDailyMaximum__c,
                COMM_ThirdPeriodStartDay__c,
                COMM_ThirdPeriodEndDay__c,
                COMM_ThirdPeriodDailyMaximum__c,
                COMM_FourthPeriodStartDay__c,
                COMM_FourthPeriodEndDay__c,
                COMM_FourthPeriodDailyMaximum__c
            FROM PricebookEntry
            WHERE Product2Id IN :productIds AND Pricebook2Id IN :pricebookIds
            WITH USER_MODE
        ];
    }
}