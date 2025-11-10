/**
 * @author Daniel Reto
 * @description Subscription repository
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
public inherited sharing class COMM_REP_Subscription extends FW_SobjectRep implements COMM_IREP_Subscription {
    public static final List<SObjectField> SUBSCRIPTION_FIELDS = new List<SObjectField>{
        COMM_Subscription__c.Id,
        COMM_Subscription__c.COMM_Account__c,
        COMM_Subscription__c.COMM_Active__c,
        COMM_Subscription__c.COMM_ActiveSubscriptionRequest__c,
        COMM_Subscription__c.COMM_ActiveSubscriptionRequestRecordType__c,
        COMM_Subscription__c.COMM_ActiveSubscriptionRequestStatus__c,
        COMM_Subscription__c.COMM_Address__c,
        COMM_Subscription__c.COMM_AffiliateNumber__c,
        COMM_Subscription__c.COMM_Airport__c,
        COMM_Subscription__c.COMM_AutomaticRenewal__c,
        COMM_Subscription__c.COMM_CancellationDate__c,
        COMM_Subscription__c.COMM_CarBrand__c,
        COMM_Subscription__c.COMM_CarModel__c,
        COMM_Subscription__c.COMM_Card__c,
        COMM_Subscription__c.COMM_ChangeSubscriptionPeriodicity__c,
        COMM_Subscription__c.COMM_Contact__c,
        COMM_Subscription__c.COMM_Email__c,
        COMM_Subscription__c.COMM_EndDate__c,
        COMM_Subscription__c.COMM_FirstName__c,
        COMM_Subscription__c.COMM_InitialSubscriptionMonth__c,
        COMM_Subscription__c.COMM_JobRole__c,
        COMM_Subscription__c.LastModifiedById,
        COMM_Subscription__c.COMM_LastName__c,
        COMM_Subscription__c.COMM_LicensePlate__c,
        COMM_Subscription__c.COMM_OCIEndDate__c,
        COMM_Subscription__c.COMM_Order__c,
        COMM_Subscription__c.COMM_OrderProduct__c,
        COMM_Subscription__c.COMM_OrderSummary__c,
        COMM_Subscription__c.OwnerId,
        COMM_Subscription__c.COMM_Park__c,
        COMM_Subscription__c.COMM_Periodicity__c,
        COMM_Subscription__c.COMM_PhoneNumber__c,
        COMM_Subscription__c.COMM_Price__c,
        COMM_Subscription__c.COMM_Product__c,
        COMM_Subscription__c.RecordTypeId,
        COMM_Subscription__c.COMM_SABARejection__c,
        COMM_Subscription__c.COMM_SecondaryCarBrand__c,
        COMM_Subscription__c.COMM_SecondaryCarModel__c,
        COMM_Subscription__c.COMM_SecondaryLicensePlate__c,
        COMM_Subscription__c.COMM_StartDate__c,
        COMM_Subscription__c.COMM_Status__c,
        COMM_Subscription__c.COMM_SubCategory__c,
        COMM_Subscription__c.COMM_SubscriptionNumber__c,
        COMM_Subscription__c.COMM_SubscriptionPriceChange__c,
        COMM_Subscription__c.Name,
        COMM_Subscription__c.COMM_VATNumber__c,
        COMM_Subscription__c.CreatedById
    };

    /**
     * @description Get Subscription records by Parent Product
     *
     * @param parentProductIds Set of Product Id's to find Subscriptions for
     * @return List of Subscription
     */
    public List<COMM_Subscription__c> getSubscriptionsByParentProductIds(Set<String> parentProductIds) {
        return [
            SELECT Id, COMM_OCIEndDate__c, COMM_Product__c, COMM_Product__r.ProductCode, COMM_Product__r.COMM_ParentProduct__c
            FROM COMM_Subscription__c
            WHERE
                COMM_Product__r.COMM_ParentProduct__c IN :parentProductIds
                AND COMM_Active__c = TRUE
                AND COMM_Status__c = :COMM_DO_Subscription.STATUS_PROCESS_CONCLUDED
            WITH USER_MODE
        ];
    }

    /**
     * @description Get Subscription records by Id
     *
     * @param subscriptionIdSet Set of Subscription Id's to find Subscriptions for
     * @return List of Subscription
     */
    public List<COMM_Subscription__c> getSubscriptionsByIds(Set<Id> subscriptionIdSet) {
        return [
            SELECT Id, COMM_Account__c, COMM_Product__c, COMM_Price__c
            FROM COMM_Subscription__c
            WHERE Id IN :subscriptionIdSet
            WITH USER_MODE
        ];
    }

    /**
     * @description Get Subscription records by Account Id and optional filters
     * @example SELECT Id,COMM_Active__c,COMM_ActiveSubscriptionRequestRecordType__c,COMM_ActiveSubscriptionRequestStatus__c,
     * COMM_EndDate__c,COMM_IsRenewable__c,COMM_LicensePlate__c,COMM_Periodicity__c,COMM_Price__c,COMM_SubscriptionNumber__c,
     * COMM_Product__r.ProductCode,COMM_Product__r.COMM_Airport__c,COMM_Order__r.OrderNumber,COMM_Order__r.EffectiveDate,
     * COMM_Order__r.EndDate FROM COMM_Subscription__c WHERE COMM_Contact__c = '0039X00000Om5ycQAB' AND COMM_StartDate__c >= 2024-06-06
     * AND COMM_EndDate__c <= 2024-08-20 AND COMM_Order__r.EffectiveDate >= 2024-06-06 AND COMM_Order__r.EffectiveDate <= 2024-08-20
     * AND COMM_Order__r.OrderNumber = '1234' AND COMM_Product__r.COMM_Airport__c in ('LIS','OPO') AND COMM_Active__c = true
     * AND COMM_LicensePlate__c = '12-AV-12' AND COMM_Account__c = '0019K00000TA8IKQA1' WITH USER_MODE
     * ORDER BY COMM_EndDate__c DESC,COMM_Status__c ASC
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
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<COMM_Subscription__c> getSubscriptionsByAccountId(
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
    ) {
        //Build Query using Framework's Query Builder for dinamic query
        FW_QueryBuilder queryBuilder = new FW_QueryBuilder(COMM_Subscription__c.sObjectType)
            .selectFields(
                new List<SObjectField>{
                    COMM_Subscription__c.Id,
                    COMM_Subscription__c.COMM_Active__c,
                    COMM_Subscription__c.COMM_ActiveSubscriptionRequestRecordType__c,
                    COMM_Subscription__c.COMM_ActiveSubscriptionRequestStatus__c,
                    COMM_Subscription__c.COMM_EndDate__c,
                    COMM_Subscription__c.COMM_InRenewal__c,
                    COMM_Subscription__c.COMM_IsRenewable__c,
                    COMM_Subscription__c.COMM_LicensePlate__c,
                    COMM_Subscription__c.COMM_SecondaryLicensePlate__c,
                    COMM_Subscription__c.COMM_Periodicity__c,
                    COMM_Subscription__c.COMM_Price__c,
                    COMM_Subscription__c.COMM_StartDate__c,
                    COMM_Subscription__c.COMM_SubscriptionNumber__c
                }
            )
            .selectParentFields(COMM_Subscription__c.COMM_Product__c, new List<SObjectField>{ Product2.ProductCode, Product2.COMM_Airport__c })
            .selectParentFields(COMM_Subscription__c.COMM_Order__c, new List<SObjectField>{ Order.OrderNumber, Order.EffectiveDate, Order.EndDate })
            .selectParentFields(COMM_Subscription__c.COMM_OrderProduct__c, new List<SObjectField>{ OrderItem.ListPrice });

        //Add Optional Filters if Provided
        //Verify Date Clauses
        String dateClauses = '';
        if (orderStartDate != null && orderEndDate != null) {
            dateClauses +=
                ' AND COMM_Order__r.EffectiveDate >= ' +
                orderStartDate.format('yyyy-MM-dd') +
                ' AND COMM_Order__r.EffectiveDate <= ' +
                orderEndDate.format('yyyy-MM-dd');
        }
        if (reservationStartDate != null && reservationEndDate != null) {
            dateClauses +=
                ' AND COMM_StartDate__c <= ' +
                reservationStartDate.format('yyyy-MM-dd') +
                ' AND COMM_EndDate__c >= ' +
                reservationEndDate.format('yyyy-MM-dd');
        }
        if (String.isNotBlank(dateClauses)) {
            queryBuilder.setWhere(dateClauses.removeStart(' AND '));
        }

        //Verify remaining opcional filters
        if (String.isNotBlank(contactId)) {
            queryBuilder.whereEquals(COMM_Subscription__c.COMM_Contact__c, contactId);
        }
        if (String.isNotBlank(orderNumber)) {
            queryBuilder.whereEquals('COMM_Order__r.OrderNumber', orderNumber);
        }
        if (airportList != null && !airportList.isEmpty()) {
            queryBuilder.whereIn('COMM_Product__r.COMM_Airport__c', airportList);
        }
        if (isActive != null) {
            queryBuilder.whereEquals(COMM_Subscription__c.COMM_Active__c, isActive);
        }
        if (String.isNotBlank(licensePlate)) {
            queryBuilder.whereEquals(COMM_Subscription__c.COMM_LicensePlate__c, licensePlate);
        }
        if (String.isNotBlank(secondaryLicensePlate)) {
            queryBuilder.whereEquals(COMM_Subscription__c.COMM_SecondaryLicensePlate__c, secondaryLicensePlate);
        }
        if (String.isNotBlank(affiliateNumber)) {
            queryBuilder.whereEquals(COMM_Subscription__c.COMM_AffiliateNumber__c, affiliateNumber);
        }
        //Add Account Id to Where clause
        String query = queryBuilder.whereEquals(COMM_Subscription__c.COMM_Account__c, accountId).getQuery();

        //Add USER_MODE Security and ORDER BY End Date and Status to query
        query += ' WITH USER_MODE ORDER BY COMM_EndDate__c DESC,COMM_Status__c ASC';

        return (List<COMM_Subscription__c>) Database.query(query);
    }

    /**
     * @description Get Subscription records by Subscription Number
     *
     * @param subscriptionNumberSet Set of Subscription Numbers to find Subscriptions for
     * @return List of Subscription
     */
    public List<COMM_Subscription__c> getSubscriptionsById(Set<String> subscriptionIdSet) {
        return [
            SELECT
                Id,
                COMM_SubscriptionNumber__c,
                COMM_Order__c,
                COMM_OrderProduct__c,
                COMM_OrderSummary__c,
                COMM_Account__c,
                COMM_Contact__c,
                COMM_Price__c,
                COMM_Product__c,
                COMM_InitialSubscriptionMonth__c,
                COMM_StartDate__c,
                COMM_EndDate__c,
                COMM_LicensePlate__c,
                COMM_SecondaryLicensePlate__c,
                COMM_Periodicity__c,
                COMM_FirstName__c,
                COMM_LastName__c,
                COMM_VATNumber__c,
                COMM_PhoneNumber__c,
                COMM_Email__c,
                COMM_Address__Street__s,
                COMM_Address__City__s,
                COMM_Address__CountryCode__s,
                COMM_Address__PostalCode__s,
                COMM_Card__c
            FROM COMM_Subscription__c
            WHERE Id IN :subscriptionIdSet
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Get Subscription records by Products
     *
     * @param productIds Set of Product Id's to find Subscriptions for
     * @return List of Subscription
     */
    public List<COMM_Subscription__c> getSubscriptionsByProductIds(Set<Id> productIds) {
        return [
            SELECT Id, COMM_Product__c
            FROM COMM_Subscription__c
            WHERE COMM_Product__c IN :productIds
            WITH USER_MODE
        ];
    }
}