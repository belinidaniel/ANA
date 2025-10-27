/**
 * @author Ruben Rodrigues
 * @description Batch class to create records on the Product Readiness SObject based on rules defined on the Product Setting SObject.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues 09/04/2024      Original version
 **/
public with sharing class COMM_Async_ProductValidation extends FW_AsyncHandler implements Database.Batchable<sObject>, Database.Stateful {
    private FW_ISObjectRep sObjectRep;
    private COMM_SL_ProductValidation productValidationSl;

    public static final List<SObjectField> PRODUCT_FIELDS = new List<SObjectField>{
        Product2.Id,
        Product2.Family,
        Product2.IsActive,
        Product2.COMM_ValidFrom__c,
        Product2.COMM_ValidTo__c,
        Product2.COMM_IsIntegratedInCommerce__c,
        Product2.COMM_HasUpdateForCommerce__c,
        Product2.COMM_ParentProduct__c,
        Product2.ProductCode
    };

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_ProductValidation() {
        this.sObjectRep = new FW_SObjectRep();
        this.productValidationSl = new COMM_SL_ProductValidation();
    }

    @testVisible
    private COMM_Async_ProductValidation(
        FW_ISObjectRep sObjectRep,
        COMM_SL_ProductValidation productValidationSl,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.sObjectRep = sObjectRep;
        this.productValidationSl = productValidationSl;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. Initiates query to obtain all Product records.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        //Build Query. Retrieve Products and their respective Pricebook Entries and Capacities.
        //@example SELECT Id,Family,IsActive,COMM_ValidFrom__c,COMM_ValidTo__c,COMM_IsIntegratedInCommerce__c,COMM_HasUpdateForCommerce__c,
        //COMM_ParentProduct__c,ProductCode,(SELECT Id,UnitPrice,COMM_First15MinuteUnit__c,COMM_Second15MinuteUnit__c,COMM_Third15MinuteUnit__c,
        //COMM_Remaining15MinuteUnit__c,COMM_FirstPeriodStartDay__c,COMM_FirstPeriodEndDay__c,COMM_FirstPeriodDailyMaximum__c,
        //Pricebook2.IsStandard FROM PricebookEntries WHERE IsActive = true),(SELECT Id FROM Capacities__r
        //WHERE COMM_Active__c = true AND COMM_IsDefaultCapacity__c = true AND COMM_ProcessStatus__c in ('COMPLETED','PENDING')) FROM Product2
        FW_QueryBuilder query = new FW_QueryBuilder(Product2.sObjectType)
            .selectFields(PRODUCT_FIELDS)
            .selectSubquery(
                'PricebookEntries',
                new List<SObjectField>{
                    PricebookEntry.Id,
                    PricebookEntry.UnitPrice,
                    PricebookEntry.COMM_First15MinuteUnit__c,
                    PricebookEntry.COMM_Second15MinuteUnit__c,
                    PricebookEntry.COMM_Third15MinuteUnit__c,
                    PricebookEntry.COMM_Remaining15MinuteUnit__c,
                    PricebookEntry.COMM_FirstPeriodStartDay__c,
                    PricebookEntry.COMM_FirstPeriodEndDay__c,
                    PricebookEntry.COMM_FirstPeriodDailyMaximum__c
                }
            )
            .selectParentFields(PricebookEntry.Pricebook2Id, new List<SObjectField>{ Pricebook2.IsStandard })
            .whereEquals(PricebookEntry.IsActive, true)
            .getParent()
            .selectSubquery('Capacities__r', new List<SObjectField>{ COMM_Capacity__c.Id })
            .whereEquals(COMM_Capacity__c.COMM_Active__c, true)
            .whereEquals(COMM_Capacity__c.COMM_IsDefaultCapacity__c, true)
            .whereIn(
                COMM_Capacity__c.COMM_ProcessStatus__c,
                new List<String>{ COMM_DO_Capacity.PROCESS_STATUS_COMPLETED, COMM_DO_Capacity.PROCESS_STATUS_PENDING }
            )
            .getParent();

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method.
     *
     * @param bc Context Information of the executed batch
     * @param controllerList List of Product2 Records to verify validation
     */
    public void execute(Database.BatchableContext bc, List<Product2> records) {
        //Call SL Class to obtain Product Readiness Records
        List<COMM_ProductReadiness__c> prList = productValidationSl.verifyReadiness(records);

        if (!prList.isEmpty()) {
            sObjectRep.upsertSObjects(prList, COMM_ProductReadiness__c.Name);
        }
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