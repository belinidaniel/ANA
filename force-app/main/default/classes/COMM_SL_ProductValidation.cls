/**
 * @author Ruben Rodrigues
 * @description Service Layer class to validate and generate Product Readiness
 * records
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues   4/06/2024       Original version
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class COMM_SL_ProductValidation {
    private COMM_IREP_ProductSetting productSettingRep;
    private COMM_IREP_Product2 productRep;

    /**
     * @description Class constructor to initialize REP classes
     */
    public COMM_SL_ProductValidation() {
        this.productSettingRep = new COMM_REP_ProductSetting();
        this.productRep = new COMM_REP_Product2();
    }

    /**
     * @description Method that verifies Product Readiness and returns list of result
     *
     * @param productList List of Products to verify readiness
     * @param pricingMap Map with information if Product has Pricing defined
     * @param availabilityMap Map with information if Product has availability defined
     * @return List of COMM_ProductReadiness__c records
     */
    public List<COMM_ProductReadiness__c> verifyReadiness(List<Product2> productList) {
        //Verify Pricing and Availability of Product Records
        Map<Id, Boolean> parentHasCapacityMap = getParentHasCapacityMap(productList);
        Map<Id, Boolean> pricingMap = new Map<Id, Boolean>();
        Map<Id, Boolean> availabilityMap = new Map<Id, Boolean>();
        for (Product2 pRecord : productList) {
            pricingMap.put(pRecord.Id, isValidForPricing(pRecord));
            availabilityMap.put(pRecord.Id, isValidForAvailability(pRecord, parentHasCapacityMap));
        }

        //Verify Settings
        Map<Product2, String> emptyOrNullFieldsMap = checkMatching(productList);
        List<COMM_ProductSetting__c> coreFieldsList = productSettingRep.getCoreEssentialFields();
        List<COMM_ProductSetting__c> commerceFieldsList = productSettingRep.getCommerceEssentialFields();

        return generateReadinessList(emptyOrNullFieldsMap, coreFieldsList, commerceFieldsList, pricingMap, availabilityMap);
    }

    /**
     * @description Method to generate List of Product Readiness based on Product List
     * and settings
     *
     * @param emptyOrNullFieldsMap Map of Products with missing or null fields
     * @param coreFieldsList List of Fields essecial in Core
     * @param commerceFieldsList List of Fields essecial in Commerce
     * @param pricingMap Map indicating that Product has pricing defined
     * @param availabilityMap Map indicating that Product has availability defined
     * @return List of Product Readiness Records generated.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList,PMD.CognitiveComplexity')
    private List<COMM_ProductReadiness__c> generateReadinessList(
        Map<Product2, String> emptyOrNullFieldsMap,
        List<COMM_ProductSetting__c> coreFieldsList,
        List<COMM_ProductSetting__c> commerceFieldsList,
        Map<Id, Boolean> pricingMap,
        Map<Id, Boolean> availabilityMap
    ) {
        List<COMM_ProductReadiness__c> prList = new List<COMM_ProductReadiness__c>();
        for (Product2 p : emptyOrNullFieldsMap.keySet()) {
            Boolean validForPricing = pricingMap.get(p.Id);
            Boolean validForAvailability = availabilityMap.get(p.Id);
            String emptyOrNullFields = emptyOrNullFieldsMap.get(p);

            COMM_ProductReadiness__c pr = new COMM_ProductReadiness__c();

            List<String> emptyOrNullFieldsList = emptyOrNullFields.split(',\\s*');

            // Match empty or null fields with essential fields
            List<String> matchingCoreFieldsList = new List<String>();
            List<String> matchingCommerceFieldsList = new List<String>();
            for (String field : emptyOrNullFieldsList) {
                for (COMM_ProductSetting__c coreField : coreFieldsList) {
                    if (field == coreField.COMM_FieldAPIName__c) {
                        matchingCoreFieldsList.add(field);
                        break;
                    }
                }
                for (COMM_ProductSetting__c commerceField : commerceFieldsList) {
                    if (field == commerceField.COMM_FieldAPIName__c) {
                        matchingCommerceFieldsList.add(field);
                        break;
                    }
                }
            }
            pr.Name = p.Id; //Store Product Id as Readiness Name to allow upsert
            pr.COMM_Product__c = p.Id;
            pr.COMM_MissingInformationOnCommerce__c = String.join(matchingCommerceFieldsList, ', ');
            pr.COMM_MissingInformationOnCore__c = String.join(matchingCoreFieldsList, ', ');
            pr.COMM_HasPricing__c = validForPricing;
            pr.COMM_HasCapacity__c = validForAvailability;
            prList.add(pr);
        }
        return prList;
    }

    /**
     * @description Method to obtain map with information if Parent Product for Lounge
     * and Subscription has Capacity defined.
     *
     * @param productList List of Products to check for Parent Capacity
     * @return Map where Key is Parent Product Id and Values is Boolean indicating if Parent
     * has Capacity defined
     */
    private Map<Id, Boolean> getParentHasCapacityMap(List<Product2> productList) {
        Set<Id> parentIdSet = new Set<Id>();
        //Verify if Product has Parent and is Lounge or Subscription
        for (Product2 product : productList) {
            if (
                product.COMM_ParentProduct__c != null &&
                (product.Family.Equals(COMM_OCI_Constants.PRODUCT_FAMILY_LOUNGE) ||
                product.Family.Equals(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION))
            ) {
                parentIdSet.add(product.COMM_ParentProduct__c);
            }
        }

        //Verify if Parent Products for Lounge and Subscription have Capacity
        Map<Id, Boolean> parentProductHasCapacityMap = new Map<Id, Boolean>();
        if (!parentIdSet.isEmpty()) {
            for (Product2 parentProduct : productRep.getValidProductAndCapacitiesByIds(parentIdSet)) {
                parentProductHasCapacityMap.put(parentProduct.Id, !parentProduct.Capacities__r.isEmpty());
            }
        }
        return parentProductHasCapacityMap;
    }

    /**
     * @description Method to match Product2 records missing required fields inserted on the COMM_ProductSetting__c
     * @param productsWithEmptyOrNullFieldsList Product2 List
     * @return Map of Product2 that with the missing fields
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    private Map<Product2, String> checkMatching(List<Product2> productsWithEmptyOrNullFieldsList) {
        // Get the custom fields of the Product2 object
        SObjectType productType = Schema.getGlobalDescribe().get('Product2');
        Map<String, Schema.SObjectField> productFieldsMap = new Map<String, Schema.SObjectField>();
        for (Schema.SObjectField field : productType.getDescribe().fields.getMap().values()) {
            productFieldsMap.put(field.getDescribe().getName(), field);
        }
        // Check if Product_Settings is a custom object in your org
        if (!Schema.getGlobalDescribe().containsKey('COMM_ProductSetting__c')) {
            return null; // Exit the code if COMM_ProductSetting__c custom object does not exist
        }

        // Get the values of the custom field from COMM_ProductSetting__c
        Set<String> productSettingsValuesSet = new Set<String>();
        List<COMM_ProductSetting__c> fieldAPIList = productSettingRep.getFieldAPINames();
        for (COMM_ProductSetting__c setting : fieldAPIList) {
            productSettingsValuesSet.add(setting.COMM_FieldAPIName__c);
        }
        // Define a list to store empty or null fields
        Map<Product2, String> emptyOrNullFieldsMap = new Map<Product2, String>();

        // Construct the SOQL query to fetch all relevant fields from Product2
        productsWithEmptyOrNullFieldsList = productRep.getProductWithDynamicFields(productSettingsValuesSet);

        // Iterate through each field in Product2 and check if its value matches any value from Product_Settings__c
        for (Product2 prod : productsWithEmptyOrNullFieldsList) {
            // Get the field value from the Product2 record
            for (String fieldName : productSettingsValuesSet) {
                String fieldValue = String.valueOf(prod.get(fieldName));
                // Check if the field value is empty or null
                if (String.isBlank(fieldValue)) {
                    // Add the empty or null field to the string associated with the Product2 record
                    if (!emptyOrNullFieldsMap.containsKey(prod)) {
                        emptyOrNullFieldsMap.put(prod, fieldName);
                    } else {
                        String existingFields = emptyOrNullFieldsMap.get(prod);
                        emptyOrNullFieldsMap.put(prod, existingFields + ', ' + fieldName);
                    }
                }
            }
        }

        return emptyOrNullFieldsMap;
    }

    /**
     * @description Method to verify if valid for Pricing
     *
     * @param Product to verify pricing
     * @return True if Product is valid for Pricing, false otherwise.
     */
    private Boolean isValidForPricing(Product2 product) {
        // Check if the Product2 record has an active standard price book entry for the current date

        if (
            product.Family != null &&
            product.Family.Equals(COMM_DO_Product2.CATEGORY_PARKING) &&
            (hasActiveStandardPriceBook(product) || hasRequiredPriceBookEntry(product))
        ) {
            return true;
        } else if (
            product.Family != null &&
            (product.Family.Equals(COMM_DO_Product2.CATEGORY_FASTTRACK) ||
            product.Family.Equals(COMM_DO_Product2.CATEGORY_LOUNGE) ||
            product.Family.Equals(COMM_DO_Product2.CATEGORY_SUBSCRIPTION)) &&
            (hasActiveStandardPriceBook(product) || hasRequiredPriceBookEntryWithUnitPrice(product))
        ) {
            return true;
        }

        // All validation not criteria met, return false
        return false;
    }

    /**
     * @description Verify if there is atleast one Pricebook Entry
     * for Standard Pricebook
     *
     * @param productRecord Product whos Pricebook is verified
     * @return True if there is one PBE, false otherwise
     */
    private Boolean hasActiveStandardPriceBook(Product2 productRecord) {
        for (PricebookEntry pbEntry : productRecord.PricebookEntries) {
            //Verify if Entry is for Standard Pricebook and is Valid
            if (
                pbEntry.Pricebook2.IsStandard &&
                productRecord.COMM_ValidFrom__c <= System.today() &&
                productRecord.COMM_ValidTo__c >= System.today()
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Verify if there is atleast one Pricebook Entry
     * with required units filled
     *
     * @param productRecord Product whos Pricebook is verified
     * @return True if there is one PBE, false otherwise
     */
    private Boolean hasRequiredPriceBookEntry(Product2 productRecord) {
        for (PricebookEntry pbEntry : productRecord.PricebookEntries) {
            //Verify if Entry has Required Fields defined
            if (
                pbEntry.COMM_First15MinuteUnit__c != null &&
                pbEntry.COMM_Second15MinuteUnit__c != null &&
                pbEntry.COMM_Third15MinuteUnit__c != null &&
                pbEntry.COMM_Remaining15MinuteUnit__c != null &&
                pbEntry.COMM_FirstPeriodStartDay__c != null &&
                pbEntry.COMM_FirstPeriodEndDay__c != null &&
                pbEntry.COMM_FirstPeriodDailyMaximum__c != null
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Verify if there is atleast one Pricebook Entry
     * with unit price
     *
     * @param productRecord Product whos Pricebook is verified
     * @return True if there is one PBE, false otherwise
     */
    private Boolean hasRequiredPriceBookEntryWithUnitPrice(Product2 productRecord) {
        for (PricebookEntry pbEntry : productRecord.PricebookEntries) {
            //Verify if Entry has Unit Price defined
            if (pbEntry.UnitPrice > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Method to verify availability
     *
     * @param product Product Record to verify availability
     * @param parentHasCapacityMap Map with Availability of Parent Products
     * @return True if Product is Valid, False otherwise
     */
    private Boolean isValidForAvailability(Product2 product, Map<Id, Boolean> parentHasCapacityMap) {
        return validateAvailabilityOnLoungeSubscrProducts(product, parentHasCapacityMap) || validateAvailabilityOnParkingFTrackProducts(product);
    }

    /**
     * @description Method to verify if Product has valid availabity
     * according to Rule for Lounge and Subscription.
     *
     * @param product Product to be verified
     * @param parentHasCapacityMap Map that indicates if Parent Product has Capacity
     * @return True if Product has Valid Availability, False otherwise
     */
    private Boolean validateAvailabilityOnLoungeSubscrProducts(Product2 product, Map<Id, Boolean> parentHasCapacityMap) {
        //If Product doesn't have Parent or is't Lounge or Subscription then validation is false
        if (
            product.COMM_ParentProduct__c == null ||
            (!product.Family.Equals(COMM_OCI_Constants.PRODUCT_FAMILY_LOUNGE) &&
            !product.Family.Equals(COMM_OCI_Constants.PRODUCT2_FAMILY_SUBSCRIPTION))
        ) {
            return false;
        }
        //Verify if Parent Product has Capacity
        return parentHasCapacityMap.containsKey(product.COMM_ParentProduct__c) && parentHasCapacityMap.get(product.COMM_ParentProduct__c);
    }

    /**
     * @description Method to verify if Product has valid availabity
     * according to Rule for Parking and FastTrack.
     *
     * @param product Product to be verified
     * @return True if Product has Valid Availability, False otherwise
     */
    private Boolean validateAvailabilityOnParkingFTrackProducts(Product2 product) {
        //Verify if Product is Parking or Fast Track and has Capacity
        return (product.Family.equals(COMM_DO_Product2.CATEGORY_PARKING) || product.Family.equals(COMM_DO_Product2.CATEGORY_FASTTRACK)) &&
            !product.Capacities__r.isEmpty();
    }
}