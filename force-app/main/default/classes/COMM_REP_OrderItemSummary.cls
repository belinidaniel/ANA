/**
 * @author Rui Salgado
 * @description OrderItemSummary selector class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado          01/04/2024       Original version
 * Diogo Gonçalves      01/04/2024       ECOMM-105: Added getOrderItemSummariesById and getWithQRCode
 * Diogo Gonçalves      01/04/2024       ECOMM-481: Added getForGiftCard
 * Diogo Gonçalves      10/05/2024       ECOMM-133: Added field to query in getOrderItemSummariesById
 * Diogo Gonçalves      19/06/2024       ECOMM-1420 Change the name of the method getWithQRCode and query conditions
 * Daniel Reto          12/08/2024       ECOMM-1945: timezone changes
 * Jose Passos          27/08/2024       ECOMM-2123: Fix Download Voucher Service
 * Daniel Reto          12/08/2024       ECOMM-327
 **/
public inherited sharing class COMM_REP_OrderItemSummary extends FW_SobjectRep implements COMM_IREP_OrderItemSummary {
    /**
     * @description OrderItemSummary records field list
     */
    public static final List<SObjectField> ORDERITEMSUMMARY_FIELDS = new List<SObjectField>{
        OrderItemSummary.Id,
        OrderItemSummary.COMM_ReservationEnd__c,
        OrderItemSummary.COMM_ReservationStart__c,
        orderItemSummary.COMM_SetupInitialStock__c,
        OrderItemSummary.Product2Id,
        OrderItemSummary.COMM_TimeZoneByAirport__c
    };

    /**
     * @description Selects OrderItemSummary records for CPMS communication based on the Id list
     * @param OrderItemSummary List of the Ids
     * @return List of OrderItemSummary
     */
    public List<OrderItemSummary> getForCPMS(List<Id> orderItemSummaryIds) {
        return [
            SELECT
                Id,
                OrderSummaryId,
                Status,
                COMM_ReservationStart__c,
                COMM_ReservationEnd__c,
                COMM_ReservationName__c,
                COMM_ReservationIdCPMS__c,
                COMM_TimeZoneByAirport__c,
                COMM_BarcodeType__c,
                COMM_Barcode__c,
                COMM_CPMSStatus__c,
                OrderDeliveryGroupSummary.EmailAddress,
                OrderDeliveryGroupSummary.PhoneNumber
            FROM OrderItemSummary
            WHERE ID IN :orderItemSummaryIds
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Retrieve a list of Order Item Summaries that have a specific Id
     * @param {List<String>}
     * @return {List<OrderItemSummary>}
     */
    public List<OrderItemSummary> getOrderItemSummariesById(List<String> ids) {
        return [
            SELECT
                Id,
                Status,
                OrderSummaryId,
                OriginalOrderItemId,
                TotalPrice,
                COMM_SubscriptionNumber__c,
                COMM_ReservationStart__c,
                COMM_TimeZoneByAirport__c,
                OrderSummary.Account.COMM_Email__c,
                OrderSummary.Account.PersonEmail,
                OrderSummary.Account.RecordType.DeveloperName,
                OrderSummary.COMM_Language__c,
                OriginalOrderItem.OrderId,
                OriginalOrderItem.TotalPrice,
                OriginalOrderItem.Product2Id,
                OriginalOrderItem.COMM_ReservationStart__c,
                OriginalOrderItem.COMM_ReservationEnd__c,
                OriginalOrderItem.COMM_LicensePlate__c,
                OriginalOrderItem.Order.AccountId,
                OriginalOrderItem.Order.BillToContactId,
                OriginalOrderItem.Order.Account.COMM_BillingFirstName__c,
                OriginalOrderItem.Order.Account.COMM_BillingLastName__c,
                OriginalOrderItem.Order.Account.COMM_VATNumber__c,
                OriginalOrderItem.Order.Account.IsPersonAccount,
                OriginalOrderItem.Order.Account.PersonMobilePhone,
                OriginalOrderItem.Order.Account.Phone,
                OriginalOrderItem.Order.Account.BillingStreet,
                OriginalOrderItem.Order.Account.BillingCity,
                OriginalOrderItem.Order.Account.BillingCountryCode,
                OriginalOrderItem.Order.Account.BillingPostalCode,
                OriginalOrderItem.Product2.COMM_Periodicity__c,
                OriginalOrderItem.Product2.COMM_Airport__c,
                OriginalOrderItem.Product2.COMM_ParentProduct__c,
                Product2Id,
                Product2.Family,
                Product2.COMM_SubCategory__c,
                Product2.COMM_Airport__c,
                Product2.COMM_ParentProduct__c
            FROM OrderItemSummary
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Retrieve Order Item Summaries with a QRCode
     * @param {List<String>} orderSummaryIds
     * @return {List<OrderItemSummary>}
     */
    public List<OrderItemSummary> getForVoucherPDF(List<String> orderSummaryIds, List<String> orderItemSummaryIds) {
        String returnedStatus = COMM_DO_OrderItemSummary.RETURNED_STATUS;
        if (orderItemSummaryIds == null) {
            return [
                SELECT
                    Id,
                    Product2.Name,
                    Type,
                    COMM_ReservationStart__c,
                    COMM_ReservationName__c,
                    COMM_QRCodeImage__c,
                    COMM_TimeZoneByAirport__c,
                    Product2.Family,
                    COMM_ReservationEnd__c,
                    COMM_LicensePlate__c
                FROM OrderItemSummary
                WHERE OrderSummaryId IN :orderSummaryIds AND (COMM_QRCode__c != NULL OR COMM_Barcode__c != NULL) AND Status != :returnedStatus
                WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
            ];
        } else {
            return [
                SELECT
                    Id,
                    Product2.Name,
                    Type,
                    COMM_ReservationStart__c,
                    COMM_ReservationName__c,
                    COMM_QRCodeImage__c,
                    COMM_TimeZoneByAirport__c,
                    Product2.Family,
                    COMM_ReservationEnd__c,
                    COMM_LicensePlate__c
                FROM OrderItemSummary
                WHERE
                    OrderSummaryId IN :orderSummaryIds
                    AND Id IN :orderItemSummaryIds
                    AND (COMM_QRCode__c != NULL
                    OR COMM_Barcode__c != NULL)
                    AND Status != :returnedStatus
                WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
            ];
        }
    }

    /**
     * @description Retrieves the order item summaries to create a gift card
     * @param {List<String>} orderSummaryIds
     * @return {List<OrderItemSummary>}
     */
    public List<OrderItemSummary> getForGiftCard(List<String> ids) {
        return [
            SELECT
                Id,
                Product2.Family,
                Product2.COMM_Airport__c,
                COMM_ReservationStart__c,
                COMM_TimeZoneByAirport__c,
                TotalAmtWithTax,
                OrderDeliveryGroupSummary.EmailAddress,
                Product2.Description,
                OrderSummaryId,
                OrderSummary.OrderNumber,
                OrderSummary.Account.Name,
                Quantity
            FROM OrderItemSummary
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieve a list of Order Item Summaries that have a specific Order Summary Id
     * @param orderSummaryId Order Summary Id
     * @return List<OrderItemSummary>
     */
    public List<OrderItemSummary> getOrderItemSummariesByOrderSummaryId(String orderSummaryId) {
        return [
            SELECT
                Id,
            	Description,
                Status,
                OrderSummaryId,
                OriginalOrderItemId,
                COMM_Barcode__c,
                COMM_BundleLineId__c,
                COMM_OrderItemReferenceNumber__c,
                COMM_QRCode__c,
                Product2Id,
                Product2.Family,
            	Product2.COMM_SAPLocation__c,
            	Product2.StockKeepingUnit,
            	Product2.COMM_Tax__c,
            	TotalLineAmount,
            	TotalTaxAmount,
            	Type
            FROM OrderItemSummary
            WHERE OrderSummaryId =: orderSummaryId
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }
}