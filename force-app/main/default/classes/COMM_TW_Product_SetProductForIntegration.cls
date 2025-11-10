/**
 * @author Carlos Fusco
 * @description Trigger worker to verify if Product is in condition to be integrated
 * in Commerce Cloud. If yes set text field with JSON text containing the body for
 * the callout request for the integration.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    08/03/2024		Original version
 **/
public class COMM_TW_Product_SetProductForIntegration {
    /**
     * @description Execute Trigger Worker Logic
     *
     * @param newProductList List with the Product Records in Trigger.New context
     * @param oldProductMap Map with the Product Records in Trigger.Old context
     */
    public void execute(List<Product2> newProductList, Map<Id, Product2> oldProductMap) {
        Map<String, COMM_ProductSynchronizationFieldMapping__mdt> fieldMappingByProductField = new Map<String, COMM_ProductSynchronizationFieldMapping__mdt>();
        Map<String, Object> fieldValueByCommerceApi = new Map<String, Object>();

        for (COMM_ProductSynchronizationFieldMapping__mdt productSyncMapping : COMM_ProductSynchronizationFieldMapping__mdt.getAll().values()) {
            fieldMappingByProductField.put(productSyncMapping.COMM_CoreApiFieldName__c, productSyncMapping);
        }

        for (Product2 newProduct : newProductList) {
            if (isProductInConditionsForIntegration(newProduct)) {
                for (String productField : fieldMappingByProductField.keySet()) {
                    String value = newProduct.get(productField)?.toString();
                    fieldValueByCommerceApi.put(fieldMappingByProductField.get(productField).COMM_CommerceApiFieldName__c, value);
                }

                if (!fieldValueByCommerceApi.isEmpty()) {
                    updateBodyField(newProduct, fieldValueByCommerceApi);
                }
            }
        }
    }

    /**
     * @description Check if Product Record in Trigger.New context is in conditions to be integrated to Commerce
     *
     * @param newProduct Product Record to process
     * @return Boolean flagging if Product record is in condition to be integrated to Commerce
     */
    private Boolean isProductInConditionsForIntegration(Product2 newProduct) {
        return newProduct.COMM_WhereProductAvailable__c != null &&
            newProduct.COMM_WhereProductAvailable__c.contains(COMM_DO_Product2.PRODUCT_AVAILABLE_IN_COMMERCE);
    }

    /**
     * @description Deserialize JSON formated COMM_IntegrationRequestBody to process and support field mapping between Salesforce Core and Commerce
     *
     * @param newProduct Product Record to process
     * @return Map of Product field value by Commerce API field value to map
     */
    private Map<String, Object> getFieldValueByCommerceApi(Product2 newProduct) {
        return String.isBlank(newProduct.COMM_IntegrationRequestBody__c)
            ? new Map<String, Object>()
            : (Map<String, Object>) JSON.deserializeUntyped(newProduct.COMM_IntegrationRequestBody__c);
    }

    /**
     * @description Method to update Integration Request Body on the Product Record
     * Additionally verifies if update occured and set flag that has update to true
     *
     * @param newProduct Product Record that is being inserted/updated
     * @param fieldValueByCommerceApi Map with the mew request body
     */
    private void updateBodyField(Product2 newProduct, Map<String, Object> fieldValueByCommerceApi) {
        String jsonIntregrationRequestBody = JSON.serializePretty(fieldValueByCommerceApi);

        Map<String, Object> bodyBeforeUpdate = getFieldValueByCommerceApi(newProduct);

        newProduct.COMM_IntegrationRequestBody__c = jsonIntregrationRequestBody;
        //Verify if Product is integrated in Commerce and Request Body was changed
        if (newProduct.COMM_IsIntegratedInCommerce__c && !bodyBeforeUpdate.equals(fieldValueByCommerceApi)) {
            newProduct.COMM_HasUpdateForCommerce__c = true;
        }
    }
}