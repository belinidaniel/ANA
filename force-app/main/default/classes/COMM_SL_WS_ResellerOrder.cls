/**
 * @author Diogo Gonçalves
 * @description Class to support the Web Service to create reseller orders.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  05/05/2024       Original version
 **/
public inherited sharing class COMM_SL_WS_ResellerOrder {
    public static final COMM_IREP_Product2 PRODUCT_REPO = new COMM_REP_Product2();
    public static final COMM_IREP_Account ACCOUNT_REPO = new COMM_REP_Account();
    public static final COMM_IREP_ProductVariations PROD_VARIATION_REPO = new COMM_REP_ProductVariations();
    public static final COMM_IREP_PaymentGateway PAYMENT_GATEWAY_REPO = new COMM_REP_PaymentGateway();
    public static final COMM_IREP_SalesChannel SALESCHANNEL_REPO = new COMM_REP_SalesChannel();
    public static final COMM_IREP_ResellerAssortment RESELLERASSORTMENT_REPO = new COMM_REP_ResellerAssortment();
    public static final COMM_IREP_TaxValueConfigurationMdt TAXVALUECONFIGURATIONMDT_REPO = new COMM_REP_TaxValueConfigurationMdt();
    public static final FW_ISObjectRep SOBJECT_REPO = new FW_SObjectRep();
    public static final String RESELLER_SALESCHANNEL = 'reseller';
    public static final String PRODUCT_ID_FIELDNAME = 'productId';
    public static final String PRODUCTS_FIELDNAME = 'product';
    public static final String START_DATE_FIELDNAME = 'startDate';
    public static final String END_DATE_FIELDNAME = 'endDate';
    public static final String PRICE_FIELDNAME = 'price';
    public static final String PRICEBOOK_ENTRY_ID_FIELDNAME = 'pricebookEntryId';
    public static final String ERROR_FIELDNAME = 'error';
    public static final String CREDIT_PAYMENT_EXTERNAL_REF = 'COMM_CREDIT';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static Map<String, List<String>> productsByBundleCode = new Map<String, List<String>>();

    /**
     * @description Create reseller order
     * @param orderInput Reseller order input object with the data to create the order
     * @return Reseller order output with the Id of the order created
     *
     */
    public static COMM_WS_ResellerOrderOutput createResellerOrder(COMM_WS_ResellerOrderInput orderInput) {
        COMM_WS_ResellerOrderOutput output;
        Map<Id, Product2> productByIdMap = new Map<Id, Product2>();

        List<String> inputErrors = orderInput.getErrors();
        if (!inputErrors.isEmpty()) {
            throw new COMM_SL_ResellerOrderException(inputErrors[0], COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(inputErrors[0]));
        }
        Account reseller = getResellerAccount(orderInput.resellerId);
        Map<String, Product2> products = getProductsByProductCodes(orderInput.getProductIds());
        if (!isEveryBundleCorrect(orderInput)) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.BAD_BUNDLE,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.BAD_BUNDLE)
            );
        }

        COMM_WS_ReservationInput tempReservationInput = temporaryReserveStock(orderInput, reseller.Id);

        try {
            Double sumTotalAmount = 0;
            PaymentGateway paymentGateway = PAYMENT_GATEWAY_REPO.getByExternalReference(CREDIT_PAYMENT_EXTERNAL_REF);
            List<COMM_ResellerAssortment__c> resellerAssortmentList = RESELLERASSORTMENT_REPO.getForStockReserve(products.keySet(), reseller.Id);
            Map<String,List<PricingWrapper>> pricingWrapperListByProductCodeMap = createPricingWrapperMap(orderInput, resellerAssortmentList, products);
            Order order = createOrder(orderInput, reseller.Id, resellerAssortmentList[0]?.COMM_PriceBook__c);
            OrderDeliveryGroup orderDeliveryGroup = createOrderDeliveryGroup(order.Id, reseller);
            List<OrderItem> orderLines = createOrderItems(orderInput, products, order.Id, productByIdMap, orderDeliveryGroup.Id, pricingWrapperListByProductCodeMap);
            List<OrderItemTaxLineItem> orderTaxLines = createOrderTaxLines(orderLines, productByIdMap, pricingWrapperListByProductCodeMap);
            CardPaymentMethod creditPaymentMethod = createCreditPaymentMethod(reseller, paymentGateway);
            PaymentGroup paymentGroup = createPaymentGroup(order.Id);
            for(String productCode : pricingWrapperListByProductCodeMap.keySet()){
                for(PricingWrapper pricingWrapperRecord : pricingWrapperListByProductCodeMap.get(productCode)){
                    sumTotalAmount += pricingWrapperRecord.grossPrice;
                }
            }
            Payment payment = createPayment(reseller.Id, creditPaymentMethod.Id, paymentGroup.Id, (Test.isRunningTest() ? null : paymentGateway.Id), sumTotalAmount);

            order.Status = 'Activated';
            SOBJECT_REPO.updateSObjects(new List<Order>{ order });
            output = new COMM_WS_ResellerOrderOutput(order.Id);
            // send future method to permanentely reserve stock
            String jsonReservationInputString = JSON.serialize(tempReservationInput);
            String jsonOrderInputString = JSON.serialize(orderInput);
            reserveStock(jsonreservationInputString, jsonOrderInputString, reseller.Id);
        } catch (Exception e) {
            throw e;
        }

        return output;
    }

    /**
     * @description Create Card Payment Method object for Credit Payment
     * @param reseller account record
     * @return CardPaymentMethod created
     */
    private static CardPaymentMethod createCreditPaymentMethod(Account reseller, PaymentGateway paymentGateway) {
        if (paymentGateway == null && !Test.isRunningTest()) {
            throw new COMM_SL_ResellerOrderException(COMM_CommerceAPI_Constants.PAYMENT_GATEWAY_NOT_FOUND);
        }
        CardPaymentMethod creditPaymentMethod = new CardPaymentMethod(
            CardHolderName = reseller.Name,
            PaymentGatewayId = paymentGateway?.Id,
            AccountId = reseller.Id,
            ProcessingMode = 'External',
            Status = 'Active'
        );
        SOBJECT_REPO.insertSObjects(new List<CardPaymentMethod>{ creditPaymentMethod });
        return creditPaymentMethod;
    }

    /**
     * @description Create map to be used as the parameter for COMM_SL_WS_Pricing.calculatePricingResponse
     * @param orderInput Reseller order input object with the data to create the order
     * @return Map with the parameters to be used as input to the pricing service
     */
    private static Map<String, Object> getPricingServiceInput(COMM_WS_ResellerOrderInput orderInput) {
        List<Map<String, Object>> productsMap = new List<Map<String, Object>>();
        Set<String> bundleProductCodeSet = new Set<String>();

        for (COMM_WS_ResellerOrderInput.OrderItem orderItem : orderInput.orderItems) {
            if(String.isNotBlank(orderItem.bundleProductId) && !bundleProductCodeSet.contains(orderItem.bundleProductId)){
                productsMap.add(
                    new Map<String, Object>{
                        PRODUCT_ID_FIELDNAME => orderItem.bundleProductId,
                        START_DATE_FIELDNAME => String.valueOf(orderItem.startDate),
                        END_DATE_FIELDNAME => String.valueOf(orderItem.startDate)
                    }
                );
                bundleProductCodeSet.add(orderItem.bundleProductId);
            }
            productsMap.add(
                new Map<String, Object>{
                    PRODUCT_ID_FIELDNAME => orderItem.productId,
                    START_DATE_FIELDNAME => String.valueOf(orderItem.startDate),
                    END_DATE_FIELDNAME => String.valueOf(orderItem.endDate)
                }
            );
        }
        return new Map<String, Object>{ PRODUCTS_FIELDNAME => productsMap };
    }

    /**
     * @description Create Order Tax Lines
     * @param orderLines Order Line List
     * @param productByIdMap Product by product code map
     * @param pricingWrapperListByProductCodeMap Map of pricing wrapper List by product code
     * @return List<OrderTaxLine>
     */
    public static List<OrderItemTaxLineItem> createOrderTaxLines(List<OrderItem> orderLines, Map<Id, Product2> productByIdMap, Map<String,List<PricingWrapper>> pricingWrapperListByProductCodeMap) {
        List<OrderItemTaxLineItem> taxes = new List<OrderItemTaxLineItem>();

        for (OrderItem orderItem : orderLines) {
            List<PricingWrapper> pricingWrapperList = new List<PricingWrapper>();
            PricingWrapper pricingWrapperRecord;
            if(String.isBlank(orderItem.COMM_BundleProductId__c)){
                pricingWrapperList = pricingWrapperListByProductCodeMap.get(productByIdMap.get(orderItem.Product2Id).ProductCode);
                pricingWrapperRecord = pricingWrapperList.get(0);
            } else {
                pricingWrapperList = pricingWrapperListByProductCodeMap.get(productByIdMap.get(orderItem.COMM_BundleProductId__c).ProductCode);
                for(PricingWrapper pricingWrapperRecordOnLoop : pricingWrapperList) {
                    if(pricingWrapperRecordOnLoop.bundleLineId == orderItem.COMM_BundleLineId__c){
                        pricingWrapperRecord = pricingWrapperRecordOnLoop;
                        break;
                    }
                }
            }
            taxes.add(
                new OrderItemTaxLineItem(
                    Name = productByIdMap.get(orderItem.Product2Id).ProductCode + ' - Tax',
                    Type = 'Estimated',
                    Amount = pricingWrapperRecord.vat,
                    Rate = pricingWrapperRecord.taxRate,
                    TaxEffectiveDate = Date.today(),
                    OrderItemId = orderItem.Id
                )
            );
        }

        if (!taxes.isEmpty()) {
            SOBJECT_REPO.insertSObjects(taxes);
        }
        return taxes;
    }

    public class PricingServiceOutput {
        public Map<String, Object> products;

        public PricingServiceOutput() {
            this.products = new Map<String, Object>();
        }

        public void addProductPricing(Map<String, Object> productPricing) {
            String productId = (String) productPricing.get(PRODUCT_ID_FIELDNAME);
            products.put(productId, productPricing);
        }

        public Decimal getProductPrice(String productCode) {
            Map<String, Object> product = (Map<String, Object>) this.products.get(productCode);
            return (Decimal) product.get(PRICE_FIELDNAME);
        }

        public String getProductPricebookEntryId(String productCode) {
            Map<String, Object> product = (Map<String, Object>) this.products.get(productCode);
            return (String) product.get(PRICEBOOK_ENTRY_ID_FIELDNAME);
        }
    }

    /**
     * @description Gets the price for the speficif product
     * @param orderInput order input received
     * @param resellerAssortmentList List of reseller assortments
     * @return PricingServiceOutput
     */
    private static PricingServiceOutput getProductsPricing(COMM_WS_ResellerOrderInput orderInput, List<COMM_ResellerAssortment__c> resellerAssortmentList) {
        COMM_SL_WS_Pricing pricingService = new COMM_SL_WS_Pricing();
        Map<String, Object> pricingServiceInput = getPricingServiceInput(orderInput);
        Map<String, Object> pricingData = pricingService.calculatePricingResellerResponse(pricingServiceInput, resellerAssortmentList);
        List<Object> pricingErrors = (List<Object>) pricingData.get(ERROR_FIELDNAME);
        List<Object> pricingProducts = (List<Object>) pricingData.get(PRODUCTS_FIELDNAME);
        if (!pricingErrors.isEmpty()) {
            throw new COMM_SL_ResellerOrderException(COMM_CommerceAPI_Constants.PRICING_NOT_FOUND);
        }

        PricingServiceOutput pricingOutput = new PricingServiceOutput();
        for (Object productPricing : pricingProducts) {
            Map<String, Object> productPricingMap = (Map<String, Object>) productPricing;
            pricingOutput.addProductPricing(productPricingMap);
        }

        return pricingOutput;
    }

    /**
     * @description Get pricing for all products on Input request
     * @param orderInput Reseller order input object with the data to create the order
     * @param resellerAssortmentList Reseller Assortment List
     * @param productByProductCodeMap Products mapped by productCode
     * @return Map of pricing wrapper List by product code
     */
    private static Map<String, List<PricingWrapper>> createPricingWrapperMap(COMM_WS_ResellerOrderInput orderInput, List<COMM_ResellerAssortment__c> resellerAssortmentList, Map<String, Product2> productByProductCodeMap) {
        Map<String, List<PricingWrapper>> outputPricingWrapperMap = new Map<String, List<PricingWrapper>>();
        PricingServiceOutput pricingOutput = getProductsPricing(orderInput, resellerAssortmentList);
        Map<String, List<String>> productsByBundleIdMap = orderInput.getProductsByBundleId();

        for (Integer i = 0; i < orderInput.orderItems.size(); i++) {
            PricingWrapper pricingWrapper = new PricingWrapper();
            COMM_WS_ResellerOrderInput.OrderItem orderItem = orderInput.orderItems[i];
            Decimal grossPrice = 0;
            if (String.isBlank(orderItem.bundleProductId)) {
                grossPrice = pricingOutput.getProductPrice(orderItem.productId);
            } else {
                pricingWrapper.bundleLineId = orderItem.bundleLineId;
                List<String> bundledProductCodes = productsByBundleIdMap.get(orderItem.orderLineId + ':' + orderItem.bundleProductId);
                Decimal productRealPrice = pricingOutput.getProductPrice(orderItem.productId);
                Decimal productRealPriceOutOfBundle = 0;
                for(String productCode : bundledProductCodes) {
                    productRealPriceOutOfBundle += pricingOutput.getProductPrice(productCode);
                }
                Decimal realGrossPricePercentageWithoutRound = (productRealPrice * 100) / productRealPriceOutOfBundle;
                Decimal grossPriceWithoutRound = pricingOutput.getProductPrice(orderItem.bundleProductId) * (realGrossPricePercentageWithoutRound / 100);
                grossPrice = grossPriceWithoutRound.setScale(2, RoundingMode.HALF_UP);
            }
            Decimal taxPercentage = TAXVALUECONFIGURATIONMDT_REPO.getTaxValueConfig(productByProductCodeMap.get(orderItem.productId).COMM_Tax__c)/100;
            Decimal unitPrice = grossPrice / (1+taxPercentage);
            pricingWrapper.orderRef = orderItem.orderLineId;
            pricingWrapper.unitPrice = unitPrice.setScale(2, RoundingMode.HALF_UP);
            pricingWrapper.vat = grossPrice - unitPrice.setScale(2, RoundingMode.HALF_UP);
            pricingWrapper.grossPrice = grossPrice;
            pricingWrapper.taxRate = taxPercentage * 100;
            pricingWrapper.pricebookEntryId = pricingOutput.getProductPricebookEntryId(orderItem.productId);
            if (String.isBlank(orderItem.bundleProductId)) {
                if(outputPricingWrapperMap.containsKey(orderItem.productId)){
                    outputPricingWrapperMap.get(orderItem.productId).add(pricingWrapper);
                } else {
                    outputPricingWrapperMap.put(orderItem.productId, new List<PricingWrapper>{pricingWrapper});
                }
            } else {
                if(outputPricingWrapperMap.containsKey(orderItem.bundleProductId)){
                    outputPricingWrapperMap.get(orderItem.bundleProductId).add(pricingWrapper);
                } else {
                    outputPricingWrapperMap.put(orderItem.bundleProductId, new List<PricingWrapper>{pricingWrapper});
                }
            }
        }
        return outputPricingWrapperMap;
    }

    /**
     * @description Create the order lines for the given order
     * @param orderInput Reseller order input object with the data to create the order
     * @param products Products mapped by productCode
     * @param orderId Order Id
     * @param productByIdMap Product by Id Map
     * @param orderDeliveryGroupId Order Delivery Group Id
     * @param pricingWrapperListByProductCodeMap Map of pricing wrapper List by product code
     * @return List<OrderItem> Order Item created
     */
    private static List<OrderItem> createOrderItems(COMM_WS_ResellerOrderInput orderInput, Map<String, Product2> products, Id orderId, Map<Id, Product2> productByIdMap, Id orderDeliveryGroupId, Map<String,List<PricingWrapper>> pricingWrapperListByProductCodeMap) {
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < orderInput.orderItems.size(); i++) {
            COMM_WS_ResellerOrderInput.OrderItem orderItem = orderInput.orderItems[i];
            PricingWrapper pricingWrapperRecord;
            if (String.isBlank(orderItem.bundleProductId)) {
                pricingWrapperRecord = pricingWrapperListByProductCodeMap.get(orderItem.productId)[0];
            } else {
                for(PricingWrapper pricingWrapperRecordOnLoop : pricingWrapperListByProductCodeMap.get(orderItem.bundleProductId)) {
                    if(pricingWrapperRecordOnLoop.bundleLineId == orderItem.bundleLineId){
                        pricingWrapperRecord = pricingWrapperRecordOnLoop;
                        break;
                    }
                }
                productByIdMap.put(products.get(orderItem.bundleProductId).Id, products.get(orderItem.bundleProductId));
            }
            orderItems.add(
                new OrderItem(
                    Description = products.get(orderItem.productId).Name,
                    Type = 'Order Product',
                    Quantity = 1,
                    LineNumber = i + 1,
                    UnitPrice = pricingWrapperRecord.unitPrice,
                    OrderId = orderId,
                    Product2Id = products.get(orderItem.productId).Id,
                    COMM_ReservationName__c = orderItem.passengerName,
                    COMM_ReservationStart__c = orderItem.startDate,
                    COMM_ReservationEnd__c = orderItem.endDate,
                    PricebookEntryId = pricingWrapperRecord.pricebookEntryId,
                    COMM_BundleLineId__c = orderItem.bundleLineId,
                    COMM_BundleProductId__c = products.get(orderItem.bundleProductId)?.Id,
                    COMM_OrderItemReferenceNumber__c = orderItem.orderLineId,
                    OrderDeliveryGroupId = orderDeliveryGroupId,
                    TotalLineAmount = pricingWrapperRecord.unitPrice,
                    GrossUnitPrice = pricingWrapperRecord.grossPrice
                )
            );
            productByIdMap.put(products.get(orderItem.productId).Id, products.get(orderItem.productId));
        }

        if (!orderItems.isEmpty()) {
            SOBJECT_REPO.insertSObjects(orderItems);
        }
        return orderItems;
    }

    /**
     * @description Get unit price for bundled product
     * @param bundledProducts
     * @param productId
     * @param pricingOutput
     */
    private static Decimal getBundleProductUnitPrice(List<String> bundledProducts, String bundleProductId, PricingServiceOutput pricingOutput) {
        Integer totalBundleProducts = bundledProducts.size();
        Decimal bundlePrice = pricingOutput.getProductPrice(bundleProductId);
        return (Decimal) (bundlePrice / totalBundleProducts);
    }

    /**
     * @description Create and insert Order
     * @param orderInput Reseller order input object with the data to create the order
     * @return Order SObject
     */
    private static Order createOrder(COMM_WS_ResellerOrderInput orderInput, Id resellerAccountId, Id pricebookId) {
        Order order = new Order(
            Name = orderInput.orderId,
            AccountId = resellerAccountId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OrderReferenceNumber = orderInput.orderId,
            OrderedDate = Date.today(),
            SalesChannelId = getResellerSalesChannelId(),
            Pricebook2Id = pricebookId,
            COMM_Language__c = DEFAULT_LANGUAGE
        );
        SOBJECT_REPO.insertSObjects(new List<Order>{ order });
        return order;
    }

    /**
     * @description Create and insert OrderDeliveryGroup
     * @param orderId order Id
     * @param reseller reseller account
     * @return OrderDeliveryGroup new record
     */
    private static OrderDeliveryGroup createOrderDeliveryGroup(Id orderId, Account reseller) {
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            OrderId = orderId,
            OrderDeliveryMethodId = getOrderDeliveryMethod().Id,
            DeliverToName = reseller.Name,
            EmailAddress = reseller.COMM_Email__c
        );
        SOBJECT_REPO.insertSObjects(new List<OrderDeliveryGroup>{ orderDeliveryGroup });
        return orderDeliveryGroup;
    }

    /**
     * @description Creates payment group
     * @param sourceObjectId Order
     * @return PaymentGroup record
     */
    public static PaymentGroup createPaymentGroup(String sourceObjectId) {
        PaymentGroup paymentGroup = new PaymentGroup();
        paymentGroup.SourceObjectId = sourceObjectId;
        SOBJECT_REPO.insertSObjects(new List<PaymentGroup>{ paymentGroup });
        return paymentGroup;
    }

    /**
     * @description Creates payment
     * @param resellerId account Id
     * @param creditPaymentMethodId credit payment method Id
     * @param paymentGatewayId payment gateway Id
     * @param sumTotalAmount Total amount to include on Payment
     * @return Payment record
     */
    public static Payment createPayment(Id resellerId, Id creditPaymentMethodId, Id paymentGroupId, Id paymentGatewayId, Decimal sumTotalAmount) {
        Payment payment = new Payment(
            Amount = sumTotalAmount,
            ProcessingMode = 'External',
            Status = 'Processed',
            PaymentGroupId = paymentGroupId,
            AccountId = resellerId,
            PaymentMethodId = creditPaymentMethodId,
            PaymentGatewayId = paymentGatewayId,
            Type = 'Capture'
        );
        SOBJECT_REPO.insertSObjects(new List<Payment>{ payment });
        return payment;
    }

    /**
     * @description Get Reseller Sales Channel
     * @return Sales Channel Id
     */
    private static Id getResellerSalesChannelId() {
        List<SalesChannel> salesChannels = SALESCHANNEL_REPO.getByName(new List<String>{ RESELLER_SALESCHANNEL });
        if (salesChannels.isEmpty()) {
            throw new COMM_SL_ResellerOrderException(COMM_CommerceAPI_Constants.RESELLER_SALESCHANNEL_NOT_FOUND);
        } else {
            return salesChannels[0].Id;
        }
    }

    /**
     * @description Secures the stock for the products of the order.
     * @param orderInput Reseller order input object with the data to create the order
     * @param resellerAccountId reseller account id
     * @return reservationInput reservation input request already sent to OCI
     */
    private static COMM_WS_ReservationInput temporaryReserveStock(COMM_WS_ResellerOrderInput orderInput, Id resellerAccountId) {
        COMM_WS_ReservationInput reservationInput = getOCIReservationInput(orderInput);
        COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();

        ociReservation.reserve(reservationInput, false);
        COMM_SL_ResellerReservation.reserve(orderInput.getProductQuantities(), resellerAccountId);
        return reservationInput;
    }

    /**
     * @description Secures the stock for the products of the order.
     * @param reservationInput reservation input request already sent to OCI
     * @param orderInput Reseller order input object with the data to create the order
     * @param resellerAccountId reseller account id
     */
    @future
    private static void reserveStock(String jsonreservationInputString, String jsonOrderInputString, Id resellerAccountId) {
        COMM_WS_ReservationInput reservationInput = (COMM_WS_ReservationInput) JSON.deserialize(jsonreservationInputString, COMM_WS_ReservationInput.class);
        COMM_WS_ResellerOrderInput orderInput = (COMM_WS_ResellerOrderInput) JSON.deserialize(jsonOrderInputString, COMM_WS_ResellerOrderInput.class);
        reservationInput.expirationSeconds = 0;
        COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();

        ociReservation.release(reservationInput);
        COMM_SL_ResellerReservation.release(orderInput.getProductQuantities(), resellerAccountId);
    }

    /**
     * @description Get a COMM_SL_WS_OCIReservation for each order item in the parameter list
     * @param orderInputs List of reseller order inputs to get OCI reservation input
     */
    private static COMM_WS_ReservationInput getOCIReservationInput(COMM_WS_ResellerOrderInput orderInput) {
        COMM_WS_ReservationInput reservationInput = new COMM_WS_ReservationInput();
        Integer i = 0;
        reservationInput.reservationId = orderInput.orderId;
        reservationInput.extend = false;
        reservationInput.expirationSeconds = 120;
        for (COMM_WS_ResellerOrderInput.OrderItem orderItem : orderInput.orderItems) {
            String actionRequestId = orderInput.orderId + '' + i;
            reservationInput.addProduct(orderItem.productId, orderItem.startDate, orderItem.endDate, actionRequestId);
            i++;
        }
        return reservationInput;
    }

    /**
     * @description Get active Products by ProductCode
     * @param productIds List of Product Code
     * @return Map of Product by Product Code
     */
    public static Map<String, Product2> getProductsByProductCodes(List<String> productIds) {
        Map<String, Product2> products = PRODUCT_REPO.getProductsByProductCodes(productIds);
        if (products.isEmpty() || products.size() != productIds.size()) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.PRODUCT_NOT_FOUND,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.PRODUCT_NOT_FOUND)
            );
        }
        return products;
    }

    /**
     * @description Get default OrderDeliveryMethod.
     * @return OrderDeliveryMethod record
     */
    private static OrderDeliveryMethod getOrderDeliveryMethod() {
        return [SELECT Id FROM OrderDeliveryMethod WHERE Name = 'default' LIMIT 1];
    }

    /**
     * @description Get reseller account from given reseller id.
     * @param {string} id - Reseller Id
     * @return {Account} Reseller Account
     */
    private static Account getResellerAccount(String resellerId) {
        List<Account> resellers = ACCOUNT_REPO.getResellers(new List<String>{ resellerId });
        if (resellers.isEmpty()) {
            throw new COMM_SL_ResellerOrderException(
                COMM_CommerceAPI_Constants.RESELLER_NOT_FOUND,
                COMM_CommerceAPI_Constants.ERROR_MESSAGE_MAP.get(COMM_CommerceAPI_Constants.RESELLER_NOT_FOUND)
            );
        } else {
            return resellers[0];
        }
    }

    /**
     * @description Checks if the given bundle ids have the correct product ids.
     * @param orderInput Reseller order input object with the data to create the order
     * @return Boolean to identify if the records are correct or not
     */
    private static Boolean isEveryBundleCorrect(COMM_WS_ResellerOrderInput orderInput) {
        Boolean isEveryBundleCorrect = true;
        Map<String, List<String>> orderBundles = orderInput.getProductsByBundleId();
        List<COMM_ProductVariations__c> productVariations = PROD_VARIATION_REPO.getProductVariationsByMasterProduct(orderInput.getBundleIds());
        productsByBundleCode = getProductVariationsByBundleCode(productVariations);

        for (String orderBundleId : orderBundles.keySet()) {
            String bundleId = orderBundleId.split(':')[1];
            List<String> orderBundleProducts = orderBundles.get(orderBundleId);
            List<String> bundleProducts = productsByBundleCode.get(bundleId);
            if (bundleProducts == null) {
                isEveryBundleCorrect = false;
                break;
            }

            orderBundleProducts.sort();
            bundleProducts.sort();
            if (!orderBundleProducts.equals(bundleProducts)) {
                isEveryBundleCorrect = false;
                break;
            }
        }
        return isEveryBundleCorrect;
    }

    /**
     * @description Creates a map with the product code for every bundle
     * @param productVariations List<COMM_ProductVariations__c>
     * @return Map<String, List<String>>
     */
    private static Map<String, List<String>> getProductVariationsByBundleCode(List<COMM_ProductVariations__c> productVariations) {
        Map<String, List<String>> productVariationsByBundleCode = new Map<String, List<String>>();
        for (COMM_ProductVariations__c variation : productVariations) {
            String bundleCode = variation.COMM_MasterProduct__r.ProductCode;
            String productCode = variation.COMM_RelatedProduct__r.ProductCode;
            if (productVariationsByBundleCode.containsKey(bundleCode)) {
                productVariationsByBundleCode.get(bundleCode).add(productCode);
            } else {
                productVariationsByBundleCode.put(bundleCode, new List<String>{ productCode });
            }
        }
        return productVariationsByBundleCode;
    }

    /**
     * @description Wrapper to represent data structure to identify the correct unit price and vat for each Order Item.
     */
    public class PricingWrapper {
        private String bundleLineId;
		private String orderRef;
		private Decimal unitPrice;
		private Decimal vat;
		private Decimal grossPrice;
		private Decimal taxRate;
		private String pricebookEntryId;
    }
}