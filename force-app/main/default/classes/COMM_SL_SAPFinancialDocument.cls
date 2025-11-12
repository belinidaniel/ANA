/**
 * @author Daniel Lascas
 * @description Service Layer Class with methods to retrive and generate financial
 * documents by communicating with SAP
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer		Date             Description
 * ------------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-194: Original version
 * Daniel Lascas    05/09/2024       CR-41: Added Item Refence for Cortesy Purchases and Discount
 **/
public with sharing class COMM_SL_SAPFinancialDocument {
    //Values for Document Type
    public static final String DOCUMENT_TYPE_INVOICE = 'Invoice';
    public static final String DOCUMENT_TYPE_CREDIT = 'CreditNote';

    //Values for Document Creation
    public static final String PAYMENT_MODE_PREPAID = 'Prepaid';
    public static final String PAYMENT_MODE_CREDIT = 'Credit';
    public static final String DOCUMENT_GENERATION_NOT_KIOSK = 'FT';
    public static final String DOCUMENT_GENERATION_KIOSK = 'FS';

    //Values for Item Refennce
    private static final String COURTESY_REFERENCE = 'Cortesia';

    //Variable in SAP Request
    private static final String DOCUMENT_TYPE = 'documentType';
    private static final String DOCUMENT_DATE = 'documentDate';
    private static final String DOCUMENT_NUMBER = 'documentNumber';
    private static final String PAYMENT_MODE = 'paymentMode';
    private static final String PAYMENT_DAYS = 'paymentDays';
    private static final String DOCUMENT_ID = 'id';
    private static final String DOCUMENT_SERIE = 'documentSerie';
    private static final String BILLING_NAME = 'billingName';
    private static final String BILLING_ADDITIONAL_NAME = 'billingAddicionalName';
    private static final String BILLING_ADDRESS = 'billingAddress';
    private static final String BILLING_DATE = 'billingDate';
    private static final String BILLING_EMAIL = 'billingEmail';
    private static final String DOCUMENT_NET_AMOUNT = 'netAmount';
    private static final String DOCUMENT_ORDER_ITEMS = 'orderItems';
    private static final String DUE_DATE = 'dueDate';
    private static final String VAT_DIFFERENCE_AMOUNT = 'vatDifferenceAmount';
    private static final Decimal VAT_DIFFERENCE_DEFAULT_VALUE = 0.00;
    private static final Integer ID_CHAR_LIMIT = 16;
    private static final Integer BILLING_ADDRESS_LIMIT = 35;
    private static final Integer BILLING_NAME_LIMIT = 35;
    private static final Integer BILLING_ADDITIONAL_NAME_LIMIT = 35;

    //Variable in SAP Request (Invoice Item)
    private static final String INVOICE_PRODUCT_ID = 'productId';
    private static final String INVOICE_EXEMPT_PAYMENT = 'exemptPayment';
    private static final String INVOICE_QUANTITY = 'quantity';
    private static final String INVOICE_NET_AMOUNT = 'totalNetAmount';
    private static final String INVOICE_TAX_AMOUNT = 'taxAmout';
    private static final String INVOICE_DESCRIPTION = 'description';
    private static final String INVOICE_ITEM_TAX_AMOUNT = 'totalVatAmount';
    private static final String INVOICE_ITEM_REFERENCE = 'itemReference';
    private static final Integer DESCRIPTION_CHAR_LIMIT = 40;

    //Variable in SAP Response
    private static final String FILE_CONTENT = 'fileContent';
    private static final String FILE_NAME = 'fileName';
    private static final String SAP_ID = 'documentId';
    private static final String RESULT_CODE = 'resultCode';
    private static final String RESULT_DESCRIPTION = 'resultDesc';

    //Maximum Size for Field to store sent JSON in SF
    private static final Integer MAX_JSON_LENGTH = 131072;

    private COMM_IDO_SAPMapping sapMappingDo;
    private COMM_IWS_SAPFinancialDocument sapWs;

    public COMM_SL_SAPFinancialDocument() {
        this.sapMappingDo = new COMM_DO_SAPMapping();
        this.sapWs = new COMM_WS_SAPFinancialDocument();
    }

    @TestVisible
    private COMM_SL_SAPFinancialDocument(COMM_IDO_SAPMapping sapMappingDo, COMM_IWS_SAPFinancialDocument sapWs) {
        this.sapMappingDo = sapMappingDo;
        this.sapWs = sapWs;
    }

    /**
     * @description Send request to SAP to obtain Financial Document
     *
     * @param documentType The type of Document to retrieve (Invoice or CreditNote)
     * @param documentDate The date the document was generated
     * @param documentNumber The SAP number that identifies the document to retrieve
     * @return Document from SAP as an Attachment Record
     */
    public Attachment getFinancialDocument(String documentType, Date documentDate, String documentNumber) {
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(DOCUMENT_TYPE, documentType);
        requestMap.put(DOCUMENT_DATE, String.valueOf(documentDate));
        requestMap.put(DOCUMENT_NUMBER, documentNumber);

        HttpResponse response = sapWs.getFinancialDocument(requestMap);
        Map<String, String> responseMap = (Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class);

        //If File wasn't returned, log error and throw error message to User informing an error occured
        if (!responseMap.containsKey(FILE_CONTENT)) {
            Exception e = new AuraException(System.Label.COMM_SUBSCRIPTION_INVOICE_DOCUMENT_GENERATION_ERROR);
            COMM_GEN_Utility.logError(e, 'Error obtaining fiscal document: ' + JSON.serialize(responseMap), 'COMM_SL_SAPFinancialDocument');
            throw e;
        }

        Attachment fileAttachment = new Attachment();
        fileAttachment.Body = EncodingUtil.base64Decode(responseMap.get(FILE_CONTENT));
        fileAttachment.Name = responseMap.get(FILE_NAME);

        return fileAttachment;
    }

    /**
     * @description Send request to generate a Financial Document to SAP using Account Data and list of
     * invoice records. Mapping is done according to Custom Metadata SAP Mappings.
     *
     * @param clientEmail Email of the client to sent to SAP
     * @param controlRecord Control Record in Salesforce associated with invoice
     * @param accRecord The client's account to retrieve data
     * @param saleDate Date when Sale was made (ex: Last Day of Month)
     * @param paymentDays Number of days for Client to pay invoice
     * @param invoiceList List of Salesforce Records that represent an Invoice (ex: Invoice or Subscription Invoice)
     * @return Number from SAP that identifies the generated financial document
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public COMM_SL_SAPDocumentResponse createFinancialDocument(
        String clientEmail,
        COMM_MonthlyFiscalDocumentControl__c controlRecord,
        Account accRecord,
        Date saleDate,
        Integer paymentDays,
        List<SObject> invoiceList
    ) {
        //Map to store invoice line items without discount applied
        Map<String, Map<String, Object>> processedInvoiceItemsMap = new Map<String, Map<String, Object>>();
        //Map to store invoice line items where discount is applied (purchase line)
        Map<String, Map<String, Object>> processedPurchaseDiscountInvoiceItemsMap = new Map<String, Map<String, Object>>();
        //Map to store invoice line items where discount is applied (discount line)
        Map<String, Map<String, Object>> processedDiscountInvoiceItemsMap = new Map<String, Map<String, Object>>();
        //List of Invoice Items (with and without discount) to be sent to SAP
        List<Map<String, Object>> invoiceItemList = new List<Map<String, Object>>();

        for (SObject invoiceItem : invoiceList) {
            //Check and add primary invoice item (ex: Subscription Product)
            Map<String, Object> invoiceItemMap = sapMappingDo.mapJsonFromSObject(invoiceItem, new Map<String, Object>(), false);
            addInvoiceItemToMap(
                invoiceItemMap,
                invoiceItemList,
                processedInvoiceItemsMap,
                processedPurchaseDiscountInvoiceItemsMap,
                processedDiscountInvoiceItemsMap
            );
            //Check and add additional invoice item (ex: Card Product)
            Map<String, Object> additionalItemMap = sapMappingDo.mapJsonFromSObject(invoiceItem, new Map<String, Object>(), true);
            addInvoiceItemToMap(
                additionalItemMap,
                invoiceItemList,
                processedInvoiceItemsMap,
                processedPurchaseDiscountInvoiceItemsMap,
                processedDiscountInvoiceItemsMap
            );
        }

        //Create Request Map (structured like a JSON)
        Map<String, Object> requestMap = buildCreateDocRequestMap(invoiceItemList, accRecord, controlRecord.Id, clientEmail, paymentDays, saleDate);

        //Build Request to SAP, make callout then return response
        COMM_SL_SAPDocumentRequest sapRequest = COMM_SL_SAPDocumentRequest.parse(JSON.serialize(requestMap, true));
        //Store JSON sent for logging
        controlRecord.COMM_SentRequestJson__c = JSON.serialize(sapRequest, true)?.left(MAX_JSON_LENGTH);
        COMM_SL_SAPDocumentResponse sapResponse = COMM_SL_GenerateSAPDoc.makeCallout(sapRequest, false);

        return sapResponse;
    }

    /**
     * @description Add Invoice Item to Map.
     * Checks if Item was processed previously, it it was increment quantity, if not add as new item.
     *
     * @param invoiceItemMap Invoice Item to be added
     * @param invoiceItemList List with all the invoices (with and without discount)
     * @param processedInvoiceItemsMap Map with all the invoice line items already processed
     * @param processedPurchaseDiscountInvoiceItemsMap Map with all the invoice line items related to discounts (purchase lines)
     * @param processedDiscountInvoiceItemsMap Map with all the invoice line items related to discounts (discount lines)
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void addInvoiceItemToMap(
        Map<String, Object> invoiceItemMap,
        List<Map<String, Object>> invoiceItemList,
        Map<String, Object> processedInvoiceItemsMap,
        Map<String, Object> processedPurchaseDiscountInvoiceItemsMap,
        Map<String, Map<String, Object>> processedDiscountInvoiceItemsMap
    ) {
        Decimal netAmount = (Decimal) invoiceItemMap.get(INVOICE_NET_AMOUNT);
        //Check if invoice item has Id and Price to add it to invoice
        if (!invoiceItemMap.isEmpty() && invoiceItemMap.get(INVOICE_PRODUCT_ID) != null && netAmount != null) {
            verifyInvoiceItem(invoiceItemMap);

            String productId = (String) invoiceItemMap.get(INVOICE_PRODUCT_ID);
            Boolean isExempt = invoiceItemMap.containsKey(INVOICE_EXEMPT_PAYMENT) && Boolean.valueOf(invoiceItemMap.get(INVOICE_EXEMPT_PAYMENT));

            //Verify if a Product with same code was processed. If it was then increment quantiy, net amount and tax amount.
            if (
                (!isExempt && processedInvoiceItemsMap.containsKey(productId)) ||
                (isExempt && processedPurchaseDiscountInvoiceItemsMap.containsKey(productId))
            ) {
                Map<String, Object> existingInvoiceItem = isExempt
                    ? (Map<String, Object>) processedPurchaseDiscountInvoiceItemsMap.get(productId)
                    : (Map<String, Object>) processedInvoiceItemsMap.get(productId);
                existingInvoiceItem.put(INVOICE_QUANTITY, ((Decimal) existingInvoiceItem.get(INVOICE_QUANTITY)) + 1);
                existingInvoiceItem.put(INVOICE_NET_AMOUNT, ((Decimal) existingInvoiceItem.get(INVOICE_NET_AMOUNT)) + netAmount);
                existingInvoiceItem.put(
                    INVOICE_TAX_AMOUNT,
                    ((Decimal) existingInvoiceItem.get(INVOICE_TAX_AMOUNT)) + (Decimal) invoiceItemMap.get(INVOICE_TAX_AMOUNT)
                );
            } else if (isExempt) {
                //If no previous product that was exempt payment (courtesy) was processed then add to item list
                processedPurchaseDiscountInvoiceItemsMap.put(productId, invoiceItemMap);
                invoiceItemList.add(invoiceItemMap);
                //Add Courtesia to Line's Item Reference
                invoiceItemMap.put(INVOICE_ITEM_REFERENCE, COURTESY_REFERENCE);
            } else {
                //If no previous product (not exempt payment) was processed then add to item list
                processedInvoiceItemsMap.put(productId, invoiceItemMap);
                invoiceItemList.add(invoiceItemMap);
            }

            //If Invoice is exempt from payment then verify discount lines
            if (isExempt) {
                //Call method to update discount invoice line items
                verifyInvoiceExemption(processedDiscountInvoiceItemsMap, invoiceItemList, invoiceItemMap);
            }
        }
    }

    /**
     * @description Verify if product discount was previously processed. If yes, then increment quantity and amount.
     * If not then add new invoice line with discount.
     *
     * @param processedDiscountInvoiceItemsMap Map with all the invoice line items related to discounts
     * @param invoiceItemList List with all the invoices (with and without discount)
     * @param productId Id used to identify the Product on the invoice
     */
    private void verifyInvoiceExemption(
        Map<String, Map<String, Object>> processedDiscountInvoiceItemsMap,
        List<Map<String, Object>> invoiceItemList,
        Map<String, Object> invoiceItemMap
    ) {
        String productId = (String) invoiceItemMap.get(INVOICE_PRODUCT_ID);
        //Verify if a previous exempt Product with the same Code was processed. If it was increment quantity, net amount and tax amount on existing.
        if (processedDiscountInvoiceItemsMap.containsKey(productId)) {
            Map<String, Object> discountInvoiceItem = (Map<String, Object>) processedDiscountInvoiceItemsMap.get(productId);
            discountInvoiceItem.put(INVOICE_QUANTITY, ((Decimal) discountInvoiceItem.get(INVOICE_QUANTITY)) + 1);
            discountInvoiceItem.put(
                INVOICE_NET_AMOUNT,
                ((Decimal) discountInvoiceItem.get(INVOICE_NET_AMOUNT)) - ((Decimal) invoiceItemMap.get(INVOICE_NET_AMOUNT))
            );
            discountInvoiceItem.put(
                INVOICE_TAX_AMOUNT,
                ((Decimal) discountInvoiceItem.get(INVOICE_TAX_AMOUNT)) - ((Decimal) invoiceItemMap.get(INVOICE_TAX_AMOUNT))
            );
        } else {
            //If no previous Product was processed add new item to invoice with price as negative
            Map<String, Object> discountInvoiceItem = new Map<String, Object>(invoiceItemMap);
            discountInvoiceItem.put(INVOICE_NET_AMOUNT, -(Decimal) discountInvoiceItem.get(INVOICE_NET_AMOUNT));
            discountInvoiceItem.put(INVOICE_TAX_AMOUNT, -(Decimal) discountInvoiceItem.get(INVOICE_TAX_AMOUNT));
            processedDiscountInvoiceItemsMap.put(productId, discountInvoiceItem);
            invoiceItemList.add(discountInvoiceItem);
        }
    }

    /**
     * @description Verify invoice item and add missing required fields (ex: quantity)
     * and/or abbreviate fields that pass limits (ex: description)
     *
     * @param invoiceItemMap Map with the details of the invoice item
     */
    private static void verifyInvoiceItem(Map<String, Object> invoiceItemMap) {
        //If Quantity wasn't included set it to 1
        if (!invoiceItemMap.containsKey(INVOICE_QUANTITY)) {
            invoiceItemMap.put(INVOICE_QUANTITY, 1.0);
        }

        //Verify description lenght. Abbreviate to ensure it doesn't pass char limit
        if (invoiceItemMap.containsKey(INVOICE_DESCRIPTION)) {
            String descriptionText = (String) invoiceItemMap.get(INVOICE_DESCRIPTION);
            invoiceItemMap.put(INVOICE_DESCRIPTION, descriptionText.abbreviate(DESCRIPTION_CHAR_LIMIT));
        }
    }

    /**
     * @description Method to build the request body to create a financial document in SAP
     *
     * @param invoiceItemList Map with the data for the Invoice Items
     * @param accRecord Client's Account Record
     * @param documentId Id to serve as an identifier for the document generated
     * @param clientEmail The Client's Email to receive notification from SAP
     * @param paymentDays Number of Days for Client to pay Invoice
     * @param saleDate Date when Sale was made (ex: Last Day of Month)
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Map<String, Object> buildCreateDocRequestMap(
        List<Map<String, Object>> invoiceItemList,
        Account accRecord,
        String documentId,
        String clientEmail,
        Integer paymentDays,
        Date saleDate
    ) {
        //Generate Map with Account Data (based on Metadata)
        Map<String, Object> requestMap = sapMappingDo.mapJsonFromSObject(accRecord, new Map<String, Object>(), false);

        //Verify Billing Name lenght. If it passes then split Name into Billing Name and Additional Billing Name fields.
        if (requestMap.containsKey(BILLING_NAME)) {
            String billingName = (String) requestMap.get(BILLING_NAME);
            if (billingName.length() > BILLING_NAME_LIMIT) {
                //Verify if Remaining Chars don't pass Limit. If they do then truncate Additional Name.
                Integer endIndex = billingName.length() - BILLING_NAME_LIMIT <= BILLING_ADDITIONAL_NAME_LIMIT
                    ? billingName.length()
                    : BILLING_NAME_LIMIT + BILLING_ADDITIONAL_NAME_LIMIT;
                requestMap.put(BILLING_NAME, billingName.left(BILLING_NAME_LIMIT));
                requestMap.put(BILLING_ADDITIONAL_NAME, billingName.substring(BILLING_NAME_LIMIT, endIndex));
            }
        }

        //Verify Billing Address lenght. Abbreviate to ensure it doesn't pass char limit
        if (requestMap.containsKey(BILLING_ADDRESS)) {
            String billingAddress = (String) requestMap.get(BILLING_ADDRESS);
            requestMap.put(BILLING_ADDRESS, billingAddress.abbreviate(BILLING_ADDRESS_LIMIT));
        }
        //Set Account Email for Billing
        requestMap.put(BILLING_EMAIL, clientEmail);
        //Set Document Details
        requestMap.put(PAYMENT_MODE, PAYMENT_MODE_CREDIT);
        requestMap.put(DOCUMENT_ID, documentId.right(ID_CHAR_LIMIT));
        requestMap.put(DOCUMENT_TYPE, DOCUMENT_TYPE_INVOICE);
        requestMap.put(DOCUMENT_SERIE, DOCUMENT_GENERATION_NOT_KIOSK);
        //Set Dates
        requestMap.put(DOCUMENT_DATE, String.valueOf(saleDate));
        requestMap.put(BILLING_DATE, String.valueOf(Date.today()));
        requestMap.put(PAYMENT_DAYS, paymentDays);
        requestMap.put(DUE_DATE, String.valueOf(Date.today().addDays(paymentDays)));

        //Sum net amount and tax amount from invoice items.
        Decimal finalAmount = 0.0;
        Decimal taxAmount = 0.0;
        for (Map<String, Object> invoiceItem : invoiceItemList) {
            //Set Amount Scale to 2 decimal places to ensure it follows SAP limit.
            Decimal lineNetAmount = ((Decimal) invoiceItem.get(INVOICE_NET_AMOUNT)).setScale(2);
            Decimal lineTaxAmount = ((Decimal) invoiceItem.get(INVOICE_TAX_AMOUNT)).setScale(2);
            invoiceItem.put(INVOICE_NET_AMOUNT, lineNetAmount);
            invoiceItem.put(INVOICE_ITEM_TAX_AMOUNT, lineTaxAmount);
            finalAmount += lineNetAmount;
            taxAmount += lineTaxAmount;
        }
        //Set Invoice Items and Amounts
        requestMap.put(DOCUMENT_ORDER_ITEMS, invoiceItemList);
        requestMap.put(DOCUMENT_NET_AMOUNT, finalAmount);
        requestMap.put(INVOICE_TAX_AMOUNT, taxAmount);
        requestMap.put(VAT_DIFFERENCE_AMOUNT, VAT_DIFFERENCE_DEFAULT_VALUE);
        return requestMap;
    }
}