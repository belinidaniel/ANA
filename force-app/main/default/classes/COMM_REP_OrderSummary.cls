/**
 * @author Diogo Gonçalves
 * @description OrderSummary selector class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      08/04/2024       Original version
 * Diogo Gonçalves      01/07/2024       ECOMM-1557: Added getForVoucherPDFService
 * Daniel Reto		    03/07/2024       Added getOrderSummaryById
 * Diogo Gonçalves      17/09/2024       ECOMM-481: Added the field Account.Name
 * Daniel Reto		    30/10/2024       ECOMM-327
 * Daniel Reto          06/11/2024       ECOMM-327: New Method
 **/
public inherited sharing class COMM_REP_OrderSummary extends FW_SobjectRep implements COMM_IREP_OrderSummary {
    public static final List<SObjectField> ORDERSUMMARY_FIELDS = new List<SObjectField>{
        OrderSummary.Id,
        OrderSummary.AccountId,
        OrderSummary.COMM_ResellerVoucherStatus__c,
        OrderSummary.COMM_ResellerVoucherStatusDate__c,
        OrderSummary.COMM_SalesforceOrderId__c,
        OrderSummary.OriginalOrderId
    };

    /**
     * @description Selects OrderSummary records based on the Id list
     * @param ordersummaryIds List of the Ids
     * @return List of OrderSummary
     */
    public List<OrderSummary> getByIds(List<String> ordersummaryIds) {
        return [
            SELECT
                Id,
                AccountId,
                Account.PersonContactId,
                Account.PersonEmail,
                Account.Name,
                COMM_Language__c,
                OrderNumber,
                Account.PersonContact.Name,
                BillingEmailAddress,
                BillToContactId,
                OriginalOrder.GrandTotalAmount,
                (SELECT id, COMM_SAPDocumentId__c, COMM_IssuanceDate__c, TotalAmount, COMM_CreditMemoSAPId__c FROM Invoices),
                (SELECT Id, Status, Type, TypeCode FROM OrderItemSummaries),
                (SELECT EmailAddress FROM OrderDeliveryGroupSummaries ORDER BY id DESC LIMIT 1)
            FROM OrderSummary
            WHERE Id IN :ordersummaryIds
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Selects OrderSummary records based on the an Order Number list, to be used in COMM_WS_VoucherPDF
     * @param orderNumbers List of the OrderNumbers
     * @return List of OrderSummary
     */
    public List<OrderSummary> getForVoucherPDFService(List<String> orderNumbers) {
        return [
            SELECT Id, AccountId, COMM_Language__c, (SELECT EmailAddress FROM OrderDeliveryGroupSummaries)
            FROM OrderSummary
            WHERE OrderNumber IN :orderNumbers
            WITH SECURITY_ENFORCED // This is required for the flow to work. With USER_MODE it fails with permission issues on user autoproc.
        ];
    }

    /**
     * @description Retrieves the order item summaries to to send for Commerce side while doing a Search Order
     * @param COMM_WS_SearchOrdersInput inputRequest
     * @param String orderSummaryExtraFilter : request key matched with Salesforce Field to add on Order Summary query filter
     * @return {List<OrderSummary>}
     */
    public List<OrderSummary> getForSearchOrder(COMM_WS_SearchOrdersInput inputRequest, String orderSummaryExtraFilter) {
        // generate query with oupput required fields
        FW_QueryBuilder orderItemSummayQuery = new FW_QueryBuilder(OrderItemSummary.SObjectType)
            .selectFields(new List<SObjectField>{ OrderItemSummary.Id })
            .selectParentFields(OrderItemSummary.Product2Id, new List<SObjectField>{ Product2.Family, Product2.COMM_Airport__c });

        FW_QueryBuilder orderSummayQuery = new FW_QueryBuilder(OrderSummary.SObjectType)
            .selectFields(
                new List<SObjectField>{
                    OrderSummary.Id,
                    OrderSummary.GrandTotalAmount,
                    OrderSummary.Status,
                    OrderSummary.OrderNumber,
                    OrderSummary.OrderedDate,
                    OrderSummary.COMM_MaxReservationEnd__c,
                    OrderSummary.COMM_IsLegacyOrder__c
                }
            );
        // add extra filter
        if (String.isNotBlank(orderSummaryExtraFilter)) {
            orderSummayQuery.setWhere(orderSummaryExtraFilter);
        }
        // apply filters on orderSummayQuery
        if (inputRequest.orderStartDate != null) {
            orderSummayQuery.setWhere(
                (String.isNotBlank(orderSummaryExtraFilter) ? orderSummaryExtraFilter : '') +
                    ' AND OrderedDate >= ' +
                    COMM_GEN_Utility.generateDateTimeDataType(inputRequest.orderStartDate).format(COMM_GEN_Utility.TIME_FORMAT) +
                    ' AND OrderedDate <= ' +
                    COMM_GEN_Utility.generateDateTimeDataType(inputRequest.orderEndDate)
                        .addDays(1)
                        .addSeconds(-1)
                        .format(COMM_GEN_Utility.TIME_FORMAT)
            );
        }
        if (inputRequest.status != null && !inputRequest.status.isEmpty()) {
            orderSummayQuery.whereIn('Status', COMM_DO_OrderSummary.getFilterStatusAPI(inputRequest.status));
        }
        if (inputRequest.orderNumber != null) {
            orderSummayQuery.whereEquals('OrderNumber', inputRequest.orderNumber);
        }
        orderSummayQuery.orderByDesc(Order.OrderedDate);
        orderSummayQuery.orderByAsc(Order.Status);
        orderSummayQuery.orderByAsc(Order.OrderNumber);

        FW_QueryBuilder orderItemSummayWhereClauseQuery = new FW_QueryBuilder(OrderItemSummary.SObjectType)
            .selectFields(new List<SObjectField>{ OrderItemSummary.OrderSummaryId });
        // apply filters on orderItemSummayWhereClauseQuery
        if (inputRequest.reservationStartDate != null) {
            orderItemSummayWhereClauseQuery.setWhere(
                'COMM_ReservationStart__c >= ' +
                    COMM_GEN_Utility.generateDateTimeDataType(inputRequest.reservationStartDate).format(COMM_GEN_Utility.TIME_FORMAT) +
                    ' AND COMM_ReservationStart__c <= ' +
                    COMM_GEN_Utility.generateDateTimeDataType(inputRequest.reservationEndDate)
                        .addDays(1)
                        .addSeconds(-1)
                        .format(COMM_GEN_Utility.TIME_FORMAT)
            );
        }
        if (inputRequest.licensePlate != null) {
            orderItemSummayWhereClauseQuery.whereEquals('COMM_LicensePlate__c', inputRequest.licensePlate);
        }
        if (inputRequest.secondaryLicensePlate != null) {
            orderItemSummayWhereClauseQuery.whereEquals('COMM_SecondaryLicensePlate__c', inputRequest.secondaryLicensePlate);
        }
        if (inputRequest.affiliateNumber != null) {
            orderItemSummayWhereClauseQuery.whereEquals('COMM_AffiliateNumber__c,', inputRequest.affiliateNumber);
        }
        if (inputRequest.productTypes != null && !inputRequest.productTypes.isEmpty()) {
            orderItemSummayWhereClauseQuery.whereIn('Product2.Family', COMM_DO_Product2.getFilterProductFamilyAPI(inputRequest.productTypes));
        }
        if (inputRequest.airports != null && !inputRequest.airports.isEmpty()) {
            orderItemSummayWhereClauseQuery.whereIn('Product2.COMM_Airport__c', inputRequest.airports);
        }
        String query = orderSummayQuery.getQuery().replace(' FROM', ',(' + orderItemSummayQuery.getQuery() + ') FROM');
        query = query.replace('OrderItemSummary', 'OrderItemSummaries');
        query = query.replace('ORDER BY', 'WITH SECURITY_ENFORCED ORDER BY');
        if (orderItemSummayWhereClauseQuery.getQuery().contains(' WHERE ')) {
            query = query.replace('WITH SECURITY_ENFORCED', 'AND Id IN (' + orderItemSummayWhereClauseQuery.getQuery() + ') WITH SECURITY_ENFORCED');
        }

        return Database.query(query);
    }

    /**
     * @description Retrieves the order item summaries to to send for Commerce side while doing a Search Order
     * @param String orderNumberValue : Order Summary Order Number to search
     * @return {List<OrderSummary>}
     */
    public List<OrderSummary> getOrderSummaryByOrderNumber(String orderNumberValue) {
        return [
            SELECT
                Id,
                OrderNumber,
                AccountId,
                BillToContactId,
                Account.Phone,
                Status,
                OrderedDate,
                COMM_BillingName__c,
                BillingEmailAddress,
                BillingStreet,
                BillingPostalCode,
                BillingCity,
            	BillingCountry,
            	BillingCountryCode,
                COMM_BillingVATNumber__c,
                BillingPhoneNumber,
                TotalAmount,
                TotalTaxAmount,
                GrandTotalAmount,
                COMM_IsLegacyOrder__c,
                (
                    SELECT Id, COMM_SAPIntegrationDate__c, COMM_SAPDocumentId__c, TotalAmountWithTax, COMM_CreditMemoSAPId__c, COMM_SAPDocumentId2__c
                    FROM Invoices
                ),
                (
                    SELECT Id, COMM_SAPIntegrationDate__c, COMM_SAPDocumentId__c, TotalAmountWithTax
                    FROM CreditMemos
                ),
                (
                    SELECT
                        Id,
                        COMM_LicensePlate__c,
                        COMM_SecondaryLicensePlate__c,
                        COMM_AffiliateNumber__c,
                        COMM_ReservationName__c,
                        COMM_ReservationStart__c,
                        COMM_ReservationEnd__c,
                        Product2Id,
                        Product2.ProductCode,
                        Product2.Name,
                        Product2.COMM_Airport__c,
                        Product2.Family,
                        Product2.COMM_TimeZoneByAirport__c,
                        TotalAmtWithTax,
                        Status
                    FROM OrderItemSummaries
                    WHERE Type = 'Order Product'
                )
            FROM OrderSummary
            WHERE OrderNumber = :orderNumberValue
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves the order summaries while doing a Cancel Reseller Order
     * @param resellerId : reseller Id on related Account to search
     * @param salesforceOrderId : merge field between Salesforce and Order sent from Mulesoft, to search
     * @return {List<OrderSummary>}
     */
    public List<OrderSummary> getOrderSummaryByCOMMSalesforceOrderId(String resellerId, String salesforceOrderId) {
        return [
            SELECT
                Id,
                (
                    SELECT
                        Id,
                        COMM_OrderItemReferenceNumber__c,
                        Status
                    FROM OrderItemSummaries
                    WHERE Type = 'Order Product'
                )
            FROM OrderSummary
            WHERE COMM_SalesforceOrderId__c =: salesforceOrderId AND Account.COMM_ResellerId__c =: resellerId
            WITH SECURITY_ENFORCED
        ];
    }
}