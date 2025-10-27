/**
 * @author Daniel Reto
 * @description Model for order details.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      27/06/2024       Original version
 * Daniel Reto      08/08/2024       ECOMM-1971: Tax Details
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_OrderDetailOutput {
    global String orderNumber;
    global String orderSummaryId;
    global Integer orderStatus;
    global Date orderDate;
    global BillingAddress billingAddress;
    global String customerEmail;
    global String customerPhoneNumber;
    global Decimal totalNet;
    global Decimal totalTaxes;
    global Decimal totalGross;
    global String currencyCode;
    global Boolean isLegacyOrder;
    global String accountId;
    global String billToContactId;
    global List<FinancialDocuments> financialDocuments;
    global List<OrderProducts> products;
    global List<TaxDetails> taxTotalsPerTaxRate;

    global class BillingAddress {
        global String name;
        global String street;
        global String zipCode;
        global String city;
        global String vat;
        global String phoneNumber;
        global String country;
        global String countryCode;
        
    }

    global class FinancialDocuments {
        global String id;
        global String docNumber;
        global String docType;
        global Date docDate;
        global String name;
        global Decimal total;
        global String currencyCode;
        global Integer status;
        global String creditMemoId;
        global String oldSAPId;
        global Boolean isInvoiceEdited;
    }

    global class OrderProducts {
        global String productCode;
        global String orderProductSummaryId;
        global String name;
        global String airport;
        global Decimal totalPrice;
        global String currencyCode;
        global String productType;
        global DateTime reservationStartDate;
        global DateTime reservationEndDate;
        global PassengerDetails passengerDetails;
        global Integer status;
    }

    global class PassengerDetails {
        global String licensePlate;
        global String secondaryLicensePlate;
        global String affiliateNumber;
        global String name;
    }

    global class TaxDetails {
        global Decimal taxRate;
        global Decimal taxValue;
    }
}