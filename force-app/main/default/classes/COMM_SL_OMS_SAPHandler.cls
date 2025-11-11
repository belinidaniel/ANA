/**
 * @author Rui Salgado
 * @description Service for SAP Communication
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      19/04/2024       Original version
 * Daniel Reto      05/06/2024       ECOMM-307: Credit Memo and Credit Payment Handlers
 * Jose Passos      25/06/2024       ECOMM-1523: Get Billing VAT and Name from Order instead of the Account and use COMM_Email__c or PersonEmail
 * Jose Passos      25/06/2024       ECOMM-1566: Use OrderSummary.BillingEmailAddress for VD orders
 * Daniel Reto      08/07/2024       New field to be populated on handleResponseGeneric and both handleResponse methods
 * Tiago Santos		25/07/2025		 Ctredit Memo Edit Invoice
 **/
@SuppressWarnings('PMD.ExcessiveClassLength')
public without sharing class COMM_SL_OMS_SAPHandler {
    private static String defaultCurrency = 'EUR';
    private static String defaultVATNumber = 'PT999999990';
    private static final String DEFAULT_BILLING_NAME = 'Consumidor Final';
    private static final String DEFAULT_BILLING_ADDRESS = '-';
    private static final String DEFAULT_BILLING_CITY = '-';
    private static final String DEFAULT_BILLING_POSTAL_CODE = '-';
    private static final String DEFAULT_BILLING_EMAIL = 'kiosk@ana.pt';
    private static final String DEFAULT_BILLING_COUNTRY = 'PT';
    private static final String PE_MESSAGE = 'Communication with SAP failed';
    private static final String ERROR_DEFAULT_GIFTCARD_NOTFOUND = 'No default giftCard payment product found: ';
    private static final string INVOICEOBJECTID = '3tt';
    private static final string CREDITMEMOOBJECTID = '50g';
    private static final String UAT_ENV_ID = '00D5t0000008hvUEAQ';
    private static final String SAP_LOAD_TEST = 'SAPIsLoadTest';
    private static final String SAP_GIFTCARD_PAYMENT_DEFAULT_PRODUCT = COMM_REP_UnifiedSettingMdt.getUnifiedSetting(
        'SAPGiftCardPaymentDefaultProduct'
    );

    private static final Integer CREDIT_PAYMENT_DAYS = Integer.valueOf(
        COMM_REP_UnifiedSettingMdt.getUnifiedSetting('SAPCreditPaymentDays', 'SAPCreditPaymentDays')
    );
    private static final List<String> GIFTCARD_PAYMENTGATEWAY_NAME_LIST = new List<String>{ COMM_OMS_Constants.GIFTCARD_GATEWAY_NAME };

    private static String COMM_EUROCOUNTRIES = '';
    private static String VAT_DIFFERENCE = '';

    //Character Limits
    private static final Integer BILLING_NAME_LIMIT = 35;
    private static final Integer BILLING_ADDITIONAL_NAME_LIMIT = 35;
    private static final Integer ITEM_REFERENCE_LIMIT = 12;

    private static COMM_SAPTaxCodesMap__mdt sapTaxCodesMapMdt = new COMM_SAPTaxCodesMap__mdt();
    private static COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();
    private static COMM_IREP_CreditMemo creditMemoRep = new COMM_REP_CreditMemo();
    private static COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    private static COMM_IREP_OrderItemAdjustmentLineSummary orderItemAdjustmentRep = new COMM_REP_OrderItemAdjustmentLineSummary();
    private static COMM_IREP_Payment paymentRep = new COMM_REP_Payment();
    private static COMM_IREP_Refund refundRep = new COMM_REP_Refund();
    private static COMM_IREP_Product2 product2Rep = new COMM_REP_Product2();
    private static Product2 defaultGiftCardPaymentProduct;

    /**
     * @description Core action to invoke from FLOW
     * @param objectIds List of invoice Ids to send to SAP
     */
    @InvocableMethod(Category='SAP' description='Send Financial Document (Invoice or CreditMemo) to SAP' label='Send Financial Document to SAP')
    public static void invocableMethod(List<Id> objectIds) {
        COMM_SL_OMS_SAPHandler.doCall(objectIds);
    }

    /**
     * @description Worker method to do the SAP callout to Mulesoft
     * @param objectIds List of invoice Ids to send to SAP
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.CognitiveComplexity')
    @future(callout=true)
    public static void doCall(List<Id> objectIds) {
        doCallNotFuture(objectIds);
    }

    /**
     * @description Worker method to do the SAP callout to Mulesoft
     * @param objectIds List of invoice Ids to send to SAP
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.CognitiveComplexity')
    public static void doCallNotFuture(List<Id> objectIds) {
        if (objectIds == null || objectIds.isEmpty()) {
            return;
        }

        COMM_EUROCOUNTRIES = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('SAPEuroCommunityCountries', 'EURO');
        VAT_DIFFERENCE = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('SAPVatDifferenceAmount', 'SAPVatDifferenceAmount');
        if (Test.isRunningTest()) {
            VAT_DIFFERENCE = '0.00';
        }

        FW_ISObjectRep sObjectRep = new FW_SObjectRep();
        List<ProcessException> processExceptionsList = new List<ProcessException>();
        List<Invoice> invoices = new List<Invoice>();
        List<CreditMemo> creditMemos = new List<CreditMemo>();
        Map<String, List<Payment>> invoicePaymentsMap = new Map<String, List<Payment>>();
        Map<String, List<Refund>> creditMemoRefundsMap = new Map<String, List<Refund>>();
        try {
            // Split object ids into invoice and credit memos lists
            List<Id> invoiceIds = new List<Id>();
            List<Id> creditMemoIds = new List<Id>();
            // Original Invoices to be used in creditMemos
            Map<String, SAPData> orderSummaryInvoiceMap = new Map<String, SAPData>();
            for (Id objectId : objectIds) {
                String first3Chars = objectId.toString().substring(0, 3);
                if (first3Chars.equalsIgnoreCase(CREDITMEMOOBJECTID)) {
                    creditMemoIds.add(objectId);
                } else if (first3Chars.equalsIgnoreCase(INVOICEOBJECTID)) {
                    invoiceIds.add(objectId);
                }
            }
            if (!invoiceIds.isEmpty()) {
                invoices = invoiceRep.getForSAPInvoice(invoiceIds);
                invoicePaymentsMap = getInvoiceGiftCardPayments(invoices);
            } else if (!creditMemoIds.isEmpty()) {
                creditMemos = creditMemoRep.getForSAPCreditMemo(creditMemoIds);
                orderSummaryInvoiceMap = getCreditMemosOriginalSAPInvoices(creditMemos);
                creditMemoRefundsMap = getCreditMemoGiftCardRefunds(creditMemos);
            } else {
                // no records found
                return;
            }

            Set<Id> orderItemSummaryIdSet = new Set<Id>();
            //For Promotion Line Items retrieve Order Item Summary Id to obtain Promotion Id
            for (Invoice invoiceRecord : invoices) {
                for (InvoiceLine invoiceLine : invoiceRecord.InvoiceLines) {
                    if (invoiceLine.Type.equalsIgnoreCase('Adjustment')) {
                        Id orderItemSummaryId = ((OrderItemSummary) invoiceLine.ReferenceEntityItem).Id;
                        orderItemSummaryIdSet.add(orderItemSummaryId);
                    }
                }
            }
            Map<String, String> promotionNameByOrderItemSummaryMap = new Map<String, String>();
            if (!orderItemSummaryIdSet.isEmpty()) {
                //Query for Promotion Id. Since several promotion can be applied to the same product use promotion price as additional key.
                for (
                    OrderItemAdjustmentLineSummary summaryRecord : orderItemAdjustmentRep.getOrderItemAdjustLineSumByOrderItemSummaryIds(
                        orderItemSummaryIdSet
                    )
                ) {
                    promotionNameByOrderItemSummaryMap.put(
                        summaryRecord.OrderItemSummaryId + String.valueOf(summaryRecord.OriginalOrderItemAdjustmentLineItem.Amount),
                        ((Promotion) summaryRecord.AdjustmentCause)?.Name
                    );
                }
            }

            // process Credit memos
            for (CreditMemo creditMemoRecord : creditMemos) {
                try {
                    if (((OrderSummary) creditMemoRecord.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                        continue;
                    }
                    List<Refund> creditMemoRefundsList = creditMemoRefundsMap.get(creditMemoRecord.id);
                    COMM_SL_SAPDocumentRequest creditMemoRequest = buildCreditMemoRequest(
                        creditMemoRecord,
                        orderSummaryInvoiceMap,
                        creditMemoRefundsList
                    );
                    if (creditMemoRequest == null) {
                        continue;
                    }

                    COMM_OMS_UnifiedSettings__mdt setting = COMM_OMS_UnifiedSettings__mdt.getInstance(SAP_LOAD_TEST);
                    COMM_SL_SAPDocumentResponse responseCreditMemo = COMM_SL_GenerateSAPDoc.makeCallout(
                        creditMemoRequest,
                        Boolean.valueOf(setting.COMM_Value__c)
                    );

                    if (responseCreditMemo != null) {
                        String errorMessage = handleResponse(creditMemoRecord, responseCreditMemo);
                        if (errorMessage != '') {
                            //Resolve previous Process exceptions for same Credit Memo.
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    creditMemoRecord.Id, //attachedToId
                                    creditMemoRecord.ReferenceEntity.Id,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            // create a process exception linked to the Credit Memo
                            processExceptionsList.add(
                                COMM_DO_ProcessExceptions.createProcessException(
                                    creditMemoRecord.Id, //attachedToId
                                    creditMemoRecord.ReferenceEntity.Id,
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    COMM_DO_ProcessExceptions.SEV_HIGH,
                                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                                    PE_MESSAGE,
                                    errorMessage,
                                    COMM_DO_ProcessExceptions.NEW_S
                                )
                            );
                        } else {
                            //Resolve previous Process exceptions for same Credit Memo.
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    creditMemoRecord.Id, //attachedToId
                                    creditMemoRecord.ReferenceEntity.Id,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    creditMemoRecord.Id,
                                    null,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                        }
                    } else {
                        //Resolve previous Process exceptions for same Credit Memo.
                        processExceptionsList.addAll(
                            COMM_DO_ProcessExceptions.updateStatus(
                                COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                creditMemoRecord.Id, //attachedToId
                                creditMemoRecord.ReferenceEntity.Id,
                                new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                COMM_DO_ProcessExceptions.RESOLVED
                            )
                        );
                        // create a process exception linked to the Credit Memo
                        processExceptionsList.add(
                            COMM_DO_ProcessExceptions.createProcessException(
                                creditMemoRecord.Id, //attachedToId
                                creditMemoRecord.ReferenceEntity.Id, // Order Summary Id
                                COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                COMM_DO_ProcessExceptions.SEV_HIGH,
                                COMM_DO_ProcessExceptions.PRIO_HIGH,
                                PE_MESSAGE,
                                'Communication with SAP failed',
                                COMM_DO_ProcessExceptions.NEW_S
                            )
                        );
                    }
                } catch (Exception ex) {
                    COMM_GEN_Utility.logError(
                        ex,
                        'Credit Memo - An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                        'COMM_SL_OMS_SAPHandler'
                    );
                    processExceptionsList.add(
                        COMM_DO_ProcessExceptions.createProcessException(
                            creditMemoRecord.Id, //attachedToId
                            creditMemoRecord.ReferenceEntity.Id, // Order Summary Id
                            COMM_DO_ProcessExceptions.SAP_CATEGORY,
                            COMM_DO_ProcessExceptions.SEV_HIGH,
                            COMM_DO_ProcessExceptions.PRIO_HIGH,
                            PE_MESSAGE,
                            'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                            COMM_DO_ProcessExceptions.NEW_S
                        )
                    );
                }
            }

            // process invoices
            for (Invoice invoice : invoices) {
                try {
                    if (((OrderSummary) invoice.ReferenceEntity).COMM_SalesType__c.equalsIgnoreCase('VC')) {
                        continue;
                    }

                    List<Payment> invoicePaymentsList = invoicePaymentsMap.get(invoice.id);

                    COMM_SL_SAPDocumentRequest invoiceRequest = buildInvoiceRequest(invoice, promotionNameByOrderItemSummaryMap, invoicePaymentsList);
                    if (invoiceRequest == null) {
                        continue;
                    }

                    COMM_OMS_UnifiedSettings__mdt setting = COMM_OMS_UnifiedSettings__mdt.getInstance(SAP_LOAD_TEST);
                    COMM_SL_SAPDocumentResponse responseInvoice = COMM_SL_GenerateSAPDoc.makeCallout(
                        invoiceRequest,
                        Boolean.valueOf(setting.COMM_Value__c)
                    );

                    if (responseInvoice != null) {
                        String errorMessage = handleResponse(invoice, responseInvoice);
                        if (errorMessage != '') {
                            //Resolve previous Process exceptions for same Invoice.
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    invoice.Id, //attachedToId
                                    invoice.ReferenceEntity.Id,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            // create a process exception linked to the Invoice
                            processExceptionsList.add(
                                COMM_DO_ProcessExceptions.createProcessException(
                                    invoice.Id, //attachedToId
                                    invoice.ReferenceEntity.Id,
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    COMM_DO_ProcessExceptions.SEV_HIGH,
                                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                                    PE_MESSAGE,
                                    errorMessage,
                                    COMM_DO_ProcessExceptions.NEW_S
                                )
                            );
                        } else {
                            //Resolve previous Process exceptions for same Invoice.
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    invoice.Id, //attachedToId
                                    invoice.ReferenceEntity.Id,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                    invoice.Id,
                                    null,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                        }
                    } else {
                        //Resolve previous Process exceptions for same Invoice.
                        processExceptionsList.addAll(
                            COMM_DO_ProcessExceptions.updateStatus(
                                COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                invoice.Id, //attachedToId
                                invoice.ReferenceEntity.Id,
                                new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                COMM_DO_ProcessExceptions.RESOLVED
                            )
                        );
                        // create a process exception linked to the Invoice
                        processExceptionsList.add(
                            COMM_DO_ProcessExceptions.createProcessException(
                                invoice.Id, //attachedToId
                                invoice.ReferenceEntity.Id,
                                COMM_DO_ProcessExceptions.SAP_CATEGORY,
                                COMM_DO_ProcessExceptions.SEV_HIGH,
                                COMM_DO_ProcessExceptions.PRIO_HIGH,
                                PE_MESSAGE,
                                'Communication with SAP failed',
                                COMM_DO_ProcessExceptions.NEW_S
                            )
                        );
                    }
                } catch (Exception ex) {
                    COMM_GEN_Utility.logError(
                        ex,
                        'Invoice - An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                        'COMM_SL_OMS_SAPHandler'
                    );
                    processExceptionsList.add(
                        COMM_DO_ProcessExceptions.createProcessException(
                            invoice.Id, //attachedToId
                            invoice.ReferenceEntity.Id, // Order Summary Id
                            COMM_DO_ProcessExceptions.SAP_CATEGORY,
                            COMM_DO_ProcessExceptions.SEV_HIGH,
                            COMM_DO_ProcessExceptions.PRIO_HIGH,
                            PE_MESSAGE,
                            'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                            COMM_DO_ProcessExceptions.NEW_S
                        )
                    );
                }
            }
        } catch (Exception ex) {
            COMM_GEN_Utility.logError(
                ex,
                'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                'COMM_SL_OMS_SAPHandler'
            );
            processExceptionsList.add(
                COMM_DO_ProcessExceptions.createProcessException(
                    objectIds[0], //attachedToId
                    null, // Order Summary Id
                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                    COMM_DO_ProcessExceptions.SEV_HIGH,
                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                    PE_MESSAGE,
                    'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                    COMM_DO_ProcessExceptions.NEW_S
                )
            );
        } finally {
            if (invoices != null && !invoices.isEmpty()) {
                sObjectRep.updateSObjects(invoices);
            }
            if (creditMemos != null && !creditMemos.isEmpty()) {
                sObjectRep.updateSObjects(creditMemos);
            }
            if (!processExceptionsList.isEmpty()) {
                sObjectRep.upsertSObjects(processExceptionsList);
            }
            COMM_OMS_DatabaseUtil.commitChanges();
        }
    }

    /**
     * @description Update input Map based on the HTTP Response
     * @param invoice
     * @param response Mulesoft HTTP response
     * @return String error message
     */
    private static String handleResponse(Invoice invoice, COMM_SL_SAPDocumentResponse response) {
        // Response can be a list of errors
        String errorMessage = '';

        if (response == null) {
            errorMessage = 'Null response received';
        } else if (!String.isEmpty(response.resultCode)) {
            // error
            errorMessage = response.resultDesc;
        } else {
            // register sap document id
            invoice.COMM_SAPDocumentId__c = response.documentId;
            invoice.COMM_IssuanceDate__c = Date.today();
        }
        invoice.COMM_SAPLastLog__c = System.JSON.serialize(response);
        invoice.COMM_SAPIntegrationDate__c = Datetime.now();
        invoice.COMM_SAPCount__c += 1;

        return errorMessage;
    }

    /**
     * @description Build SAP request based on the invoice
     * @param invoice Invoice object
     * @param promotionNameByOrderItemSummaryMap Map with Promotion Name by Order Item Summary Id + Price
     * @param paymentsList List of Payments Linked to the Invoice
     * @return List<CO>
     */
    @TestVisible
    private static COMM_SL_SAPDocumentRequest buildInvoiceRequest(
        Invoice invoice,
        Map<String, String> promotionNameByOrderItemSummaryMap,
        List<Payment> paymentsList
    ) {
        COMM_SL_SAPDocumentRequest request = new COMM_SL_SAPDocumentRequest();
        OrderSummary os = (OrderSummary) invoice.ReferenceEntity;
        String salesChannelName = ((SalesChannel) os.SalesChannel).SalesChannelName;
        request.paymentMode = 'Prepaid';
        request.id = UserInfo.getOrganizationId() == UAT_ENV_ID ? invoice.DocumentNumber.replace('DOC', 'UAT') : invoice.DocumentNumber;
        request.documentSerie = salesChannelName.containsIgnoreCase('kiosk') ? 'FS' : 'FT';
        request.documentType = 'Invoice';
        request.documentDate = os.OrderedDate.format('yyyy-MM-dd');
        request.billingDate = Datetime.now().format('yyyy-MM-dd');
        request.paymentDays = null;
        request.dueDate = null;
        request.netAmount = invoice.TotalAmount;
        if (String.isNotBlank(VAT_DIFFERENCE)) {
            request.vatDifferenceAmount = Decimal.valueOf(VAT_DIFFERENCE);
        } else {
            request.vatDifferenceAmount = 0.00;
        }
        request.taxAmout = invoice.TotalTaxAmount;
        populateBillingData(
            request,
            os.BillingEmailAddress,
            os.BillingStreet,
            os.BillingPostalCode,
            os.BillingCity,
            os.BillingCountryCode,
            os.COMM_BillingVATNumber__c,
            os.COMM_BillingName__c,
            os.COMM_BillingVATNumber__c
        );

        request.orderItems = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
        //Build Map with all Promotion Lines in Invoice
        Map<String, List<InvoiceLine>> mapPromotionLines = new Map<String, List<InvoiceLine>>();
        for (InvoiceLine invoiceLine : invoice.InvoiceLines) {
            //Process Invoice Line that is Adjustment (Promotion) and Amount is different from zero
            if (invoiceLine.Type.equalsIgnoreCase('Adjustment') && invoiceLine.LineAmount != 0.00) {
                if (!mapPromotionLines.containsKey(invoiceLine.RelatedLineId)) {
                    mapPromotionLines.put(invoiceLine.RelatedLineId, new List<InvoiceLine>());
                }
                mapPromotionLines.get(invoiceLine.RelatedLineId).add(invoiceLine);
            }
        }
        // Get billing country type
        String clientType = '';
        if (os.BillingCountryCode.equalsIgnoreCase('pt')) {
            clientType = 'NAC';
        } else if (COMM_EUROCOUNTRIES.containsIgnoreCase(os.BillingCountryCode)) {
            clientType = 'COM';
        } else {
            clientType = 'OT';
        }

        //Retrieve Tax Lines Amount
        Map<Id, Decimal> taxMap = new Map<Id, Decimal>();
        for (InvoiceLine invoiceLine : invoice.InvoiceLines) {
            //If Line is Tax then store value (to associate with Line)
            if (invoiceLine.Type.equalsIgnoreCase('Tax')) {
                taxMap.put(invoiceLine.RelatedLineId, invoiceLine.LineAmount);
            }
        }

        for (InvoiceLine invoiceLine : invoice.InvoiceLines) {
            if (!invoiceLine.Type.equalsIgnoreCase('Charge') || invoiceLine.ReferenceEntityItemType.equalsIgnoreCase('Delivery Charge')) {
                continue;
            }
            COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
            line.location = invoiceLine.Product2.COMM_SAPLocation__c;
            line.productId = invoiceLine.Product2.StockKeepingUnit;
            String taxCode = invoiceLine.Product2.COMM_Tax__c == null ? 'Continent' : invoiceLine.Product2.COMM_Tax__c;
            line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT', taxCode, clientType);
            line.quantity = invoiceLine.Quantity;
            line.description = ((OrderItemSummary) invoiceLine.ReferenceEntityItem).Description;
            line.totalNetAmount = invoiceLine.LineAmount;
            line.totalVatAmount = taxMap.get(invoiceLine.Id);
            line.itemReference = null;
            request.orderItems.add(line);
            // check if there are promotion lines
            List<InvoiceLine> promoInvoiceLineList = mapPromotionLines.get(invoiceLine.Id);
            if (promoInvoiceLineList != null && !promoInvoiceLineList.isEmpty() && invoiceLine.Type.equalsIgnoreCase('Charge')) {
                for (InvoiceLine promoInvoiceLine : promoInvoiceLineList) {
                    COMM_SL_SAPDocumentRequest.OrderItems promoLine = line.clone();

                    //Set Promotion Id as Item Reference
                    Id orderItemSummaryId = ((OrderItemSummary) invoiceLine.ReferenceEntityItem).Id;
                    String promotionId = promotionNameByOrderItemSummaryMap?.get(orderItemSummaryId + String.valueOf(promoInvoiceLine.LineAmount));
                    promoLine.itemReference = promotionId?.left(ITEM_REFERENCE_LIMIT);

                    //Add Amount of Promotion Lines
                    promoLine.totalNetAmount = promoInvoiceLine.LineAmount;
                    promoLine.totalVatAmount = taxMap.get(promoInvoiceLine.Id);
                    //Add Promotion Line to Item List
                    request.orderItems.add(promoLine);
                }
            }
        }

        // Get GiftCard Payments
        if (paymentsList != null && !paymentsList.isEmpty()) {
            getGiftCardPaymentDefaultProduct();
            for (Payment payment : paymentsList) {
                COMM_SL_SAPDocumentRequest.OrderItems giftCardPaymentLine = new COMM_SL_SAPDocumentRequest.OrderItems();
                giftCardPaymentLine.location = defaultGiftCardPaymentProduct.COMM_SAPLocation__c;
                giftCardPaymentLine.productId = defaultGiftCardPaymentProduct.ProductCode;
                String taxCode = defaultGiftCardPaymentProduct.COMM_Tax__c == null ? 'Continent' : defaultGiftCardPaymentProduct.COMM_Tax__c;
                giftCardPaymentLine.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT', taxCode, clientType);
                giftCardPaymentLine.quantity = 1;
                giftCardPaymentLine.description = defaultGiftCardPaymentProduct.Name;
                giftCardPaymentLine.totalNetAmount = -payment.Amount;
                giftCardPaymentLine.totalVatAmount = 0;
                giftCardPaymentLine.itemReference = null;
                request.orderItems.add(giftCardPaymentLine);
            }
        }

        return request;
    }

    /**
     * @description Update input Map based on the HTTP Response
     * @param creditMemoRecord Credit Memo object
     * @param response Mulesoft HTTP response
     * @return String error message
     */
    private static String handleResponse(CreditMemo creditMemoRecord, COMM_SL_SAPDocumentResponse response) {
        // Response can be a list of errors
        String errorMessage = '';

        if (response == null) {
            errorMessage = 'Null response received';
        } else if (!String.isEmpty(response.resultCode)) {
            // error
            errorMessage = response.resultDesc;
        } else {
            // register sap document id
            creditMemoRecord.COMM_SAPDocumentId__c = response.documentId;
            creditMemoRecord.COMM_IssuanceDate__c = Date.today();
        }
        creditMemoRecord.COMM_SAPLastLog__c = System.JSON.serialize(response);
        creditMemoRecord.COMM_SAPIntegrationDate__c = Datetime.now();
        creditMemoRecord.COMM_SAPCount__c += 1;

        return errorMessage;
    }
    
    public void createCreditMemo(OrderSummary os, COMM_WS_EditInvoiceInput input) {
        String billingName = input.firstName + ' ' + input.lastName;
        String email = os.BillingEmailAddress;
        String street = input.address;
        String zipCode = input.postalCode;
        String city = input.city;
        String country = 'Portugal';
        String countryCode = input.country; 
        String nif = input.vatNumber;
        List<ProcessException> processExceptionsList = new List<ProcessException>();
        List<Invoice> invoices = [Select Id, COMM_SAPDocumentId2__c, COMM_SAPDocumentId__c, COMM_CreditMemoSAPId__c from Invoice where ReferenceEntityId =: os.Id];
        List<Id> invoicesId = new List<Id>();
        invoicesId.add(invoices[0].Id);
        Invoice invoiceRecord = invoiceRep.getForSAPInvoice(invoicesId)[0]; 
        
        COMM_SL_SAPDocumentRequest creditMemoRequest = buildCreditMemoFromOrderSummaryRequest(os, invoiceRecord);
        COMM_SL_SAPDocumentRequest InvoiceRequest = buildInvoiceFromOrderSummaryRequest(os, invoiceRecord, input);
        COMM_OMS_UnifiedSettings__mdt setting = COMM_OMS_UnifiedSettings__mdt.getInstance(SAP_LOAD_TEST);
        
        COMM_SL_SAPDocumentResponse responseCreditMemo = COMM_SL_GenerateSAPDoc.makeCallout(
            creditMemoRequest,
            Boolean.valueOf(setting.COMM_Value__c)
        );
        
        COMM_SL_SAPDocumentResponse responseInvoice = COMM_SL_GenerateSAPDoc.makeCallout(
            InvoiceRequest,
            Boolean.valueOf(setting.COMM_Value__c)
        );
        
        String errorMessage;
        if(responseInvoice != null) {
            errorMessage = handleResponse(invoiceRecord, responseInvoice);
            if (errorMessage != '') {
                //Resolve previous Process exceptions for same Credit Memo.
                processExceptionsList.addAll(
                    COMM_DO_ProcessExceptions.updateStatus(
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        invoiceRecord.Id, //attachedToId
                        invoiceRecord.ReferenceEntity.Id,
                        new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                        COMM_DO_ProcessExceptions.RESOLVED
                    )
                );
                // create a process exception linked to the Credit Memo
                processExceptionsList.add(
                    COMM_DO_ProcessExceptions.createProcessException(
                        invoiceRecord.Id, //attachedToId
                        invoiceRecord.ReferenceEntity.Id,
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        COMM_DO_ProcessExceptions.SEV_HIGH,
                        COMM_DO_ProcessExceptions.PRIO_HIGH,
                        PE_MESSAGE,
                        errorMessage,
                        COMM_DO_ProcessExceptions.NEW_S
                    )
                );
            }
            // Update Billing Address
            os.COMM_BillingName__c = billingName;
            os.BillingEmailAddress = email;
            os.BillingStreet = street;
            os.BillingPostalCode = zipCode;
            os.BillingCity = city;
            os.BillingCountry = country;
            os.BillingCountryCode = countryCode; 
            os.COMM_BillingVATNumber__c = nif;
            update os;
            invoices[0].COMM_SAPDocumentId2__c = invoices[0].COMM_SAPDocumentId__c;
            invoices[0].COMM_SAPDocumentId__c = responseInvoice.documentId;
        }
        
        
        if (responseCreditMemo != null) {
            errorMessage = handleResponse(invoiceRecord, responseCreditMemo);
            if (errorMessage != '') {
                //Resolve previous Process exceptions for same Credit Memo.
                processExceptionsList.addAll(
                    COMM_DO_ProcessExceptions.updateStatus(
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        invoiceRecord.Id, //attachedToId
                        invoiceRecord.ReferenceEntity.Id,
                        new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                        COMM_DO_ProcessExceptions.RESOLVED
                    )
                );
                // create a process exception linked to the Credit Memo
                processExceptionsList.add(
                    COMM_DO_ProcessExceptions.createProcessException(
                        invoiceRecord.Id, //attachedToId
                        invoiceRecord.ReferenceEntity.Id,
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        COMM_DO_ProcessExceptions.SEV_HIGH,
                        COMM_DO_ProcessExceptions.PRIO_HIGH,
                        PE_MESSAGE,
                        errorMessage,
                        COMM_DO_ProcessExceptions.NEW_S
                    )
                );                
            } else {
                //Resolve previous Process exceptions for same Credit Memo.
                processExceptionsList.addAll(
                    COMM_DO_ProcessExceptions.updateStatus(
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        invoiceRecord.Id, //attachedToId
                        invoiceRecord.ReferenceEntity.Id,
                        new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                        COMM_DO_ProcessExceptions.RESOLVED
                    )
                );
                processExceptionsList.addAll(
                    COMM_DO_ProcessExceptions.updateStatus(
                        COMM_DO_ProcessExceptions.SAP_CATEGORY,
                        invoiceRecord.Id,
                        null,
                        new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                        COMM_DO_ProcessExceptions.RESOLVED
                    )
                );
                invoices[0].COMM_CreditMemoSAPId__c = responseCreditMemo.documentId;
                update invoices;
            }
        } else {
            //Resolve previous Process exceptions for same Credit Memo.
            processExceptionsList.addAll(
                COMM_DO_ProcessExceptions.updateStatus(
                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                    invoiceRecord.Id, //attachedToId
                    invoiceRecord.ReferenceEntity.Id,
                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                    COMM_DO_ProcessExceptions.RESOLVED
                )
            );
            // create a process exception linked to the Credit Memo
            processExceptionsList.add(
                COMM_DO_ProcessExceptions.createProcessException(
                    invoiceRecord.Id, //attachedToId
                    invoiceRecord.ReferenceEntity.Id, // Order Summary Id
                    COMM_DO_ProcessExceptions.SAP_CATEGORY,
                    COMM_DO_ProcessExceptions.SEV_HIGH,
                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                    PE_MESSAGE,
                    'Communication with SAP failed',
                    COMM_DO_ProcessExceptions.NEW_S
                )
            );
        }
    }

    /**
     * @description Build SAP request based on the Credit Memo
     * @param creditMemoRecord Credit Memo object
     * @param orderSummaryInvoiceMap Map with Invoices linked to the Order
     * @param refundsList List of Refunds Linked to the CreditMemo
     * @return List<CO>
     */
    @TestVisible
    private static COMM_SL_SAPDocumentRequest buildCreditMemoRequest(
        CreditMemo creditMemoRecord,
        Map<String, SAPData> orderSummaryInvoiceMap,
        List<Refund> refundsList
    ) {
        COMM_SL_SAPDocumentRequest request = new COMM_SL_SAPDocumentRequest();
        OrderSummary os = (OrderSummary) creditMemoRecord.ReferenceEntity;
        request.paymentMode = 'Prepaid';
        request.id = UserInfo.getOrganizationId() == UAT_ENV_ID
            ? creditMemoRecord.DocumentNumber.replace('DOC', 'UAT')
            : creditMemoRecord.DocumentNumber;
        request.documentSerie = 'FT';
        request.documentType = 'CreditNote';
        request.documentDate = os.OrderedDate.format('yyyy-MM-dd');
        request.billingDate = Datetime.now().format('yyyy-MM-dd');
        request.paymentDays = null;
        request.dueDate = null;
        request.netAmount = creditMemoRecord.TotalAmount;
        if (String.isNotBlank(VAT_DIFFERENCE)) {
            request.vatDifferenceAmount = Decimal.valueOf(VAT_DIFFERENCE);
        } else {
            request.vatDifferenceAmount = 0.00;
        }
        request.taxAmout = creditMemoRecord.TotalTaxAmount;
        populateBillingData(
            request,
            os.BillingEmailAddress,
            os.BillingStreet,
            os.BillingPostalCode,
            os.BillingCity,
            os.BillingCountryCode,
            os.COMM_BillingVATNumber__c,
            os.COMM_BillingName__c,
            os.COMM_BillingVATNumber__c
        );
        request.orderItems = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
        //Build Map with all Promotion Lines in Credit Memo
        Map<String, List<CreditMemoLine>> mapPromotionLines = new Map<String, List<CreditMemoLine>>();
        for (CreditMemoLine creditMemoLineRecord : creditMemoRecord.CreditMemoLines) {
            //Process Credit Memo Line that is Adjustment (Promotion) and Amount is different from zero
            if (creditMemoLineRecord.Type.equalsIgnoreCase('Adjustment') && creditMemoLineRecord.LineAmount != 0.00) {
                if (!mapPromotionLines.containsKey(creditMemoLineRecord.RelatedLineId)) {
                    mapPromotionLines.put(creditMemoLineRecord.RelatedLineId, new List<CreditMemoLine>());
                }
                mapPromotionLines.get(creditMemoLineRecord.RelatedLineId).add(creditMemoLineRecord);
            }
        }
        // Get billing country type
        String clientType = '';
        if (os.BillingCountryCode.equalsIgnoreCase('pt')) {
            clientType = 'NAC';
        } else if (COMM_EUROCOUNTRIES.containsIgnoreCase(os.BillingCountryCode)) {
            clientType = 'COM';
        } else {
            clientType = 'OT';
        }

        SAPData sapInfo = orderSummaryInvoiceMap.get(((OrderSummary) creditMemoRecord.ReferenceEntity).Id);

        //Retrieve Tax Lines Amount
        Map<Id, Decimal> taxMap = new Map<Id, Decimal>();
        for (CreditMemoLine creditMemoLineRecord : creditMemoRecord.CreditMemoLines) {
            //If Line is Tax then store value (to associate with Line)
            if (creditMemoLineRecord.Type.equalsIgnoreCase('Tax')) {
                taxMap.put(creditMemoLineRecord.RelatedLineId, creditMemoLineRecord.LineAmount);
            }
        }

        for (CreditMemoLine creditMemoLineRecord : creditMemoRecord.CreditMemoLines) {
            if (
                !creditMemoLineRecord.Type.equalsIgnoreCase('Charge') ||
                creditMemoLineRecord.ReferenceEntityItemType.equalsIgnoreCase('Delivery Charge')
            ) {
                continue;
            }
            COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
            line.location = creditMemoLineRecord.Product2.COMM_SAPLocation__c;
            line.productId = creditMemoLineRecord.Product2.StockKeepingUnit;
            String taxCode = creditMemoLineRecord.Product2.COMM_Tax__c == null ? 'Continent' : creditMemoLineRecord.Product2.COMM_Tax__c;
            line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('NC', taxCode, clientType);
            line.quantity = 1;
            line.description = ((OrderItemSummary) creditMemoLineRecord.ReferenceEntityItem).Description;
            line.totalNetAmount = creditMemoLineRecord.LineAmount;
            line.totalVatAmount = taxMap.get(creditMemoLineRecord.Id);
            String originalInvoice = sapInfo?.sapDocumentId;
            line.itemReference = originalInvoice;
            request.orderItems.add(line);
            // check if there are promotion lines
            List<CreditMemoLine> promoCreditMemoLineList = mapPromotionLines.get(creditMemoLineRecord.Id);
            if (promoCreditMemoLineList != null && !promoCreditMemoLineList.isEmpty() && creditMemoLineRecord.Type.equalsIgnoreCase('Charge')) {
                for (CreditMemoLine promoCreditMemoLine : promoCreditMemoLineList) {
                    COMM_SL_SAPDocumentRequest.OrderItems promoLine = line.clone();
                    //Sum Amount of all Promotion Line Items
                    promoLine.totalNetAmount = promoCreditMemoLine.LineAmount;
                    promoLine.totalVatAmount = taxMap.get(promoCreditMemoLine.Id);
                    //Add Promotion Line Item to List
                    request.orderItems.add(promoLine);
                }
            }
        }

        // Get GiftCard Refunds
        if (refundsList != null && !refundsList.isEmpty()) {
            getGiftCardPaymentDefaultProduct();
            for (Refund refund : refundsList) {
                COMM_SL_SAPDocumentRequest.OrderItems giftCardRefundLine = new COMM_SL_SAPDocumentRequest.OrderItems();
                giftCardRefundLine.location = defaultGiftCardPaymentProduct.COMM_SAPLocation__c;
                giftCardRefundLine.productId = defaultGiftCardPaymentProduct.ProductCode;
                String taxCode = defaultGiftCardPaymentProduct.COMM_Tax__c == null ? 'Continent' : defaultGiftCardPaymentProduct.COMM_Tax__c;
                giftCardRefundLine.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT', taxCode, clientType);
                giftCardRefundLine.quantity = 1;
                giftCardRefundLine.description = defaultGiftCardPaymentProduct.Name;
                giftCardRefundLine.totalNetAmount = -refund.Amount;
                giftCardRefundLine.totalVatAmount = 0;
                giftCardRefundLine.itemReference = null;
                request.orderItems.add(giftCardRefundLine);
            }
        }

        //Update Reference based on if Credit Refunded all Items in Invoice (Reference = Invoice SAP Document Id) or Partial (MM.YYYY-MM.YYYY)
        if (sapInfo != null) {
            request.reference = sapInfo.fullyReturned
                ? sapInfo.sapDocumentId
                : sapInfo.issuanceDate.format('MM.yyyy') + '-' + sapInfo.issuanceDate.format('MM.yyyy');
        }

        return request;
    }
    
    /**
     * @description Build SAP request based on the Order Summary
     * @param os OrderSummary object
     * @param invoice Invoice object reference to create Credit Memo on SAP 
     * @return List<CO>
     */
    @TestVisible
    private static COMM_SL_SAPDocumentRequest buildCreditMemoFromOrderSummaryRequest(
        OrderSummary os,
        Invoice invoice
    ) {
        COMM_SL_SAPDocumentRequest request = new COMM_SL_SAPDocumentRequest();
        
        request.paymentMode = 'Prepaid';
        request.id = UserInfo.getOrganizationId() == UAT_ENV_ID
            ? invoice.DocumentNumber.replace('DOC', 'UAT')
            : invoice.DocumentNumber;
        request.id = invoice.COMM_SAPDocumentId__c;
        request.documentSerie = 'FT';
        request.documentType = 'CreditNote';
        request.documentDate = os.OrderedDate.format('yyyy-MM-dd');
        request.billingDate = Datetime.now().format('yyyy-MM-dd');
        request.paymentDays = null;
        request.dueDate = null;
        request.netAmount = invoice.TotalAmount;
        if (String.isNotBlank(VAT_DIFFERENCE)) {
            request.vatDifferenceAmount = Decimal.valueOf(VAT_DIFFERENCE);
        } else {
            request.vatDifferenceAmount = 0.00;
        }
        request.taxAmout = invoice.TotalTaxAmount;
        populateBillingData(
            request,
            os.BillingEmailAddress,
            os.BillingStreet,
            os.BillingPostalCode,
            os.BillingCity,
            os.BillingCountryCode,
            os.COMM_BillingVATNumber__c,
            os.COMM_BillingName__c,
            os.COMM_BillingVATNumber__c
        );
        request.creditMemoPay = 'CR';

        request.orderItems = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
        
        String clientType = '';
        if (os.BillingCountryCode.equalsIgnoreCase('pt')) {
            clientType = 'NAC';
        } else if (COMM_EUROCOUNTRIES.containsIgnoreCase(os.BillingCountryCode)) {
            clientType = 'COM';
        } else {
            clientType = 'OT';
        }
        
        List<OrderItemSummary> orderItems = new COMM_REP_OrderItemSummary().getOrderItemSummariesByOrderSummaryId(os.Id);
        
        for (OrderItemSummary orderItem : orderItems) {
            if (
                orderItem.Type.equalsIgnoreCase('Delivery Charge')
            ) {
                continue;
            }
            COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
            line.location = orderItem.Product2.COMM_SAPLocation__c;
            line.productId = orderItem.Product2.StockKeepingUnit;
            String taxCode = orderItem.Product2.COMM_Tax__c == null ? 'Continent' : orderItem.Product2.COMM_Tax__c;
            line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('NC', taxCode, clientType);
            line.quantity = 1;
            line.description = orderItem.Description;
            line.totalNetAmount = orderItem.TotalLineAmount ;
            line.totalVatAmount = orderItem.TotalTaxAmount;
            line.itemReference = invoice.COMM_SAPDocumentId__c;
            request.orderItems.add(line);                        
        }
        return request;
    }
    
    /**
     * @description Build SAP request based on the Order Summary
     * @param os OrderSummary object
     * @param invoice Invoice object reference to create Credit Memo on SAP 
     * @return List<CO>
     */
    @TestVisible
    private static COMM_SL_SAPDocumentRequest buildInvoiceFromOrderSummaryRequest(
        OrderSummary os,
        Invoice invoice,
        COMM_WS_EditInvoiceInput input
    ) {
        COMM_SL_SAPDocumentRequest request = new COMM_SL_SAPDocumentRequest();
        
        request.paymentMode = 'Prepaid';
        request.id = UserInfo.getOrganizationId() == UAT_ENV_ID
            ? invoice.DocumentNumber.replace('DOC', 'UAT')
            : invoice.DocumentNumber;
        request.id = invoice.COMM_SAPDocumentId__c;
        request.documentSerie = 'FT';
        request.documentType = 'Invoice';
        request.documentDate = os.OrderedDate.format('yyyy-MM-dd');
        request.billingDate = Datetime.now().format('yyyy-MM-dd');
        request.paymentDays = null;
        request.dueDate = null;
        request.netAmount = invoice.TotalAmount;
        if (String.isNotBlank(VAT_DIFFERENCE)) {
            request.vatDifferenceAmount = Decimal.valueOf(VAT_DIFFERENCE);
        } else {
            request.vatDifferenceAmount = 0.00;
        }
        request.taxAmout = invoice.TotalTaxAmount;
        String vatNumberDetector = os.COMM_BillingVATNumber__c;
        String vatNumberForRequest = String.isBlank(input.vatNumber) ? os.COMM_BillingVATNumber__c : input.vatNumber;
        String vatCountryForRequest = String.isBlank(input.countryCode) ? os.BillingCountryCode : input.countryCode;
        populateBillingData(
            request,
            os.BillingEmailAddress,
            input.address,
            input.postalCode,
            input.city,
            vatCountryForRequest,
            vatNumberForRequest,
            os.COMM_BillingName__c,
            vatNumberDetector
        );
        request.creditMemoPay = '';

        request.orderItems = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
        
        String clientType = '';
        if (os.BillingCountryCode.equalsIgnoreCase('pt')) {
            clientType = 'NAC';
        } else if (COMM_EUROCOUNTRIES.containsIgnoreCase(os.BillingCountryCode)) {
            clientType = 'COM';
        } else {
            clientType = 'OT';
        }
        
        List<OrderItemSummary> orderItems = new COMM_REP_OrderItemSummary().getOrderItemSummariesByOrderSummaryId(os.Id);
        
        for (OrderItemSummary orderItem : orderItems) {
            if (
                orderItem.Type.equalsIgnoreCase('Delivery Charge')
            ) {
                continue;
            }
            COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
            line.location = orderItem.Product2.COMM_SAPLocation__c;
            line.productId = orderItem.Product2.StockKeepingUnit;
            String taxCode = orderItem.Product2.COMM_Tax__c == null ? 'Continent' : orderItem.Product2.COMM_Tax__c;
            line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('NC', taxCode, clientType);
            line.quantity = 1;
            line.description = orderItem.Description;
            line.totalNetAmount = orderItem.TotalLineAmount ;
            line.totalVatAmount = orderItem.TotalTaxAmount;
            line.itemReference = '';//invoice.COMM_SAPDocumentId__c;
            request.orderItems.add(line);                        
        }
        return request;
    }

    /**
     * @description Build SAP request based on the invoice and credit memo
     * @param accountRecord Account Record of the Client associated with the request
     * @param invoiceList List of Invoice object
     * @param creditMemoList List of CreditMemo object
     * @param controlDate Datetime crontroller field
     * @param accountRelatedInvoice List to store invoices that were processed
     * @param accountRelatedCreditMemo List to store credit memos that were processed
     * @param accountRelatedCreditMemo
     * @param isInvoiceDocument Boolean indicating if the created document is invoice (true) or credit note (false)
     * @param promotionNameByOrderItemSummaryMap Map with Promotion Name for each Order Item Summary
     * @return Object that represents Request to be sent to SAP
     */
    @TestVisible
    public static COMM_SL_SAPDocumentRequest buildCreditPaymentsRequest(
        Account accountRecord,
        List<Invoice> invoiceList,
        List<CreditMemo> creditMemoList,
        DateTime controlDate,
        List<Invoice> accountRelatedInvoice,
        List<CreditMemo> accountRelatedCreditMemo,
        Boolean isInvoiceDocument,
        Map<String, String> promotionNameByOrderItemSummaryMap
    ) {
        COMM_SL_SAPDocumentRequest request = new COMM_SL_SAPDocumentRequest();
        request.paymentMode = 'Credit';
        request.id = invoiceList.isEmpty() ? creditMemoList[0].DocumentNumber : invoiceList[0].DocumentNumber;
        request.id = UserInfo.getOrganizationId() == UAT_ENV_ID ? request.id.replace('DOC', 'UAT') : request.id;
        request.documentSerie = 'FT';
        request.documentDate = controlDate.format('yyyy-MM-dd');
        request.billingDate = Datetime.now().format('yyyy-MM-dd');
        request.dueDate = Datetime.now().addDays(CREDIT_PAYMENT_DAYS).format('yyyy-MM-dd');
        VAT_DIFFERENCE = COMM_REP_UnifiedSettingMdt.getUnifiedSetting('SAPVatDifferenceAmount', 'SAPVatDifferenceAmount');
        if (String.isNotBlank(VAT_DIFFERENCE)) {
            request.vatDifferenceAmount = Decimal.valueOf(VAT_DIFFERENCE);
        } else {
            request.vatDifferenceAmount = 0.00;
        }

        String accountBillingEmail = String.isEmpty(accountRecord.COMM_Email__c)
            ? accountRecord.PersonEmail
            : accountRecord.COMM_Email__c;
        populateBillingData(
            request,
            accountBillingEmail,
            accountRecord.BillingStreet,
            accountRecord.BillingPostalCode,
            accountRecord.BillingCity,
            accountRecord.BillingCountryCode,
            accountRecord.COMM_VATNumber__c,
            accountRecord.Name,
            accountRecord.COMM_VATNumber__c
        );

        //Build Map with Promotion Lines in Invoices and Map with Tax Values
        Map<String, List<InvoiceLine>> mapInvoicePromotionLines = new Map<String, List<InvoiceLine>>();
        Map<Id, Decimal> taxMap = new Map<Id, Decimal>();
        for (Invoice invoiceRecord : invoiceList) {
            for (InvoiceLine invoiceLine : invoiceRecord.InvoiceLines) {
                //Process Invoice Line that is Adjustment (Promotion) and Amount is different from zero
                if (invoiceLine.Type.equalsIgnoreCase('Adjustment') && invoiceLine.LineAmount != 0.00) {
                    if (!mapInvoicePromotionLines.containsKey(invoiceLine.RelatedLineId)) {
                        mapInvoicePromotionLines.put(invoiceLine.RelatedLineId, new List<InvoiceLine>());
                    }
                    mapInvoicePromotionLines.get(invoiceLine.RelatedLineId).add(invoiceLine);
                } else if (invoiceLine.Type.equalsIgnoreCase('Tax')) {
                    //If Line is Tax then store value (to associate with Line)
                    taxMap.put(invoiceLine.RelatedLineId, invoiceLine.LineAmount);
                }
            }
        }

        //Build Map with Promotion Lines in Credit Memos
        Map<String, List<CreditMemoLine>> mapCreditMemoPromotionLines = new Map<String, List<CreditMemoLine>>();
        for (CreditMemo creditMemoRecord : creditMemoList) {
            for (CreditMemoLine creditMemoLineRecord : creditMemoRecord.CreditMemoLines) {
                //Process Credit Memo Line that is Adjustment (Promotion) and Amount is different from zero
                if (creditMemoLineRecord.Type.equalsIgnoreCase('Adjustment') && creditMemoLineRecord.LineAmount != 0.00) {
                    if (!mapCreditMemoPromotionLines.containsKey(creditMemoLineRecord.RelatedLineId)) {
                        mapCreditMemoPromotionLines.put(creditMemoLineRecord.RelatedLineId, new List<CreditMemoLine>());
                    }
                    mapCreditMemoPromotionLines.get(creditMemoLineRecord.RelatedLineId).add(creditMemoLineRecord);
                } else if (creditMemoLineRecord.Type.equalsIgnoreCase('Tax')) {
                    //If Line is Tax then store value (to associate with Line)
                    taxMap.put(creditMemoLineRecord.RelatedLineId, creditMemoLineRecord.LineAmount);
                }
            }
        }
        // Get billing country type
        String clientType = '';
        if (accountRecord.BillingCountryCode.equalsIgnoreCase('pt')) {
            clientType = 'NAC';
        } else if (COMM_EUROCOUNTRIES.containsIgnoreCase(accountRecord.BillingCountryCode)) {
            clientType = 'COM';
        } else {
            clientType = 'OT';
        }

        //Initialze Map to store Invoice Line Items. Key is Id of Related OrderItemSummary Record
        Map<String, List<COMM_SL_SAPDocumentRequest.OrderItems>> invoiceItemMap = new Map<String, List<COMM_SL_SAPDocumentRequest.OrderItems>>();
        //Initialize Map to store Line Item's Amount and Tax Amount (to obtain Total Amount at the end)
        Map<String, AmountCalc> totalAmountMap = new Map<String, AmountCalc>();
        //Process Invoices
        for (Invoice invoiceRecord : invoiceList) {
            if (Date.valueOf(controlDate).monthsBetween(Date.valueOf(invoiceRecord.DueDate)) == 0) {
                accountRelatedInvoice.add(invoiceRecord);
                for (InvoiceLine invoiceLineRecord : invoiceRecord.InvoiceLines) {
                    //If Document to send to SAP is Invoice and Line is Tax then add amount to Map.
                    if (isInvoiceDocument && invoiceLineRecord.Type.equalsIgnoreCase('Tax')) {
                        String orderItemId = ((OrderItemSummary) invoiceLineRecord.ReferenceEntityItem).Id;
                        AmountCalc lineAmount = totalAmountMap.containsKey(orderItemId) ? totalAmountMap.get(orderItemId) : new AmountCalc();
                        lineAmount.taxAmount += invoiceLineRecord.LineAmount;
                        totalAmountMap.put(orderItemId, lineAmount);
                    }

                    //Skip Line if Type isn't Charge and Reference Item is Delivery Charge.
                    if (
                        !invoiceLineRecord.Type.equalsIgnoreCase('Charge') ||
                        invoiceLineRecord.ReferenceEntityItemType.equalsIgnoreCase('Delivery Charge')
                    ) {
                        continue;
                    }
                    COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
                    line.location = invoiceLineRecord.Product2.COMM_SAPLocation__c;
                    line.productId = invoiceLineRecord.Product2.StockKeepingUnit;
                    String taxCode = invoiceLineRecord.Product2.COMM_Tax__c == null ? 'Continent' : invoiceLineRecord.Product2.COMM_Tax__c;
                    line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('FT', taxCode, clientType);
                    line.quantity = invoiceLineRecord.Quantity;
                    line.description = ((OrderItemSummary) invoiceLineRecord.ReferenceEntityItem).Description;
                    line.totalNetAmount = invoiceLineRecord.LineAmount;
                    line.totalVatAmount = taxMap.get(invoiceLineRecord.Id);
                    line.itemReference = null;

                    //Store Line Item Amount
                    String orderItemId = ((OrderItemSummary) invoiceLineRecord.ReferenceEntityItem).Id;
                    //If Document to send to SAP is Invoice then store line Amount
                    if (isInvoiceDocument) {
                        AmountCalc lineAmount = totalAmountMap.containsKey(orderItemId) ? totalAmountMap.get(orderItemId) : new AmountCalc();
                        lineAmount.amount += invoiceLineRecord.LineAmount;
                        totalAmountMap.put(orderItemId, lineAmount);
                    }
                    if (!invoiceItemMap.containsKey(orderItemId)) {
                        invoiceItemMap.put(orderItemId, new List<COMM_SL_SAPDocumentRequest.OrderItems>());
                    }
                    invoiceItemMap.get(orderItemId).add(line);

                    //If Document to be sent to SAP then check if there are promotion lines
                    List<InvoiceLine> promoInvoiceLineList = mapInvoicePromotionLines.get(invoiceLineRecord.Id);
                    if (
                        isInvoiceDocument &&
                        promoInvoiceLineList != null &&
                        !promoInvoiceLineList.isEmpty() &&
                        invoiceLineRecord.Type.equalsIgnoreCase('Charge')
                    ) {
                        for (InvoiceLine promoInvoiceLine : promoInvoiceLineList) {
                            COMM_SL_SAPDocumentRequest.OrderItems promoLine = line.clone();
                            //Set Promotion Id as Item Reference
                            String promotionId = promotionNameByOrderItemSummaryMap?.get(orderItemId + String.valueOf(promoInvoiceLine.LineAmount));
                            promoLine.itemReference = promotionId?.left(ITEM_REFERENCE_LIMIT);
                            //Add Net and Tax Amount of Promotion Lines
                            promoLine.totalNetAmount = promoInvoiceLine.LineAmount;
                            promoLine.totalVatAmount = taxMap.get(promoInvoiceLine.Id);
                            //Update Invoice Item Amount with Promotion Line
                            AmountCalc lineAmount = totalAmountMap.get(orderItemId);
                            lineAmount.amount += promoLine.totalNetAmount;
                            totalAmountMap.put(orderItemId, lineAmount);
                            //Add Promotion Line to Invoice List
                            invoiceItemMap.get(orderItemId).add(promoLine);
                        }
                    }
                }
            }
        }

        Map<String, SAPData> orderSummaryInvoiceMap = getCreditMemosOriginalSAPInvoices(creditMemoList);
        Datetime oldestDate;
        Datetime newestDate;
        List<COMM_SL_SAPDocumentRequest.OrderItems> creditItemList = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
        for (CreditMemo creditMemoRecord : creditMemoList) {
            if (Date.valueOf(controlDate).monthsBetween(Date.valueOf(creditMemoRecord.CreditDate)) == 0) {
                accountRelatedCreditMemo.add(creditMemoRecord);
                for (CreditMemoLine creditMemoLineRecord : creditMemoRecord.CreditMemoLines) {
                    //If Document to send to SAP is CreditNote and Line is Tax then add amount to Map as tax value.
                    if (!isInvoiceDocument && creditMemoLineRecord.Type.equalsIgnoreCase('Tax')) {
                        String orderItemId = ((OrderItemSummary) creditMemoLineRecord.ReferenceEntityItem).Id;
                        AmountCalc lineAmount = totalAmountMap.containsKey(orderItemId) ? totalAmountMap.get(orderItemId) : new AmountCalc();
                        lineAmount.taxAmount += creditMemoLineRecord.LineAmount;
                        totalAmountMap.put(orderItemId, lineAmount);
                    }

                    //Skip Line if Type isn't Charge and Reference Item is Delivery Charge.
                    if (
                        !creditMemoLineRecord.Type.equalsIgnoreCase('Charge') ||
                        creditMemoLineRecord.ReferenceEntityItemType.equalsIgnoreCase('Delivery Charge')
                    ) {
                        continue;
                    }
                    COMM_SL_SAPDocumentRequest.OrderItems line = new COMM_SL_SAPDocumentRequest.OrderItems();
                    line.location = creditMemoLineRecord.Product2.COMM_SAPLocation__c;
                    line.productId = creditMemoLineRecord.Product2.StockKeepingUnit;
                    String taxCode = creditMemoLineRecord.Product2.COMM_Tax__c == null ? 'Continent' : creditMemoLineRecord.Product2.COMM_Tax__c;
                    line.taxCode = COMM_REP_SapTaxCodesMapMdt.getSapTaxCodesMap('NC', taxCode, clientType);
                    line.quantity = 1;
                    line.description = ((OrderItemSummary) creditMemoLineRecord.ReferenceEntityItem).Description;
                    line.totalNetAmount = creditMemoLineRecord.LineAmount;
                    line.totalVatAmount = taxMap.get(creditMemoLineRecord.Id);

                    //Check if Credit Note is a return for an Invoice for current month
                    Id orderItemId = ((OrderItemSummary) creditMemoLineRecord.ReferenceEntityItem).Id;
                    if (invoiceItemMap.containsKey(orderItemId)) {
                        //Remove Invoice and don't include credit
                        invoiceItemMap.remove(orderItemId);
                        totalAmountMap.remove(orderItemId);
                    } else {
                        //Verify SAP Invoice Data
                        SapData sapInfo = orderSummaryInvoiceMap.get(((OrderSummary) creditMemoRecord.ReferenceEntity).id);
                        String originalInvoice = sapInfo?.sapDocumentId;
                        line.itemReference = originalInvoice;

                        if (oldestDate == null || (sapInfo?.issuanceDate != null && sapInfo.issuanceDate < oldestDate)) {
                            oldestDate = sapInfo.issuanceDate;
                        }
                        if (newestDate == null || (sapInfo?.issuanceDate != null && sapInfo.issuanceDate > newestDate)) {
                            newestDate = sapInfo.issuanceDate;
                        }
                        //Store Line Item Amount
                        creditItemList.add(line);
                        //Calculate Amount and Tax Amount (if Document to send to SAP is CreditNote)
                        if (!isInvoiceDocument) {
                            AmountCalc lineAmount = totalAmountMap.containsKey(orderItemId) ? totalAmountMap.get(orderItemId) : new AmountCalc();
                            lineAmount.amount += creditMemoLineRecord.LineAmount;
                            totalAmountMap.put(orderItemId, lineAmount);
                        }

                        //If Document to be sent to SAP then check if there are promotion lines
                        List<CreditMemoLine> promoCreditMemoLineList = mapCreditMemoPromotionLines.get(creditMemoLineRecord.Id);
                        if (
                            !isInvoiceDocument &&
                            promoCreditMemoLineList != null &&
                            !promoCreditMemoLineList.isEmpty() &&
                            creditMemoLineRecord.Type.equalsIgnoreCase('Charge')
                        ) {
                            for (CreditMemoLine promoCreditMemoLine : promoCreditMemoLineList) {
                                COMM_SL_SAPDocumentRequest.OrderItems promoLine = line.clone();
                                //Sum Net Amount of Promotion Lines
                                promoLine.totalNetAmount = promoCreditMemoLine.LineAmount;
                                promoLine.totalVatAmount = taxMap.get(promoCreditMemoLine.Id);
                                //Update Invoice Item Amount with Promotion Line
                                AmountCalc lineAmount = totalAmountMap.containsKey(orderItemId) ? totalAmountMap.get(orderItemId) : new AmountCalc();
                                lineAmount.amount += promoLine.totalNetAmount;
                                totalAmountMap.put(orderItemId, lineAmount);
                                //Add Promotion line to Credit Item List
                                creditItemList.add(promoLine);
                            }
                        }
                    }
                }
            }
        }

        if (isInvoiceDocument) {
            List<COMM_SL_SAPDocumentRequest.OrderItems> invoiceItemList = new List<COMM_SL_SAPDocumentRequest.OrderItems>();
            for (List<COMM_SL_SAPDocumentRequest.OrderItems> itemList : invoiceItemMap.values()) {
                invoiceItemList.addAll(itemList);
            }
            request.orderItems = aggregateOrderItems(invoiceItemList);
        } else {
            request.orderItems = aggregateOrderItems(creditItemList);
        }

        request.documentType = isInvoiceDocument ? 'Invoice' : 'CreditNote';
        request.paymentDays = isInvoiceDocument ? CREDIT_PAYMENT_DAYS : null;

        //If Credit Note then add Invoice Dates to Reference
        if (!isInvoiceDocument && oldestDate != null && newestDate != null) {
            request.reference = oldestDate.format('MM.yyyy') + '-' + newestDate.format('MM.yyyy');
        }

        //Calculate Total Amount and Total Tax Amount from lines
        Decimal creditPaymentTotalAmount = 0.0;
        Decimal creditPaymentTotalTaxAmount = 0.0;
        for (AmountCalc lineAmounts : totalAmountMap.values()) {
            //Ignore Null Amounts (ex: Shipping)
            if (lineAmounts.amount != null && lineAmounts.taxAmount != null) {
                creditPaymentTotalAmount += lineAmounts.amount;
                creditPaymentTotalTaxAmount += lineAmounts.taxAmount;
            }
        }
        request.netAmount = Math.abs(creditPaymentTotalAmount);
        request.taxAmout = Math.abs(creditPaymentTotalTaxAmount);

        return request;
    }

    /**
     * @description Aggregate Order Items based on all fields populated and increment quantity and amount
     * @param orderItemsList List of Order Items
     * @return List<COMM_SL_SAPDocumentRequest.OrderItems>
     */
    private static List<COMM_SL_SAPDocumentRequest.OrderItems> aggregateOrderItems(List<COMM_SL_SAPDocumentRequest.OrderItems> orderItemsList) {
        Map<String, COMM_SL_SAPDocumentRequest.OrderItems> aggregatedMap = new Map<String, COMM_SL_SAPDocumentRequest.OrderItems>();
        for (COMM_SL_SAPDocumentRequest.OrderItems item : orderItemsList) {
            // Build a unique key based on non-numeric fields for grouping (location, productId, taxCode, description, itemReference)
            String key = item.location + '|' + item.productId + '|' + item.taxCode + '|' + item.description + '|' + item.itemReference;

            // Check if an entry already exists in the map and update it, if not add it
            if (aggregatedMap.containsKey(key)) {
                COMM_SL_SAPDocumentRequest.OrderItems existingItem = aggregatedMap.get(key);
                existingItem.quantity += item.quantity;
                existingItem.totalNetAmount += item.totalNetAmount;
                existingItem.totalVatAmount += item.totalVatAmount;
            } else {
                aggregatedMap.put(key, item.clone());
            }
        }

        // Return the aggregated order items as a list
        return aggregatedMap.values();
    }

    /**
     * @description Update input Map based on the HTTP Response
     * @param sobjectRecordList List of Invoice / Credit Memo object
     * @param response SAP HTTP response
     * @param sobjectToUpdateList List of Invoice / Credit Memo object to update
     * @return String error message
     */
    public static void handleResponseGeneric(
        List<SObject> sobjectRecordList,
        COMM_SL_SAPDocumentResponse response,
        List<sObject> sobjectToUpdateList
    ) {
        // Response can be a list of errors
        Boolean registerSAPDocumentId = false;

        if (response != null && String.isEmpty(response.resultCode)) {
            // register sap document id
            registerSAPDocumentId = true;
        }
        for (SObject sobjectRecord : sobjectRecordList) {
            if (registerSAPDocumentId) {
                sobjectRecord.put('COMM_SAPDocumentId__c', response.documentId);
                sobjectRecord.put('COMM_IssuanceDate__c', Date.today());
            }
            sobjectRecord.put('COMM_SAPLastLog__c', response != null ? System.JSON.serialize(response) : '');
            sobjectRecord.put('COMM_SAPIntegrationDate__c', Datetime.now());
            sobjectRecord.put('COMM_SAPCount__c', (Decimal) sobjectRecord.get('COMM_SAPCount__c') + 1);
            sobjectToUpdateList.add(sobjectRecord);
        }
    }
    /**
     * @description Update Records with information about not being sent to SAP
     * @param sobjectRecordList List of Invoice / Credit Memo object
     * @param sobjectToUpdateList List of Invoice / Credit Memo object to update
     */
    public static void handleNoItems(List<SObject> sobjectRecordList, List<sObject> sobjectToUpdateList) {
        for (SObject sobjectRecord : sobjectRecordList) {
            sobjectRecord.put('COMM_SAPDocumentId__c', '-1');
            sobjectRecord.put('COMM_IssuanceDate__c', Date.today());
            sobjectRecord.put('COMM_SAPLastLog__c', 'item was canceled in the same month it was ordered');
            sobjectRecord.put('COMM_SAPIntegrationDate__c', Datetime.now());
            sobjectRecord.put('COMM_SAPCount__c', (Decimal) sobjectRecord.get('COMM_SAPCount__c') + 1);
            sobjectToUpdateList.add(sobjectRecord);
        }
    }

    /**
     * @description Do SAP HTTP Request + handle response and update related Invoice and Credit Memo records
     * @param request SAP HTTP request
     * @param accountRelatedInvoiceDuringControlDate List of Invoice object to process
     * @param accountRelatedCreditMemoDuringControlDate List of Credit Memo object to process
     * @param invoiceToUpdateList List of Invoice object to Update
     * @param creditMemoToUpdateList List of Credit Memo object to Update
     * @return JSON with SAP response
     */
    public static COMM_SL_SAPDocumentResponse DoCallAndHandleResponse(
        COMM_SL_SAPDocumentRequest request,
        List<SObject> accountRelatedRecordDuringControlDate,
        List<SObject> recordToUpdateList
    ) {
        COMM_SL_SAPDocumentResponse response;
        String errorMessage;

        try {
            COMM_OMS_UnifiedSettings__mdt setting = COMM_OMS_UnifiedSettings__mdt.getInstance(SAP_LOAD_TEST);
            response = COMM_SL_GenerateSAPDoc.makeCallout(request, Boolean.valueOf(setting.COMM_Value__c));
        } catch (Exception ex) {
            COMM_GEN_Utility.logError(
                ex,
                'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                'COMM_SL_OMS_SAPHandler'
            );
        }
        // Handle Error Message + update records to include SAP response data
        COMM_SL_OMS_SAPHandler.handleResponseGeneric(accountRelatedRecordDuringControlDate, response, recordToUpdateList);

        return response;
    }

    /**
     * @description Receives a list of Credit Memos and returns a map with the original OrderSummaryId and the original SAP Invoice Data
     * @param creditMemoList List of CreditMemos
     * @return Map with OrderSummaryId and Original Invoice from SAP
     */
    public static Map<String, SAPData> getCreditMemosOriginalSAPInvoices(List<CreditMemo> creditMemoList) {
        Map<String, SAPData> orderSummaryInvoiceMap = new Map<String, SAPData>();
        List<String> orderSummaryIdList = new List<String>();
        for (CreditMemo creditMemoRecord : creditMemoList) {
            orderSummaryIdList.add(((OrderSummary) creditMemoRecord.ReferenceEntity).id);
        }
        List<OrderSummary> creditMemosOrderSummaryList = orderSummaryRep.getByIds(orderSummaryIdList);
        for (OrderSummary orderSummaryRecord : creditMemosOrderSummaryList) {
            SAPData sapInfo = new SAPData();
            sapInfo.sapDocumentId = orderSummaryRecord.invoices[0].COMM_SAPDocumentId__c;
            sapInfo.issuanceDate = orderSummaryRecord.invoices[0].COMM_IssuanceDate__c;
            sapInfo.invoiceAmount = orderSummaryRecord.invoices[0].TotalAmount;
            sapInfo.fullyReturned = true;
            orderSummaryInvoiceMap.put(orderSummaryRecord.id, sapInfo);
        }

        //Verify if Credit Memo fully returned Invoice (TotalAmount are the same) or just Parcial (TotalAmount are different)
        for (CreditMemo creditMemoRecord : creditMemoList) {
            String orderId = ((OrderSummary) creditMemoRecord.ReferenceEntity).id;
            if (creditMemoRecord.TotalAmount != orderSummaryInvoiceMap.get(orderId).invoiceAmount) {
                orderSummaryInvoiceMap.get(orderId).fullyReturned = false;
            }
        }

        return orderSummaryInvoiceMap;
    }

    /**
     * @description Retrieves a map of CreditMemo Ids to lists of related Refund records filtered by gift card Refunds.
     *              This method collects all ReferenceEntityIds from the provided CreditMemos, uses them to fetch Refunds
     *              related to gift cards, and organizes these Refunds by the corresponding CreditMemo Ids.
     * @param creditMemoList List of CreditMemo records to retrieve related gift card Refunds for.
     * @return Map<String, List<Refund>> where each key is an CreditMemo Id and the value is a list of Refund records
     *         associated with that CreditMemo and filtered by the gift card Refund gateway.
     */
    private static Map<String, List<Refund>> getCreditMemoGiftCardRefunds(List<CreditMemo> creditMemoList) {
        Set<Id> orderSummaryIdSet = new Set<Id>();
        Map<String, List<Refund>> creditMemoGiftRefundsMap = new Map<String, List<Refund>>();
        for (CreditMemo creditMemoRecord : creditMemoList) {
            orderSummaryIdSet.add(creditMemoRecord.ReferenceEntityId);
            creditMemoGiftRefundsMap.put(creditMemoRecord.Id, new List<Refund>());
        }
        // Fetch gift refunds using the orderSummaryIdSet
        List<Refund> giftRefunds = refundRep.getRefundsByOrderSummaryId(orderSummaryIdSet, GIFTCARD_PAYMENTGATEWAY_NAME_LIST);

        // Populate the map with refunds
        for (Refund refundRecord : giftRefunds) {
            Id orderSummaryId = refundRecord.OrderPaymentSummary.OrderSummaryId;

            // Find matching CreditMemo based on ReferenceEntityId
            for (CreditMemo creditMemoRecord : creditMemoList) {
                if (creditMemoRecord.ReferenceEntityId == orderSummaryId && refundRecord.ClientContext.Contains(creditMemoRecord.id)) {
                    creditMemoGiftRefundsMap.get(creditMemoRecord.Id).add(refundRecord);
                }
            }
        }

        return creditMemoGiftRefundsMap;
    }

    /**
     * @description Retrieves a map of Invoice Ids to lists of related Payment records filtered by gift card payments.
     *              This method collects all ReferenceEntityIds from the provided invoices, uses them to fetch payments
     *              related to gift cards, and organizes these payments by the corresponding Invoice Ids.
     * @param invoiceList List of Invoice records to retrieve related gift card payments for.
     * @return Map<String, List<Payment>> where each key is an Invoice Id and the value is a list of Payment records
     *         associated with that Invoice and filtered by the gift card payment gateway.
     */
    private static Map<String, List<Payment>> getInvoiceGiftCardPayments(List<Invoice> invoiceList) {
        Set<Id> orderSummaryIdSet = new Set<Id>();
        Map<String, List<Payment>> invoiceGiftPaymentsMap = new Map<String, List<Payment>>();
        for (Invoice invoiceRecord : invoiceList) {
            orderSummaryIdSet.add(invoiceRecord.ReferenceEntityId);
            invoiceGiftPaymentsMap.put(invoiceRecord.Id, new List<Payment>());
        }

        // Fetch gift payments using the orderSummaryIdSet
        List<Payment> giftPayments = paymentRep.getPaymentsByOrderSummaryId(orderSummaryIdSet, GIFTCARD_PAYMENTGATEWAY_NAME_LIST);

        // Populate the map with payments
        for (Payment paymentRecord : giftPayments) {
            Id orderSummaryId = paymentRecord.OrderPaymentSummary.OrderSummaryId;

            // Find matching Invoice based on ReferenceEntityId
            for (Invoice invoiceRecord : invoiceList) {
                if (invoiceRecord.ReferenceEntityId == orderSummaryId) {
                    invoiceGiftPaymentsMap.get(invoiceRecord.Id).add(paymentRecord);
                }
            }
        }

        return invoiceGiftPaymentsMap;
    }

    /**
     * @description Populates request billing fields or applies kiosk defaults when VAT is missing.
     *
     * @return true if default data was applied, false otherwise
     */
    @TestVisible
    private static void populateBillingData(
        COMM_SL_SAPDocumentRequest request,
        String billingEmail,
        String billingAddress,
        String billingPostalCode,
        String billingCity,
        String billingCountryCode,
        String billingVatNumber,
        String billingName,
        String vatNumberDetector
    ) {
        Boolean useDefaultBillingData = vatNumberDetector == null ? String.isBlank(billingVatNumber) : String.isBlank(vatNumberDetector);
        if (useDefaultBillingData) {
            request.billingEmail = DEFAULT_BILLING_EMAIL;
            request.billingAddress = DEFAULT_BILLING_ADDRESS;
            request.billingPostalCode = DEFAULT_BILLING_POSTAL_CODE;
            request.billingCity = DEFAULT_BILLING_CITY;
            request.billingVat = defaultVATNumber;
            request.billingCountry = DEFAULT_BILLING_COUNTRY;
            verifyName(DEFAULT_BILLING_NAME, request);
            return;
        }
        String effectiveCountry = String.isBlank(billingCountryCode) ? DEFAULT_BILLING_COUNTRY : billingCountryCode;
        request.billingEmail = billingEmail;
        request.billingAddress = billingAddress;
        request.billingPostalCode = billingPostalCode;
        request.billingCity = billingCity;
        request.billingVat = effectiveCountry + billingVatNumber;
        request.billingCountry = effectiveCountry;
        verifyName(billingName, request);
    }

    /**
     * @description Verify if Billing Name's Lenght passes SAP Limit.
     * If it is then split it between Billing Name and Addicional Billing Name.
     *
     * @param billingName Billing Name to be added to request
     * @param request Request to be sent to SAP
     */
    private static void verifyName(String billingName, COMM_SL_SAPDocumentRequest request) {
        if (String.isNotBlank(billingName)) {
            request.billingName = billingName.left(BILLING_NAME_LIMIT);
            //Verify Billing Name lenght. If it passes then split Name into Billing Name and Additional Billing Name fields.
            if (billingName.length() > BILLING_NAME_LIMIT) {
                //Verify if Remaining Chars don't pass Limit. If they do then truncate Additional Name.
                Integer endIndex = billingName.length() - BILLING_NAME_LIMIT <= BILLING_ADDITIONAL_NAME_LIMIT
                    ? billingName.length()
                    : BILLING_NAME_LIMIT + BILLING_ADDITIONAL_NAME_LIMIT;
                request.billingAddicionalName = billingName.substring(BILLING_NAME_LIMIT, endIndex);
            }
        }
    }

    /**
     * @description get the default GiftCard product to send in GiftCard payments
     *
     * @return Product2 default giftCard product
     */
    private static void getGiftCardPaymentDefaultProduct() {
        if (defaultGiftCardPaymentProduct == null) {
            defaultGiftCardPaymentProduct = product2Rep.getProductsByProductCodes(new List<String>{ SAP_GIFTCARD_PAYMENT_DEFAULT_PRODUCT })
                .get(SAP_GIFTCARD_PAYMENT_DEFAULT_PRODUCT);
        }
        if (defaultGiftCardPaymentProduct == null) {
            throw new DefaultGiftCardProductException(ERROR_DEFAULT_GIFTCARD_NOTFOUND + SAP_GIFTCARD_PAYMENT_DEFAULT_PRODUCT);
        }
    }

    /**
     * @description Define a custom exception class for GiftCard Default Product
     */
    private class DefaultGiftCardProductException extends Exception {
    }

    /**
     * @description Inner Class to represent Order that was sent to SAP
     */
    private class SAPData {
        private String sapDocumentId { get; set; }
        private Datetime issuanceDate { get; set; }
        private Boolean fullyReturned { get; set; }
        private Decimal invoiceAmount { get; set; }
    }

    /**
     * @description Inner Class to represent a Line Item's Amount
     */
    private class AmountCalc {
        private Decimal amount { get; set; }
        private Decimal taxAmount { get; set; }

        private AmountCalc() {
            this.amount = 0.0;
            this.taxAmount = 0.0;
        }
    }
}
