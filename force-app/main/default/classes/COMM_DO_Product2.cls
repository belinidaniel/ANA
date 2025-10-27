/**
 * @author Daniel Lascas
 * @description Product2 SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    10/04/2024       ECOMM-194: Original version
 **/
public inherited sharing class COMM_DO_Product2 implements COMM_IDO_Product2 {
    //Values for Category Picklist (Standard Family Field)
    public static final string CATEGORY_CARD = 'Card';
    public static final string CATEGORY_FASTTRACK = 'Fast Track';
    public static final string CATEGORY_GIFTCARD = 'Gift Card';
    public static final string CATEGORY_LOUNGE = 'Lounge';
    public static final string CATEGORY_PARKING = 'Parking';
    public static final string CATEGORY_SUBSCRIPTION = 'Subscription';

    //Value for Where is Product Available Multi-Picklist
    public static final string PRODUCT_AVAILABLE_IN_COMMERCE = 'eCommerce';

    //Value for Sub-Category
    public static final String SUBCATEGORY_STAFF_COMPANY = 'Staff Company';
    public static final String SUBCATEGORY_OFFICIAL_ENTITY = 'Exempt Official Entity';
    public static final String SUBCATEGORY_COURTESY = 'Courtesy';

    //Value for Product Type
    public static final String PRODUCT_TYPE_BUNDLE = 'bundle';
	
    /**
     * @description Get correct API values of Product Family.
     * @param List<String> productFamilyCodeList - List of Product Family Code values
     * @return List<String> output with list of Strings with the correct Product Family Code API values
     */
    public static List<String> getFilterProductFamilyAPI(List<String> productFamilyCodeList) {
        List<String> productFamilyValuesList = new List<String>();
        Map<String, String> productFamilyCodeMap = new Map<String, String>{
            'CARD' => COMM_DO_Product2.CATEGORY_CARD,
            'FASTTRACK' => COMM_DO_Product2.CATEGORY_FASTTRACK,
            'GIFTCARD' => COMM_DO_Product2.CATEGORY_GIFTCARD,
            'LOUNGE' => COMM_DO_Product2.CATEGORY_LOUNGE,
            'PARKING' => COMM_DO_Product2.CATEGORY_PARKING,
            'SUBSCRIPTION' => COMM_DO_Product2.CATEGORY_SUBSCRIPTION
        };

        for (String productFamily : productFamilyCodeList) {
            if (productFamilyCodeMap.containsKey(productFamily)) {
                productFamilyValuesList.add(productFamilyCodeMap.get(productFamily));
            }
        }

        return productFamilyValuesList;
    }

    /**
     * @description Get correct API values of Product Family.
     * @param Set<String> productFamilyCodeSet - Set of Product Family Code values
     * @return List<String> output with list of Strings with the correct Product Family Code API values
     */
    public static List<String> getFilterProductFamilyCodes(Set<String> productFamilyCodeSet) {
        List<String> productFamilyValuesList = new List<String>();
        Map<String, String> productFamilyCodeMap = new Map<String, String>{
            COMM_DO_Product2.CATEGORY_CARD => 'CARD',
            COMM_DO_Product2.CATEGORY_FASTTRACK => 'FASTTRACK',
            COMM_DO_Product2.CATEGORY_GIFTCARD => 'GIFTCARD',
            COMM_DO_Product2.CATEGORY_LOUNGE => 'LOUNGE',
            COMM_DO_Product2.CATEGORY_PARKING => 'PARKING',
            COMM_DO_Product2.CATEGORY_SUBSCRIPTION => 'SUBSCRIPTION'
        };

        for (String productFamily : productFamilyCodeSet) {
            if (productFamilyCodeMap.containsKey(productFamily)) {
                productFamilyValuesList.add(productFamilyCodeMap.get(productFamily));
            }
        }

        return productFamilyValuesList;
    }
}