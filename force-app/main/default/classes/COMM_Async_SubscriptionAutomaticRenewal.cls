/**
 * @author Daniel Reto
 * @description Batch class to create a Subscription Invoice platform event and update the subscription End Date
 * when automatic renewal is set to true, based on parameters defined in the Batch Definition Record
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      11/04/2024      ECOMM-204: Original version
 * Daniel Reto      06/05/2024      ECOMM-1031: Calculate Subscription Price and Product based on Periodicity
 * Daniel Reto      17/06/2024      New filter added on start query | Record Type
 **/
public with sharing class COMM_Async_SubscriptionAutomaticRenewal extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    // CRON: 0 0 7 L * ?

    private COMM_IREP_Subscription subscriptionRep;
    //private COMM_IREP_SubscriptionInvoice subscriptionInvoiceRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_SubscriptionAutomaticRenewal() {
        this.subscriptionRep = new COMM_REP_Subscription();
        //this.subscriptionInvoiceRep = new COMM_REP_SubscriptionInvoice();
    }

    @testVisible
    private COMM_Async_SubscriptionAutomaticRenewal(
        COMM_IREP_Subscription subscriptionRep,
        //COMM_IREP_SubscriptionInvoice subscriptionInvoiceRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.subscriptionRep = subscriptionRep;
        //this.subscriptionInvoiceRep = subscriptionInvoiceRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field is set in the past.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        FW_QueryBuilder query = new FW_QueryBuilder(COMM_Subscription__c.SObjectType)
            .selectFields(COMM_REP_Subscription.SUBSCRIPTION_FIELDS)
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode })
            .selectParentFields(COMM_Subscription__c.COMM_ChangeSubscriptionPeriodicity__c, new List<SObjectField>{ Product2.COMM_Periodicity__c })
            .setWhere('COMM_EndDate__c = ' + String.valueOf(Date.today()).split(' ').get(0))
            .whereEquals('COMM_AutomaticRenewal__c', true)
            .whereEquals('COMM_Active__c', true)
            .whereEquals('COMM_Status__c', COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED)
            .whereEquals('RecordType.DeveloperName', COMM_DO_Subscription.RECORDTYPE_PARTNER);

        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Updates the records active field to false that were obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param subscriptionList List of COMM_Subscription__c that will be renewed
     */
    public void execute(Database.BatchableContext bc, List<COMM_Subscription__c> subscriptionList) {
        List<COMM_Subscription__c> subscriptionsToUpdateList = new List<COMM_Subscription__c>();
        List<COMM_SubscriptionInvoiceGenerator__e> subscriptionInvoicePlatformEventList = new List<COMM_SubscriptionInvoiceGenerator__e>();

        for (COMM_Subscription__c subscriptionRecord : subscriptionList) {
            Date newEndDateYear;
            if (!String.isBlank(subscriptionRecord.COMM_ChangeSubscriptionPeriodicity__c)) {
                newEndDateYear = Date.today()
                    .addMonths(COMM_GEN_Utility.getMonthValueToAdd(subscriptionRecord.COMM_ChangeSubscriptionPeriodicity__r.COMM_Periodicity__c));
            } else {
                newEndDateYear = Date.today().addMonths(COMM_GEN_Utility.getMonthValueToAdd(subscriptionRecord.COMM_Periodicity__c));
            }
            Integer daysInMonth = Date.daysInMonth(newEndDateYear.year(), newEndDateYear.month());
            COMM_Subscription__c recordToUpdate = new COMM_Subscription__c(
                Id = subscriptionRecord.Id,
                COMM_EndDate__c = Date.newInstance(newEndDateYear.year(), newEndDateYear.month(), daysInMonth)
            );
            if (!String.isBlank(subscriptionRecord.COMM_ChangeSubscriptionPeriodicity__c)) {
                recordToUpdate.COMM_Periodicity__c = subscriptionRecord.COMM_ChangeSubscriptionPeriodicity__r.COMM_Periodicity__c;
                recordToUpdate.COMM_Product__c = subscriptionRecord.COMM_ChangeSubscriptionPeriodicity__c;
                recordToUpdate.COMM_Price__c = subscriptionRecord.COMM_SubscriptionPriceChange__c;
                recordToUpdate.COMM_ChangeSubscriptionPeriodicity__c = null;
                recordToUpdate.COMM_SubscriptionPriceChange__c = null;
            }else{
                //Calculate price for current pricebooks
                Decimal price = calculatePrice(subscriptionRecord.COMM_Product__r.ProductCode, Date.today());
                
                if(price != null){
                    recordToUpdate.COMM_Price__c = price;
                }                
            }
            subscriptionsToUpdateList.add(recordToUpdate);
            subscriptionInvoicePlatformEventList.add(new COMM_SubscriptionInvoiceGenerator__e(COMM_SubscriptionId__c = subscriptionRecord.Id));
        }

        if (!subscriptionsToUpdateList.isEmpty()) {
            subscriptionRep.updateSObjects(subscriptionsToUpdateList);
            EventBus.publish(subscriptionInvoicePlatformEventList);
        }
    }


    private static Decimal calculatePrice(String productCodes, Date priceDate){
        COMM_REP_PricebookEntry priceBookEntryREP = new COMM_REP_PricebookEntry();
        List<PricebookEntry> priceBookEntries = priceBookEntryREP.getPBEByProductCodeList(new Set<String>{productCodes});

        COMM_SL_PricingCalculation pricingCalculationService = new COMM_SL_PricingCalculation();
        Map<PricebookEntry, Decimal> priceByPBE = pricingCalculationService.getPriceByPBE(priceBookEntries, priceDate, priceDate);

        if(priceByPBE.isEmpty()){
            return null;
        }
        return priceByPBE.values()[0];
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