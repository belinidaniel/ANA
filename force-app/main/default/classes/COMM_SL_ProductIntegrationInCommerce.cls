/**
 * @author Carlos Fusco
 * @description Product Integration in Commerce Service Layer
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    19/03/2024		Original version
 * Ricardo Dias    26/08/2024		Fix productCategory
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class COMM_SL_ProductIntegrationInCommerce {
    private static final String INTEGRATION_TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'';
    private static final String INTEGRATION_LOCALE_PT = 'pt-PT';
    private static final String INTEGRATION_KEY_SOURCE = 'source';
    private static final String INTEGRATION_SHORT_DESCRIPTION = 'short_description';
    private static final String INTEGRATION_LONG_DESCRIPTION = 'long_description';
    private static final String INTEGRATION_VALID_FROM = 'valid_from';
    private static final String INTEGRATION_VALID_TO = 'valid_to';

    private static final String INTEGRATION_PRODUCT_TARGET = 'c_productTargetAudience';
    private static final String INTEGRATION_REQUIRES_STAFF = 'c_requiresAirportStaff';
    private static final String INTEGRATION_REQUIRES_AFFILIATE = 'c_requiresAffiliate';
    private static final String INTEGRATION_PRODUCT_FEATURE = 'c_productFeature';
    private static final String INTEGRATION_TIME_TERMINAL = 'c_timeToTerminal';
    private static final String INTEGRATION_EXTERNAL_PRICING = 'c_externalPricing';
    private static final String INTEGRATION_EXTERNAL_AVAILABILITY = 'c_externalAvailability';
    private static final String INTEGRATION_ONLINE_FLAG = 'online_flag';

    private static final String INTEGRATION_TARGET_EVERYONE = 'everyone';
    private static final String INTEGRATION_TARGET_INDIVIDUAL_STAFF = 'individualStaff';
    private static final String INTEGRATION_TARGET_AFFILIATE = 'affiliate';
    private static final String INTEGRATION_KEY_DEFAULT = 'default';
    private static final String INTEGRATION_FEATURE_LIST_SPLITTER = ';';

    private static final String INTEGRATION_PERPETUAL_REQUEST_BODY = '{"perpetual_flag":true}';

    //Key name of variables associated with Category assignment
    private static final String INTEGRATION_CORE_CATEGORY = 'c_Family';
    private static final String INTEGRATION_PRIMARY_CATEGORY_ID = 'primary_category_id';
    private static final String INTEGRATION_CATEGORY_ASSIGNMENT = 'assigned_categories';
    private static final String INTEGRATION_CATEGORY_ID = 'category_id';
    private static final String INTEGRATION_CATALOG_ID = 'catalog_id';

    //Map with configuration metadata and names of configuration setting
    private static final Map<String, COMM_CommerceConfiguration__mdt> CONFIGURATION_MAP = COMM_CommerceConfiguration__mdt.getAll();
    private static final String REQUIRED_FIELDS_SETTING_NAME = 'RequiredFields';
    private static final String REQUIRED_FIELDS_PARKING_SETTING_NAME = 'RequiredParkingFields';
    private static final String REQUIRED_FIELDS_SUBSCRIPTION_SETTING_NAME = 'RequiredSubscriptionFields';
    private static final String SEARCHABLE_SETTING_NAME = 'IsSearchable';
    private static final String DEFAULT_CATALOG_SETTING_NAME = 'DefaultCatalog';
    private static final String DEFAULT_INVENTORY_SETTING_NAME = 'DefaultInventory';

    //Custom Metadata Setting with Callouts
    private static final COMM_CalloutSetting__mdt PRODUCT_CREATION_UPDATE_CALLOUT = COMM_CalloutSetting__mdt.getInstance('ProductCreationUpdate');
    private static final COMM_CalloutSetting__mdt PRODUCT_INVENTORY_CREATION_CALLOUT = COMM_CalloutSetting__mdt.getInstance(
        'ProductInventoryCreation'
    );
    private static final COMM_CalloutSetting__mdt CATEGORY_ASSIGNMENT_CALLOUT = COMM_CalloutSetting__mdt.getInstance('ProductCategoryAssignment');
    private String productCategory = '';

    private COMM_SL_VerifyAvailabilityAndPricing verifyAvailabilitySl;

    /**
     * @description Initialize SL
     */
    public COMM_SL_ProductIntegrationInCommerce() {
        this.verifyAvailabilitySl = new COMM_SL_VerifyAvailabilityAndPricing();
    }

    @TestVisible
    private COMM_SL_ProductIntegrationInCommerce(COMM_SL_VerifyAvailabilityAndPricing verifyAvailabilitySl) {
        this.verifyAvailabilitySl = verifyAvailabilitySl;
    }

    /**
     * @description Get Products integrated succesfully in Commerce
     *
     * @param products List of Products in condition to be integrated in Commerce
     * @param httpCallloutType HTTP Callout type depending on type of operation against Products (create or update)
     * @return List of Products integrated with success in Commerce
     */
    public List<Product2> getProductsIntegratedInCommerce(List<Product2> products, String httpCallloutType) {
        List<Product2> productsToUpdateList = new List<Product2>();

        //Set where Product Code of Products that are available and have pricing are stored
        Set<String> hasAvailabilitySet = new Set<String>();
        Set<String> hasPricingSet = new Set<String>();

        Boolean isSetForCreation = httpCallloutType == COMM_HttpCallout_Utility.HTTP_PUT_METHOD;
        Set<String> productCodes = new Set<String>();

        for (Product2 product : products) {
            productCodes.add(product.ProductCode);
        }

        if (isSetForCreation) {
            verifyAvailabilitySl.verifyProductHasPricingAndAvailableByCode(productCodes, hasAvailabilitySet, hasPricingSet);
        }

        for (Product2 product : products) {
            //Verifiy if Product can be integrated
            if (verifyIntegration(product, isSetForCreation, hasAvailabilitySet, hasPricingSet)) {
                HttpResponse httpResponse = makeCommerceHttpCallout(product, httpCallloutType);

                if (COMM_HttpCallout_Utility.isHttpResponseSuccesfull(httpResponse)) {
                    if (isSetForCreation) {
                        //Make call to create product inventory
                        createProductInventory(product);
                        product.COMM_IsIntegratedInCommerce__c = true;
                    } else if (httpCallloutType == COMM_HttpCallout_Utility.HTTP_PATCH_METHOD) {
                        //If Patch Call was success then update Product field used to flag that an update exists to false
                        product.COMM_HasUpdateForCommerce__c = false;
                    }
                    //Make call to assign Product to Category
                    createCategoryAssignment(product);
                    productsToUpdateList.add(product);
                } else {
                    //If call was unsuccessfull then log error with server response body
                    COMM_GEN_Utility.logError(
                        new AuraException(),
                        'Product ' + product.Id + ' failed integration: ' + httpResponse.getBody(),
                        'COMM_SL_ProductIntegrationInCommerce'
                    );
                }
            }
        }
        return productsToUpdateList;
    }

    /**
     * @description Method to verify if the Product should be integrated into Commerce
     * (has all required information filled)
     *
     * @param product The Product Record to be verified
     * @param isSetForCreation Boolean indicating if Product is set for creation in Commerce
     * @param hasAvailabilitySet Set with Product Code of Products that have availability in Core
     * @param hasPricingSet Set with Product Code of Products that have pricing in Core
     * @return True of Product is ready for integration (all requirements filled), False otherwise
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Boolean verifyIntegration(Product2 product, Boolean isSetForCreation, Set<String> hasAvailabilitySet, Set<String> hasPricingSet) {
        List<String> requiredFieldsList = getRequiredConfig(product.Family);

        //Verify if Product has Integration Body Filled and has no Child Products
        Boolean canBeIntegrated =
            String.isNotBlank(product.COMM_IntegrationRequestBody__c) && (product.Products__r == null || product.Products__r.isEmpty());

        //Verify if Required Products are filled
        if (canBeIntegrated) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(product.COMM_IntegrationRequestBody__c);
            String missingFieldList = '';
            //Verify if integration body contains all required fields
            for (String field : requiredFieldsList) {
                if (!jsonMap.containsKey(field)) {
                    missingFieldList += field + '; ';
                }
            }

            //If a field is missing generate a error log and return validation as failed
            if (String.isNotBlank(missingFieldList)) {
                COMM_GEN_Utility.logError(
                    new AuraException(),
                    'Product ' + product.Id + ' is missing fields for integration: ' + missingFieldList,
                    'COMM_SL_ProductIntegrationInCommerce'
                );
                return false;
            }

            //Verify if Product is set for Creation, has Availability and availability is set in Core
            if (isSetForCreation && product.COMM_AvailabilityDeterminedInCore__c && !hasAvailabilitySet.contains(product.ProductCode)) {
                COMM_GEN_Utility.logError(
                    new AuraException(),
                    'Product ' + product.Id + ' isn\'t available (missing capacity) ',
                    'COMM_SL_ProductIntegrationInCommerce'
                );
                return false;
            }

            //Verify if Product is set for creation, has Pricing and pricing is set in Core
            if (isSetForCreation && product.COMM_PriceDeterminedInCore__c && !hasPricingSet.contains(product.ProductCode)) {
                COMM_GEN_Utility.logError(
                    new AuraException(),
                    'Product ' + product.Id + ' doesn\'t have defined pricing ',
                    'COMM_SL_ProductIntegrationInCommerce'
                );
                return false;
            }
        }

        return canBeIntegrated;
    }

    /**
     * @description Obtain Required Fields to be filled based on Product Category
     *
     * @param productCategory Category of the Product being integrated
     * @return List of Fields that are required to be filled for Product Integration
     */
    private List<String> getRequiredConfig(String productCategory) {
        //Obtain Configuration based on Product Category (Subscription, Parking and remaining)
        COMM_CommerceConfiguration__mdt requiredFieldsConfig;
        if (COMM_DO_Product2.CATEGORY_SUBSCRIPTION.equals(productCategory)) {
            requiredFieldsConfig = CONFIGURATION_MAP.get(REQUIRED_FIELDS_SUBSCRIPTION_SETTING_NAME);
        } else if (COMM_DO_Product2.CATEGORY_PARKING.equals(productCategory)) {
            requiredFieldsConfig = CONFIGURATION_MAP.get(REQUIRED_FIELDS_PARKING_SETTING_NAME);
        } else {
            requiredFieldsConfig = CONFIGURATION_MAP.get(REQUIRED_FIELDS_SETTING_NAME);
        }
        //Return list of fields in metadata record
        return requiredFieldsConfig.COMM_Value__c.split(INTEGRATION_FEATURE_LIST_SPLITTER);
    }

    /**
     * @description Make Callout to create Product Inventory Record of Created Product as Perpetual
     *
     * @param product Salesforce Product that was created in Commerce
     */
    private void createProductInventory(Product2 product) {
        //Obtain Endpoint from Custom Metadata. Inventory Id in endpoint is expected to be the Id stored
        //in Product's Inventory Field (COMM_ProductInventory__c). If field isn't filled then use default from custom metadata.
        String defaultInventory = CONFIGURATION_MAP.get(DEFAULT_INVENTORY_SETTING_NAME).COMM_Value__c;
        String inventoryEndpoint =
            PRODUCT_INVENTORY_CREATION_CALLOUT.COMM_NamedCredential__c +
            String.format(
                PRODUCT_INVENTORY_CREATION_CALLOUT.COMM_Path__c,
                new List<Object>{ String.isNotBlank(product.COMM_ProductInventory__c) ? product.COMM_ProductInventory__c : defaultInventory }
            );
        COMM_HttpCallout_Utility.httpPutCallout(
            inventoryEndpoint + product.ProductCode,
            new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
            INTEGRATION_PERPETUAL_REQUEST_BODY
        );
    }

    /**
     * @description Make Callout to assign created Product to Category
     *
     * @param product Salesforce Product that was created in Commerce
     */
    private void createCategoryAssignment(Product2 product) {
        //Skip assignment if Category wasn't provided
        if (String.isNotBlank(productCategory)) {
            //Obtain Endpoint and Master Catalog from Custom Metadata
            String masterCatalog = CONFIGURATION_MAP.get(DEFAULT_CATALOG_SETTING_NAME).COMM_Value__c;

            //Remove empty spaces on productCategory
            productCategory = productCategory.replaceAll(' ', '%20');
            String assignmentEndpoint =
                CATEGORY_ASSIGNMENT_CALLOUT.COMM_NamedCredential__c +
                String.format(CATEGORY_ASSIGNMENT_CALLOUT.COMM_Path__c, new List<Object>{ masterCatalog, productCategory });

            HttpResponse response = COMM_HttpCallout_Utility.httpPutCallout(
                assignmentEndpoint + product.ProductCode,
                new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
                '{}'
            );
        }
    }

    /**
     * @description Perform HTTP Callout to Commerce depending on type of operation agains Products (create or update)
     *
     * @param product Product record to integrate in Commerce
     * @param httpCallloutType HTTP Callout type depending on type of operation against Products (create or update)
     * @return HTTPResponse with the result of HTTP callout request to Commerce
     */
    @TestVisible
    private HTTPResponse makeCommerceHttpCallout(Product2 product, String httpCallloutType) {
        String productEndpoint = PRODUCT_CREATION_UPDATE_CALLOUT.COMM_NamedCredential__c + PRODUCT_CREATION_UPDATE_CALLOUT.COMM_Path__c;
        return httpCallloutType == COMM_HttpCallout_Utility.HTTP_PUT_METHOD
            ? COMM_HttpCallout_Utility.httpPutCallout(
                  productEndpoint + product.ProductCode,
                  new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
                  setProductIntegrationHttpRequestBody(product.COMM_IntegrationRequestBody__c, httpCallloutType)
              )
            : httpCallloutType == COMM_HttpCallout_Utility.HTTP_PATCH_METHOD
                  ? COMM_HttpCallout_Utility.httpPatchCallout(
                        productEndpoint + product.ProductCode,
                        new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
                        setProductIntegrationHttpRequestBody(product.COMM_IntegrationRequestBody__c, httpCallloutType)
                    )
                  : null;
    }

    /**
     * @description Set up HTTP Callout request body to meet Commerce API definition
     *
     * @param productIntegrationBody String with Product Core field values mapped to Commerce field api's
     * @param httpCallloutType HTTP Callout type depending on type of operation against Products (create or update)
     * @return String with HTTP Callout request body, JSON formatted, compliant with Commerce api structure
     */
    @TestVisible
    private String setProductIntegrationHttpRequestBody(String productIntegrationBody, String httpCallloutType) {
        Map<String, Object> deserializedHttRequest = (Map<String, Object>) JSON.deserializeUntyped(productIntegrationBody);

        //If Creation (PUT) set Product Catalog to Master
        if (httpCallloutType == COMM_HttpCallout_Utility.HTTP_PUT_METHOD) {
            COMM_CommerceConfiguration__mdt catalogSetting = CONFIGURATION_MAP.get(DEFAULT_CATALOG_SETTING_NAME);
            deserializedHttRequest.put(catalogSetting.COMM_Key__c, catalogSetting.COMM_Value__c);
        }

        //Prepare short_description value
        if (deserializedHttRequest.containsKey(INTEGRATION_SHORT_DESCRIPTION)) {
            deserializedHttRequest.put(
                INTEGRATION_SHORT_DESCRIPTION,
                new Map<String, Object>{
                    INTEGRATION_LOCALE_PT => new Map<String, Object>{
                        INTEGRATION_KEY_SOURCE => deserializedHttRequest.get(INTEGRATION_SHORT_DESCRIPTION)
                    }
                }
            );
        }

        //Prepare long_description value
        if (deserializedHttRequest.containsKey(INTEGRATION_LONG_DESCRIPTION)) {
            deserializedHttRequest.put(
                INTEGRATION_LONG_DESCRIPTION,
                new Map<String, Object>{
                    INTEGRATION_LOCALE_PT => new Map<String, Object>{
                        INTEGRATION_KEY_SOURCE => deserializedHttRequest.get(INTEGRATION_LONG_DESCRIPTION)
                    }
                }
            );
        }

        //Prepare valid_from value
        if (deserializedHttRequest.containsKey(INTEGRATION_VALID_FROM)) {
            deserializedHttRequest.put(
                INTEGRATION_VALID_FROM,
                Datetime.valueOf((String) deserializedHttRequest.get(INTEGRATION_VALID_FROM)).format(INTEGRATION_TIME_FORMAT)
            );
        }

        //Prepare valid_to value
        if (deserializedHttRequest.containsKey(INTEGRATION_VALID_TO)) {
            deserializedHttRequest.put(
                INTEGRATION_VALID_TO,
                Datetime.valueOf((String) deserializedHttRequest.get(INTEGRATION_VALID_TO)).format(INTEGRATION_TIME_FORMAT)
            );
        }

        //Prepare c_timeToTerminal value
        if (deserializedHttRequest.containsKey(INTEGRATION_TIME_TERMINAL)) {
            deserializedHttRequest.put(INTEGRATION_TIME_TERMINAL, Integer.valueOf(deserializedHttRequest.get(INTEGRATION_TIME_TERMINAL)));
        }

        //Prepare online_flag value
        if (deserializedHttRequest.containsKey(INTEGRATION_ONLINE_FLAG)) {
            deserializedHttRequest.put(
                INTEGRATION_ONLINE_FLAG,
                new Map<String, Object>{ INTEGRATION_KEY_DEFAULT => Boolean.valueOf(deserializedHttRequest.get(INTEGRATION_ONLINE_FLAG)) }
            );
        }

        //Prepare primary_category_id value
        if (deserializedHttRequest.containsKey(INTEGRATION_CORE_CATEGORY)) {
            deserializedHttRequest.put(INTEGRATION_PRIMARY_CATEGORY_ID, deserializedHttRequest.get(INTEGRATION_CORE_CATEGORY));
        }

        //Verify field conversion
        verifyConversion(deserializedHttRequest);

        //Add Searchable Tag
        COMM_CommerceConfiguration__mdt searchableSetting = CONFIGURATION_MAP.get(SEARCHABLE_SETTING_NAME);
        deserializedHttRequest.put(
            searchableSetting.COMM_Key__c,
            new Map<String, Object>{ INTEGRATION_KEY_DEFAULT => Boolean.valueOf(searchableSetting.COMM_Value__c) }
        );

        return JSON.serializePretty(deserializedHttRequest);
    }

    /**
     * @description Verify if request has values that require conversion for commerce based on
     * custom metadata
     *
     * @param deserializedHttRequest Map with the request body to be sent to commerce
     */
    private void verifyConversion(Map<String, Object> deserializedHttRequest) {
        //Verify if request has Required Individual Staff or Required Affiliate field.
        // - If it has, add Product Target field whose values depends on individual staff/affiliate.
        if (deserializedHttRequest.containsKey(INTEGRATION_REQUIRES_STAFF) || deserializedHttRequest.containsKey(INTEGRATION_REQUIRES_AFFILIATE)) {
            //Convert String value to Boolean
            Boolean requiresStaff = Boolean.valueOf(deserializedHttRequest.get(INTEGRATION_REQUIRES_STAFF));
            Boolean requiresAffiliate = Boolean.valueOf(deserializedHttRequest.get(INTEGRATION_REQUIRES_AFFILIATE));

            // Determine product target value
            String productTargetAudience = INTEGRATION_TARGET_EVERYONE;

             if (requiresStaff) {
                productTargetAudience = INTEGRATION_TARGET_INDIVIDUAL_STAFF;
            } else if (requiresAffiliate) {
                productTargetAudience = INTEGRATION_TARGET_AFFILIATE;
            }

            // Add flags to payload as needed
            if (deserializedHttRequest.containsKey(INTEGRATION_REQUIRES_STAFF)) {
                deserializedHttRequest.put(INTEGRATION_REQUIRES_STAFF, requiresStaff);
            } else if (deserializedHttRequest.containsKey(INTEGRATION_REQUIRES_AFFILIATE)) {
                deserializedHttRequest.put(INTEGRATION_REQUIRES_AFFILIATE, requiresAffiliate);
            }

            // Finally, add the product target value
            deserializedHttRequest.put(INTEGRATION_PRODUCT_TARGET, productTargetAudience);
        }

        //Verify if request has External Availability field. If it has then convert String to Boolean
        if (deserializedHttRequest.containsKey(INTEGRATION_EXTERNAL_AVAILABILITY)) {
            deserializedHttRequest.put(
                INTEGRATION_EXTERNAL_AVAILABILITY,
                Boolean.valueOf(deserializedHttRequest.get(INTEGRATION_EXTERNAL_AVAILABILITY))
            );
        }

        //Verify if request has External Pricing field. If it has then convert String to Boolean
        if (deserializedHttRequest.containsKey(INTEGRATION_EXTERNAL_PRICING)) {
            deserializedHttRequest.put(INTEGRATION_EXTERNAL_PRICING, Boolean.valueOf(deserializedHttRequest.get(INTEGRATION_EXTERNAL_PRICING)));
        }

        //Verify if Product Feature was mapped. Replace value as a Set of String Array
        if (
            deserializedHttRequest.containsKey(INTEGRATION_PRODUCT_FEATURE) &&
            String.isNotBlank(deserializedHttRequest.get(INTEGRATION_PRODUCT_FEATURE)?.toString())
        ) {
            String[] stringArray = deserializedHttRequest.get(INTEGRATION_PRODUCT_FEATURE).toString().split(INTEGRATION_FEATURE_LIST_SPLITTER);
            deserializedHttRequest.put(
                INTEGRATION_PRODUCT_FEATURE,
                new Map<String, Object>{ INTEGRATION_KEY_DEFAULT => new Set<String>(stringArray) }
            );
        }

        new COMM_DO_ProductSyncFieldConvert().verifyValueConversion(deserializedHttRequest);

        //Prepare category assignment list if primary assignment has value
        if (
            deserializedHttRequest.containsKey(INTEGRATION_PRIMARY_CATEGORY_ID) &&
            String.isNotBlank((String) deserializedHttRequest.get(INTEGRATION_PRIMARY_CATEGORY_ID))
        ) {
            productCategory = (String) deserializedHttRequest.get(INTEGRATION_PRIMARY_CATEGORY_ID);
            Map<String, Object> categoryAssignemnt = new Map<String, Object>{
                INTEGRATION_CATALOG_ID => CONFIGURATION_MAP.get(DEFAULT_CATALOG_SETTING_NAME).COMM_Value__c,
                INTEGRATION_CATEGORY_ID => productCategory
            };
            deserializedHttRequest.put(INTEGRATION_CATEGORY_ASSIGNMENT, new List<Map<String, Object>>{ categoryAssignemnt });
        }
    }
}