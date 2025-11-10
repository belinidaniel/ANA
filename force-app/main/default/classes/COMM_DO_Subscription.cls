/**
 * @author           Daniel Reto
 * @description      Subscription SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      09/04/2024       ECOMM-192: Original version
 * Sofia Silva      17/10/2025       TICKET-280170: Add payment method to Public Subscription creation (always VD)
 **/
public inherited sharing class COMM_DO_Subscription implements COMM_IDO_Subscription {
    //Subscription Record Type Values
    public final static string RECORDTYPE_PARTNER = 'COMM_Partner';
    public final static string RECORDTYPE_DIRECT_SALES = 'COMM_DirectSales';
    //Subscription Status Picklist Values
    public final static string STATUS_PROCESS_CONCLUDED = 'Process Concluded';
    public final static string STATUS_ARCHIEVED = 'Archieved';
    public final static string STATUS_WAITING_CONCLUSION = 'Waiting Conclusion';
    //Subscription Periodicity Picklist Values
    public final static string PERIODICITY_MONTHLY = 'Monthly';
    public final static string PERIODICITY_QUARTERLY = 'Quarterly';
    public final static string PERIODICITY_HALF_YEARLY = 'Half Yearly';
    public final static string PERIODICITY_YEARLY = 'Yearly';
    //Subscription Payment Method
    public final static string PAYMENT_VD = 'VD';
    public final static string PAYMENT_CREDIT = 'Credit';
    public final static string PAYMENT_COURTESY = 'Courtesy';

    /**
     * @description Define Subscription records to be created base on Order Item Summary record details.
     * @param orderItemSummary List of Order Item Summary records to process.
     * @return Subscription record to be created.
     */
    public static COMM_Subscription__c setSubscriptionToCreate(OrderItemSummary orderItemSummary) {
        COMM_Subscription__c subscriptionToCreate = new COMM_Subscription__c();
        subscriptionToCreate.COMM_Order__c = orderItemSummary.OriginalOrderItem.OrderId;
        subscriptionToCreate.COMM_OrderProduct__c = orderItemSummary.OriginalOrderItemId;
        subscriptionToCreate.COMM_OrderSummary__c = orderItemSummary.OrderSummaryId;
        subscriptionToCreate.RecordTypeId = Schema.SObjectType.COMM_Subscription__c.getRecordTypeInfosByDeveloperName()
            .get(RECORDTYPE_DIRECT_SALES)
            .RecordTypeId;
        subscriptionToCreate.COMM_Account__c = orderItemSummary.OriginalOrderItem.Order.AccountId;
        subscriptionToCreate.COMM_Contact__c = orderItemSummary.OriginalOrderItem.Order.BillToContactId;
        subscriptionToCreate.COMM_Status__c = STATUS_WAITING_CONCLUSION;
        subscriptionToCreate.COMM_Price__c = orderItemSummary.OriginalOrderItem.TotalPrice;
        subscriptionToCreate.COMM_Product__c = orderItemSummary.OriginalOrderItem.Product2Id;
        subscriptionToCreate.COMM_InitialSubscriptionMonth__c = datetime.now().format('MMMM');
        subscriptionToCreate.COMM_StartDate__c = orderItemSummary.OriginalOrderItem.COMM_ReservationStart__c?.date();
        subscriptionToCreate.COMM_EndDate__c = orderItemSummary.OriginalOrderItem.COMM_ReservationEnd__c?.date();
        subscriptionToCreate.COMM_LicensePlate__c = orderItemSummary.OriginalOrderItem.COMM_LicensePlate__c;
        subscriptionToCreate.COMM_SecondaryLicensePlate__c = orderItemSummary.OriginalOrderItem.COMM_SecondaryLicensePlate__c;
        subscriptionToCreate.COMM_AffiliateNumber__c = orderItemSummary.OriginalOrderItem.COMM_AffiliateNumber__c;
        subscriptionToCreate.COMM_Periodicity__c = orderItemSummary.OriginalOrderItem.Product2.COMM_Periodicity__c;
        subscriptionToCreate.COMM_FirstName__c = orderItemSummary.OriginalOrderItem.Order.Account.COMM_BillingFirstName__c;
        subscriptionToCreate.COMM_LastName__c = orderItemSummary.OriginalOrderItem.Order.Account.COMM_BillingLastName__c;
        subscriptionToCreate.COMM_VATNumber__c = orderItemSummary.OriginalOrderItem.Order.Account.COMM_VATNumber__c;
        subscriptionToCreate.COMM_PhoneNumber__c = orderItemSummary.OriginalOrderItem.Order.Account.IsPersonAccount ? orderItemSummary.OriginalOrderItem.Order.Account.PersonMobilePhone : orderItemSummary.OriginalOrderItem.Order.Account.Phone;
        subscriptionToCreate.COMM_Email__c = orderItemSummary.OrderSummary.Account.RecordType.DeveloperName ==
            COMM_DO_Account.PERSON_ACCOUNT_RECORD_TYPE
            ? orderItemSummary.OrderSummary.Account.PersonEmail
            : orderItemSummary.OrderSummary.Account.COMM_Email__c;
        subscriptionToCreate.COMM_Address__Street__s = orderItemSummary.OriginalOrderItem.Order.Account.BillingStreet;
        subscriptionToCreate.COMM_Address__City__s = orderItemSummary.OriginalOrderItem.Order.Account.BillingCity;
        subscriptionToCreate.COMM_Address__CountryCode__s = orderItemSummary.OriginalOrderItem.Order.Account.BillingCountryCode;
        subscriptionToCreate.COMM_Address__PostalCode__s = orderItemSummary.OriginalOrderItem.Order.Account.BillingPostalCode;
        subscriptionToCreate.COMM_PaymentMethod__c = PAYMENT_VD;

        return subscriptionToCreate;
    }
}