/**
 * @author Daniel Reto
 * @description Class to support the Web Service to get Orders details.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      27/06/2024       Original version
 * Daniel Reto      08/08/2024       ECOMM-1971: Tax Details
 * Jose Passos      29/08/2024       ECOMM-2018: Add accountId and billToContactId fields on the response
 **/
public inherited sharing class COMM_SL_WS_GetOrderDetails {
    private static final String INVALID_ORDERNUMBER_PARAMETER_ERROR = 'The Order Number received doesn\'t exist!';
    private static final String MAX_ATTEMPTS_TO_EDIT_INVOICE = COMM_CommerceConfiguration__mdt.getInstance('MaxAttemptsToEditInvoice').COMM_Value__c;
    /**
     * @description Check if any Order record exists for the request order number.
     * @param String orderNumberValue - Order Number to search
     * @return COMM_WS_OrderDetailOutput output with Order data
     */
    public COMM_WS_OrderDetailOutput checkOrderDetails(String orderNumberValue) {
        COMM_WS_OrderDetailOutput outputRequest = new COMM_WS_OrderDetailOutput();

        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        List<OrderSummary> orderSummaryList = orderSummaryRep.getOrderSummaryByOrderNumber(orderNumberValue);
        COMM_IREP_OrderItemTaxLineItemSummary orderItemTaxLineItemSummaryRep = new COMM_REP_OrderItemTaxLineItemSummary();
        List<OrderItemTaxLineItemSummary> orderItemTaxLineItemSummaryList = orderItemTaxLineItemSummaryRep.getOrderItemTaxLineItemSummaryByOrderSummaryNumber(
            orderNumberValue
        );

        if (orderSummaryList != null && orderSummaryList.size() > 0) {
            OrderSummary orderSummaryRecord = orderSummaryList[0];
            COMM_WS_OrderDetailOutput.BillingAddress billingAddress = new COMM_WS_OrderDetailOutput.BillingAddress();
            List<COMM_WS_OrderDetailOutput.FinancialDocuments> financialDocumentsList = new List<COMM_WS_OrderDetailOutput.FinancialDocuments>();
            List<COMM_WS_OrderDetailOutput.OrderProducts> productsList = new List<COMM_WS_OrderDetailOutput.OrderProducts>();
            List<COMM_WS_OrderDetailOutput.TaxDetails> taxTotalsPerTaxRateList = new List<COMM_WS_OrderDetailOutput.TaxDetails>();
            Map<Decimal, Decimal> taxAmountByVatPercentage = new Map<Decimal, Decimal>();

            // process Billing Address to be sent on the response
            billingAddress.name = orderSummaryRecord.COMM_BillingName__c;
            billingAddress.street = orderSummaryRecord.BillingStreet;
            billingAddress.zipCode = orderSummaryRecord.BillingPostalCode;
            billingAddress.city = orderSummaryRecord.BillingCity;
            billingAddress.vat = orderSummaryRecord.COMM_BillingVATNumber__c;
            billingAddress.phoneNumber = orderSummaryRecord.BillingPhoneNumber;
            billingAddress.countryCode = orderSummaryRecord.BillingCountryCode;

            // process Financial Documents to be sent on the response
            for (Invoice invoiceRecord : orderSummaryRecord.Invoices) {
                COMM_WS_OrderDetailOutput.FinancialDocuments financialDocumentRecord = new COMM_WS_OrderDetailOutput.FinancialDocuments();
                financialDocumentRecord.id = invoiceRecord.Id;
                financialDocumentRecord.docNumber = invoiceRecord.COMM_SAPDocumentId__c;
                financialDocumentRecord.docType = 'INVOICE';
                financialDocumentRecord.docDate = invoiceRecord.COMM_SAPIntegrationDate__c?.dateGMT();
                financialDocumentRecord.name = orderSummaryRecord.COMM_BillingName__c;
                financialDocumentRecord.total = invoiceRecord.TotalAmountWithTax;
                financialDocumentRecord.currencyCode = 'EUR';
                financialDocumentRecord.status = 0;
                financialDocumentRecord.creditMemoId = invoiceRecord.COMM_CreditMemoSAPId__c;
                financialDocumentRecord.oldSAPId = invoiceRecord.COMM_SAPDocumentId2__c;
                financialDocumentRecord.isInvoiceEdited = invoiceRecord.COMM_CreditMemoSAPId__c != null;
                financialDocumentRecord.creditMemoDate = invoiceRecord.COMM_CreditMemoSAP_Date__c;
                financialDocumentRecord.previousName = invoiceRecord.COMM_PreviousName__c;
                financialDocumentRecord.previousDocNumber = invoiceRecord.COMM_SAPDocumentId2__c;
                financialDocumentRecord.previousDocDate = invoiceRecord.COMM_PreviousDocDate__c;
                financialDocumentRecord.invoiceEditCount = Integer.valueOf(invoiceRecord.COMM_InvoiceEditCount__c);
                financialDocumentRecord.maxAttempsToEditInvoice = Integer.valueOf(MAX_ATTEMPTS_TO_EDIT_INVOICE);
                
                financialDocumentsList.add(financialDocumentRecord);
            }
            for (CreditMemo creditMemoRecord : orderSummaryRecord.CreditMemos) {
                COMM_WS_OrderDetailOutput.FinancialDocuments financialDocumentRecord = new COMM_WS_OrderDetailOutput.FinancialDocuments();
                financialDocumentRecord.id = creditMemoRecord.Id;
                financialDocumentRecord.docNumber = creditMemoRecord.COMM_SAPDocumentId__c;
                financialDocumentRecord.docType = 'CREDIT_NOTE';
                financialDocumentRecord.docDate = creditMemoRecord.COMM_SAPIntegrationDate__c?.dateGMT();
                financialDocumentRecord.name = orderSummaryRecord.COMM_BillingName__c;
                financialDocumentRecord.total = creditMemoRecord.TotalAmountWithTax;
                financialDocumentRecord.currencyCode = 'EUR';
                financialDocumentRecord.status = 1;
                financialDocumentsList.add(financialDocumentRecord);
            }

            // process Order Products to be sent on the response
            for (OrderItemSummary orderItemSummaryRecord : orderSummaryRecord.OrderItemSummaries) {
                COMM_WS_OrderDetailOutput.PassengerDetails passengerDetailsRecord = new COMM_WS_OrderDetailOutput.PassengerDetails();
                passengerDetailsRecord.licensePlate = orderItemSummaryRecord.COMM_LicensePlate__c;
                passengerDetailsRecord.secondaryLicensePlate = orderItemSummaryRecord.COMM_SecondaryLicensePlate__c;
                passengerDetailsRecord.name = orderItemSummaryRecord.COMM_ReservationName__c;
                passengerDetailsRecord.affiliateNumber = orderItemSummaryRecord.COMM_AffiliateNumber__c;

                COMM_WS_OrderDetailOutput.OrderProducts orderProductRecord = new COMM_WS_OrderDetailOutput.OrderProducts();
                orderProductRecord.productCode = orderItemSummaryRecord.Product2?.ProductCode;
                orderProductRecord.orderProductSummaryId = orderItemSummaryRecord.Id;
                orderProductRecord.name = orderItemSummaryRecord.Product2?.Name;
                orderProductRecord.airport = orderItemSummaryRecord.Product2?.COMM_Airport__c;
                orderProductRecord.totalPrice = orderItemSummaryRecord.TotalAmtWithTax;
                orderProductRecord.currencyCode = 'EUR';
                orderProductRecord.productType = COMM_DO_Product2.getFilterProductFamilyCodes(
                    new Set<String>{ orderItemSummaryRecord.Product2?.Family }
                )[0];
                String timezone = (orderItemSummaryRecord.Product2.COMM_TimeZoneByAirport__c == null
                    ? 'null'
                    : orderItemSummaryRecord.Product2.COMM_TimeZoneByAirport__c);
                if (orderItemSummaryRecord.COMM_ReservationStart__c != null) {
                    orderProductRecord.reservationStartDate = DateTime.valueOfGMT(
                        orderItemSummaryRecord.COMM_ReservationStart__c.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, timezone)
                    );
                }
                if (orderItemSummaryRecord.COMM_ReservationEnd__c != null) {
                    orderProductRecord.reservationEndDate = DateTime.valueOfGMT(
                        orderItemSummaryRecord.COMM_ReservationEnd__c.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, timezone)
                    );
                }
                orderProductRecord.passengerDetails = passengerDetailsRecord;
                orderProductRecord.status = COMM_DO_OrderItemSummary.getFilterStatusCodes(orderItemSummaryRecord.Status);
                productsList.add(orderProductRecord);
            }

            // process Tax Details to be sent on the response
            for (OrderItemTaxLineItemSummary orderItemTaxLineItemSummaryRecord : orderItemTaxLineItemSummaryList) {
                if (!taxAmountByVatPercentage.containsKey(orderItemTaxLineItemSummaryRecord.Rate)) {
                    taxAmountByVatPercentage.put(orderItemTaxLineItemSummaryRecord.Rate, 0.0);
                }
                Decimal sum = taxAmountByVatPercentage.get(orderItemTaxLineItemSummaryRecord.Rate) + orderItemTaxLineItemSummaryRecord.Amount;
                taxAmountByVatPercentage.put(orderItemTaxLineItemSummaryRecord.Rate, sum);
            }
            for (Decimal taxPercentage : taxAmountByVatPercentage.keySet()) {
                COMM_WS_OrderDetailOutput.TaxDetails taxDetailsRecord = new COMM_WS_OrderDetailOutput.TaxDetails();
                taxDetailsRecord.taxRate = taxPercentage;
                taxDetailsRecord.taxValue = taxAmountByVatPercentage.get(taxPercentage);
                taxTotalsPerTaxRateList.add(taxDetailsRecord);
            }

            outputRequest.orderNumber = orderSummaryRecord.OrderNumber;
            outputRequest.orderSummaryId = orderSummaryRecord.Id;
            outputRequest.orderStatus = COMM_DO_OrderSummary.getFilterStatusCodes(orderSummaryRecord.Status);
            outputRequest.orderDate = orderSummaryRecord.OrderedDate?.dateGMT();
            outputRequest.billingAddress = billingAddress;
            outputRequest.customerEmail = orderSummaryRecord.BillingEmailAddress;
            outputRequest.customerPhoneNumber = orderSummaryRecord.Account?.Phone;
            outputRequest.totalNet = orderSummaryRecord.TotalAmount;
            outputRequest.totalTaxes = orderSummaryRecord.TotalTaxAmount;
            outputRequest.totalGross = orderSummaryRecord.GrandTotalAmount;
            outputRequest.currencyCode = 'EUR';
            outputRequest.accountId = orderSummaryRecord.AccountId;
            outputRequest.billToContactId = orderSummaryRecord.BillToContactId;
            outputRequest.isLegacyOrder = orderSummaryRecord.COMM_isLegacyOrder__c;
            outputRequest.financialDocuments = financialDocumentsList;
            outputRequest.products = productsList;
            outputRequest.taxTotalsPerTaxRate = taxTotalsPerTaxRateList;
        } else {
            throw new COMM_SL_WS_GetOrderDetailsException(INVALID_ORDERNUMBER_PARAMETER_ERROR);
        }

        return outputRequest;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_GetOrderDetailsException extends Exception {
    }
}