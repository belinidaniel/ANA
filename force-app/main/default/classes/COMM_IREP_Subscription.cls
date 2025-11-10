/**
 * @author Daniel Reto
 * @description Subscription repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      01/04/2024       Original version
 * Daniel Reto      03/05/2024		 ECOMM-1027
 * Daniel Lascas    19/06/2024		 Added getSubscriptionsByAccountId
 * Carlos Fusco     19/06/2024		 Added getSubscriptionsByNumber
 * Miguel Justo     22/08/2024		 Updated getSubscriptionsByAccountId
 * Daniel Reto      12/11/2024		 getSubscriptionsByNumber changed to getSubscriptionsById
 **/
@SuppressWarnings('PMD.ExcessiveParameterList')
public interface COMM_IREP_Subscription extends FW_ISObjectRep {
    /**
     * @description Get Subscription records by Parent Product
     *
     * @param parentProductIds Set of Product Id's to find Subscriptions for
     * @return List of Subscription
     */
    List<COMM_Subscription__c> getSubscriptionsByParentProductIds(Set<String> parentProductIds);
    /**
     * @description Get Subscription records by Id
     *
     * @param subscriptionIdSet Set of Subscription Id's to find Subscriptions for
     * @return List of Subscription
     */
    List<COMM_Subscription__c> getSubscriptionsByIds(Set<Id> subscriptionIdSet);
    /**
     * @description Get Subscription records by Account Id and optional filters
     *
     * @param accountId Id of the Customer's Account
     * @param contactId Id of the Customer's Contact
     * @param orderStartDate Initial Starting Date of Order
     * @param orderEndDate Maximum ending Date of Order
     * @param reservationStartDate Initial Starting Date of Subscription
     * @param reservationEndDate Maximum ending Date of Subscription
     * @param orderNumber Number of the Order
     * @param airportList List of Airport Codes the Subscriptions are associated with
     * @param isActive Boolean indicating if Subscriptions to obtain are Active
     * @param licensePlate License Plate of the Vehicle associated with Subscriptions
     * @param secondaryLicensePlate Secondary License Plate of the Vehicle associated with Subscriptions
     * @param affiliateNumber Customer's affiliate number associated with Subscriptions
     * @return List of Subscription Records found with provided filters
     */
    List<COMM_Subscription__c> getSubscriptionsByAccountId(
        Id accountId,
        Id contactId,
        Datetime orderStartDate,
        Datetime orderEndDate,
        Datetime reservationStartDate,
        Datetime reservationEndDate,
        String orderNumber,
        List<String> airportList,
        Boolean isActive,
        String licensePlate,
        String secondaryLicensePlate,
        String affiliateNumber
    );
    /**
     * @description Get Subscription records by Subscription Number
     *
     * @param subscriptionIdSet Set of Subscription Numbers to find Subscriptions for
     * @return List of Subscription
     */
    List<COMM_Subscription__c> getSubscriptionsById(Set<String> subscriptionIdSet);
    /**
     * @description Get Subscription records by Products
     *
     * @param productIds Set of Product Id's to find Subscriptions for
     * @return List of Subscription
     */
    List<COMM_Subscription__c> getSubscriptionsByProductIds(Set<Id> productIds);
}