/**
 * @author Carlos Fusco
 * @description Batch class to integrate Product records created in Salesforce Core to
 * Salesforce Commerce
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date            Description
 * ------------------------------------------------------------------------------------
 * Carlos Fusco    11/03/2024		Original version
 **/
public with sharing class COMM_Async_CreateProductInCommerce extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    @TestVisible
    private final static string PARAMETER_OBJECT_NAME = 'SObject API Name';
    @TestVisible
    private final static string PRODUCT_OBJECT_NAME = 'Product2';
    @TestVisible
    private final static string PARAMETER_AVAILABILITY = 'Availability';

    private FW_ISObjectRep sObjectRep;

    public static final List<SObjectField> CREATEPRODUCTINCOMMERCE_FIELDS = new List<SObjectField>{
        Product2.Id,
        Product2.ProductCode,
        Product2.isActive,
        Product2.Family,
        Product2.COMM_IntegrationRequestBody__c,
        Product2.COMM_IsIntegratedInCommerce__c,
        Product2.COMM_ProductInventory__c,
        Product2.COMM_WhereProductAvailable__c,
        Product2.COMM_AvailabilityDeterminedInCore__c,
        Product2.COMM_PriceDeterminedInCore__c
    };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_CreateProductInCommerce() {
        this.sObjectRep = new FW_SObjectRep();
    }

    @testVisible
    private COMM_Async_CreateProductInCommerce(FW_ISObjectRep sObjectRep, FW_IREP_JobExecution jobExecutionRep, FW_IREP_Parameters parameterRep) {
        this.sObjectRep = sObjectRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all Product records
     * that are in conditions to be created in Commerce
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        SObjectType sobjType = Schema.getGlobalDescribe().get(PRODUCT_OBJECT_NAME);
        List<String> availableIn = new List<String>{ '\'' + getParameterValue(PARAMETER_AVAILABILITY) + '\'' };

        FW_QueryBuilder query = new FW_QueryBuilder(Product2.sObjectType)
            .selectFields(CREATEPRODUCTINCOMMERCE_FIELDS)
            .selectSubquery('Products__r', new List<SObjectField>{ Product2.Id })
            .getParent()
            .setWhere('COMM_WhereProductAvailable__c includes ' + availableIn)
            .whereEquals(Product2.isActive, true)
            .whereEquals(Product2.COMM_IsIntegratedInCommerce__c, false);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the records active field to false that were obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param products List of Products that will be created in Commerce
     */
    public void execute(Database.BatchableContext bc, List<Product2> products) {
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce();
        sObjectRep.updateSObjects(productIntegrationInCommerce.getProductsIntegratedInCommerce(products, COMM_HttpCallout_Utility.HTTP_PUT_METHOD));
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}