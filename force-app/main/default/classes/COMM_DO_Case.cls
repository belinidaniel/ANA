/**
 * @author           Daniel Lascas
 * @description      Case SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    18/03/2024       ECOMM-368: Original version
 * Daniel Reto      17/06/2024       New Status and RT variable
 **/
public inherited sharing class COMM_DO_Case implements COMM_IDO_Case {
    //Record Type Developer Names
    public final static string INDIVIDUAL_STAFF_REQUEST_RT = 'COMM_IndividualStaffRequest';
    public final static string SUBSCRIPTION_REQUEST_RT = 'COMM_NewSubscription';
    public final static string CHANGE_OWNERSHIP_RT = 'COMM_ChangeOwnership';
    public final static string NEW_CARD_RT = 'COMM_NewCardDueToDamageLoss';
    public final static string NEW_PUBLIC_SUBSCRIPTION_REQUEST_RT = 'COMM_NewPublicSubscription';
    public final static string RECURRING_PUBLIC_SUBSCRIPTION_REQUEST_RT = 'COMM_RecurringPublicSubscription';
    public final static string MANUAL_RENEWAL_RT = 'COMM_ManualRenewal';
    //Case Status Picklist Values
    public final static string WAITING_APPROVAL_STATUS = 'Waiting Approval';
    public final static string IN_APPROVAL_STATUS = 'In Approval';
    public final static string PROCESS_CONCLUDED_STATUS = 'Process Concluded';
    public final static string WAITING_CONCLUSION = 'Waiting Conclusion';
    public final static string ARCHIVED_STATUS = 'Archived';
    public final static string EXPIRED_STATUS = 'Expired';
    public final static string WAITING_CONCLUSION_STATUS = 'Waiting Conclusion';
    //Case Type Picklist Values
    public final static string INDIVIDUAL_STAFF_TYPE = 'Individual Staff Request';
    public final static string NEW_PUBLIC_SUBSCRIPTION_TYPE = 'New Public Subscription';
    public final static string RECURRING_PUBLIC_SUBSCRIPTION_TYPE = 'Recurring Public Subscription';

    //Case Origin Picklist Values
    public final static string WEB_ORIGIN = 'Web';

    /**
     * @description Define Case records to be created base on Subscription record details.
     * @param subscription Subscription records by airport definition.
     * @param cardByAirportMap Card product record by airport definition.
     * @param orderSummaryByIdMap Order Summary record by identifier.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary record by subscription number.
     * @param isRecurring Boolean to flag if Case is related on recurring Subscription.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static Case setCaseToCreate(
        COMM_Subscription__c subscription,
        Map<String, OrderItemSummary> cardByAirportMap,
        Map<Id, OrderSummary> orderSummaryByIdMap,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring,
        Group sabaQueue
    ) {
        Case caseToCreate = new Case();
        caseToCreate.Type = setCaseType(isRecurring);
        caseToCreate.COMM_Subscription__c = subscription.Id;
        caseToCreate.COMM_Order__c = setCaseOrder(subscription, oItemSummaryBySubscriptionNbrMap, isRecurring);
        caseToCreate.COMM_OrderProduct__c = setCaseOrderProduct(subscription, oItemSummaryBySubscriptionNbrMap, isRecurring);
        caseToCreate.RecordTypeId = setCaseRecordType(isRecurring);
        caseToCreate.AccountId = subscription.COMM_Account__c;
        caseToCreate.ContactId = subscription.COMM_Contact__c;
        caseToCreate.Status = WAITING_CONCLUSION;
        caseToCreate.COMM_SubscriptionPrice__c = subscription.COMM_Price__c;
        caseToCreate.ProductId = subscription.COMM_Product__c;
        caseToCreate.COMM_InitialSubscriptionMonth__c = setCaseInitialSubscriptionMonth(subscription, isRecurring);
        caseToCreate.COMM_StartDate__c = setCaseStartDate(subscription, oItemSummaryBySubscriptionNbrMap, isRecurring);
        caseToCreate.COMM_EndDate__c = setCaseEndDate(subscription, oItemSummaryBySubscriptionNbrMap, isRecurring);
        caseToCreate.COMM_LicensePlate__c = subscription.COMM_LicensePlate__c;
        caseToCreate.COMM_Periodicity__c = subscription.COMM_Periodicity__c;
        caseToCreate.COMM_FirstName__c = subscription.COMM_FirstName__c;
        caseToCreate.COMM_LastName__c = subscription.COMM_LastName__c;
        caseToCreate.COMM_VATNumber__c = subscription.COMM_VATNumber__c;
        caseToCreate.COMM_PhoneNumber__c = subscription.COMM_PhoneNumber__c;
        caseToCreate.SuppliedEmail = subscription.COMM_Email__c;
        caseToCreate.COMM_Address__Street__s = subscription.COMM_Address__Street__s;
        caseToCreate.COMM_Address__City__s = subscription.COMM_Address__City__s;
        caseToCreate.COMM_Address__CountryCode__s = subscription.COMM_Address__CountryCode__s;
        caseToCreate.COMM_Address__PostalCode__s = subscription.COMM_Address__PostalCode__s;
        caseToCreate.COMM_Card__c = setCaseCard(subscription, isRecurring);
        caseToCreate.COMM_NewCardRequest__c = setCaseNewCardRequest(isRecurring);
        caseToCreate.COMM_Language__c = setCaseLanguage(subscription, orderSummaryByIdMap, oItemSummaryBySubscriptionNbrMap, isRecurring);
        caseToCreate.COMM_OrderSummary__c = isRecurring == false ? subscription.COMM_OrderSummary__c : oItemSummaryBySubscriptionNbrMap.get(subscription.Id)?.OrderSummaryId;
        caseToCreate.OwnerId = sabaQueue.Id;

        if (!isRecurring) {
            for (OrderItemSummary orderItemSummary : cardByAirportMap.values()) {
                if (orderItemSummary.Product2.Id == subscription.COMM_Card__c) {
                    caseToCreate.COMM_CardPrice__c = orderItemSummary.TotalPrice;
                }
            }
        } else {
            caseToCreate.COMM_SubscriptionNumber__c = subscription.COMM_SubscriptionNumber__c;
        }

        return caseToCreate;
    }

    /**
     * @description Define Case Type of Case to create.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Case Type value.
     */
    private static String setCaseType(Boolean isRecurring) {
        return isRecurring == false ? COMM_DO_Case.NEW_PUBLIC_SUBSCRIPTION_TYPE : COMM_DO_Case.RECURRING_PUBLIC_SUBSCRIPTION_TYPE;
    }

    /**
     * @description Define related Order on Case to create.
     * @param subscription Subscription record to process.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary by existing Subscription record Number to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Order identifier
     */
    private static String setCaseOrder(
        COMM_Subscription__c subscription,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring
    ) {
        return isRecurring == false
            ? subscription.COMM_Order__c
            : oItemSummaryBySubscriptionNbrMap.get(subscription.Id).OriginalOrderItem.OrderId;
    }

    /**
     * @description Define related Order Product on Case to create.
     * @param subscription Subscription record to process.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary by existing Subscription record Number to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Order Product identifier
     */
    private static String setCaseOrderProduct(
        COMM_Subscription__c subscription,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring
    ) {
        return isRecurring == false
            ? subscription.COMM_OrderProduct__c
            : oItemSummaryBySubscriptionNbrMap.get(subscription.Id).OriginalOrderItemId;
    }

    /**
     * @description Define Record Type of Case to create.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Case Record Type identifier value.
     */
    private static String setCaseRecordType(Boolean isRecurring) {
        return isRecurring == false
            ? Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(COMM_DO_Case.NEW_PUBLIC_SUBSCRIPTION_REQUEST_RT).RecordTypeId
            : Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(COMM_DO_Case.RECURRING_PUBLIC_SUBSCRIPTION_REQUEST_RT).RecordTypeId;
    }

    /**
     * @description Define Case Initial Subscription Month.
     * @param subscription Subscription record to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Initial Month value.
     */
    private static String setCaseInitialSubscriptionMonth(COMM_Subscription__c subscription, Boolean isRecurring) {
        return isRecurring == false ? subscription.COMM_InitialSubscriptionMonth__c : datetime.now().format('MMMM');
    }

    /**
     * @description Define Case Start Date.
     * @param subscription Subscription record to process.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary by existing Subscription record Number to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return Date with Case Start Date.
     */
    private static Date setCaseStartDate(
        COMM_Subscription__c subscription,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring
    ) {
        return isRecurring == false
            ? subscription.COMM_StartDate__c
            : oItemSummaryBySubscriptionNbrMap.get(subscription.Id).OriginalOrderItem.COMM_ReservationStart__c?.date();
    }

    /**
     * @description Define Case End Date.
     * @param subscription Subscription record to process.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary by existing Subscription record Number to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return Date with Case End Date.
     */
    private static Date setCaseEndDate(
        COMM_Subscription__c subscription,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring
    ) {
        return isRecurring == false
            ? subscription.COMM_EndDate__c
            : oItemSummaryBySubscriptionNbrMap.get(subscription.Id).OriginalOrderItem.COMM_ReservationEnd__c?.date();
    }

    /**
     * @description Define Case Card.
     * @param subscription Subscription record to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Case Card identifier.
     */
    private static String setCaseCard(COMM_Subscription__c subscription, Boolean isRecurring) {
        return isRecurring == false ? subscription.COMM_Card__c : null;
    }

    /**
     * @description Define if Case has new Card request.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return Boolean to flag if Case has New Card.
     */
    private static Boolean setCaseNewCardRequest(Boolean isRecurring) {
        return isRecurring == false ? true : false;
    }

    /**
     * @description Define Case Language.
     * @param subscription Subscription record to process.
     * @param orderSummaryByIdMap Order Summary by identifier to process.
     * @param oItemSummaryBySubscriptionNbrMap Order Item Summary by existing Subscription record Number to process.
     * @param isRecurring to flag if Case is related on recurring Subscription.
     * @return String with Case language value.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String setCaseLanguage(
        COMM_Subscription__c subscription,
        Map<Id, OrderSummary> orderSummaryByIdMap,
        Map<String, OrderItemSummary> oItemSummaryBySubscriptionNbrMap,
        Boolean isRecurring
    ) {
        return isRecurring == false
            ? orderSummaryByIdMap.get(subscription.COMM_OrderSummary__c).COMM_Language__c
            : orderSummaryByIdMap.get(oItemSummaryBySubscriptionNbrMap.get(subscription.Id).OrderSummaryId).COMM_Language__c;
    }
}