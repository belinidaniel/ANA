/**
 * @author Rui Salgado
 * @description Test data factory class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      08/04/2024       Original version
 **/
@isTest
@suppressWarnings('PMD.ExcessivePublicCount, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.CognitiveComplexity')
public class COMM_OMS_TestDataFactory {
    private static final string DEFAULT_NAME = 'Test';
    private static final string RESELLER_SALESCHANNEL_NAME = 'reseller';
    private static final string DEFAULT_RESELLER_ID = 'resellerId';
    private static final string DEFAULT_PRODUCT_FAMILY = 'Parking';
    private static final string DEFAULT_ORDER_LANGUAGE = 'pt_PT';
    private static final string DEFAULT_BILLING_NAME = 'Billing Name';
    private static final string DEFAULT_BILLING_VAT = '999999999';
    private static final string DEFAULT_BILLING_EMAIL = 'test@test.com';
    private static final string PRODUCT_FAMILY_FAST_TRACK = 'Fast Track';
    private static final string PRODUCT_FAMILY_GIFT_CARD = 'Gift Card';
    private static final string PRODUCT_FAMILY_SUBSCRIPTION = 'Subscription';

    // custom fields
    private static final string DEFAULT_PRODUCT_COMM_CPMS = 'SKIDATA';
    private static final string DEFAULT_PRODUCT_COMM_AIRPORT = 'LIS';
    private static final string DEFAULT_PRODUCT_COMM_PARK = 'P0';
    private static final DateTime DEFAULT_PRODUCT_COMM_VALIDFROM = Datetime.now().addHours(1);
    private static final DateTime DEFAULT_PRODUCT_COMM_VALIDTO = Datetime.now().addYears(1);
    private static final string DEFAULT_ORDERITEMSUMMARY_COMM_RESERVATIONNAME = 'Reservation Name';

    /**
     * @description Creates Contact object
     * @param input Contact input
     * @return Contact
     */
    public static Contact createContact(COMM_OMS_TestDataInput.ContactInput input) {
        Contact contact = new Contact();
        contact.LastName = input.lastName;
        return contact;
    }

    /**
     * @description Create reseller assortements
     * @param name Account name
     * @param resellerId
     */
    public static Account createResellerAccount(String name, String resellerId) {
        Account resellerAccount = new Account();
        resellerAccount.Name = name;
        resellerAccount.COMM_ResellerId__c = resellerId;
        resellerAccount.COMM_IsReseller__c = true;
        return resellerAccount;
    }

    /**
     * @description Create reseller assortment for reseller
     * @param prod
     * @param ressellerAccountId
     */
    public static COMM_ResellerAssortment__c createResellerAssortment(Id productId, Id resellerAccountId) {
        return new COMM_ResellerAssortment__c(
            COMM_Account__c = resellerAccountId,
            COMM_Product__c = productId,
            COMM_Pricebook__c = Test.getStandardPricebookId(),
            COMM_CurrentDailyQuantity__c = 0,
            COMM_DailyLimit__c = 10
        );
    }

    /**
     * @description Creates product
     * @param input Product input
     * @return Product2
     */
    public static Product2 createProduct(COMM_OMS_TestDataInput.ProductInput input) {
        Product2 product = new Product2();
        product.Name = input.name;
        product.COMM_Tax__c = 'Continent';
        product.ProductCode = input.productCode;
        product.Description = input.productCode;
        product.Family = DEFAULT_PRODUCT_FAMILY;
        product.COMM_ClosingOperatingHours__c = System.now().time();
        product.COMM_OpeningOperatingHours__c = System.now().time();
        product.COMM_CPMS__c = DEFAULT_PRODUCT_COMM_CPMS;
        product.COMM_Airport__c = DEFAULT_PRODUCT_COMM_AIRPORT;
        product.COMM_Park__c = DEFAULT_PRODUCT_COMM_PARK;
        product.COMM_ValidFrom__c = DEFAULT_PRODUCT_COMM_VALIDFROM;
        product.COMM_ValidTo__c = DEFAULT_PRODUCT_COMM_VALIDTO;
        return product;
    }

    /**
     * @description Creates product
     * @param productCode Product code
     * @return Product2
     */
    public static Product2 createProduct(String productCode) {
        Product2 product = new Product2();
        product.Name = DEFAULT_NAME;
        product.COMM_Tax__c = 'Continent';
        product.ProductCode = productCode;
        product.Description = productCode;
        product.COMM_ClosingOperatingHours__c = System.now().time();
        product.COMM_OpeningOperatingHours__c = System.now().time();
        product.Family = DEFAULT_PRODUCT_FAMILY;
        product.COMM_CPMS__c = DEFAULT_PRODUCT_COMM_CPMS;
        product.COMM_Airport__c = DEFAULT_PRODUCT_COMM_AIRPORT;
        product.COMM_Park__c = DEFAULT_PRODUCT_COMM_PARK;
        product.COMM_ValidFrom__c = DEFAULT_PRODUCT_COMM_VALIDFROM;
        product.COMM_ValidTo__c = DEFAULT_PRODUCT_COMM_VALIDTO;
        return product;
    }

    /**
     * @description Creates product
     * @param orderItem Order item object
     * @return Product2
     */
    public static Product2 createProduct(CreateOrderItem orderItem) {
        Product2 product = new Product2();
        product.Name = DEFAULT_NAME;
        product.COMM_Tax__c = 'Continent';
        product.ProductCode = orderItem.productCode;
        product.Description = orderItem.productCode;
        product.COMM_ClosingOperatingHours__c = System.now().time();
        product.COMM_OpeningOperatingHours__c = System.now().time();
        product.Family = orderItem.family;
        product.COMM_CPMS__c = DEFAULT_PRODUCT_COMM_CPMS;
        product.COMM_Airport__c = DEFAULT_PRODUCT_COMM_AIRPORT;
        product.COMM_Park__c = DEFAULT_PRODUCT_COMM_PARK;
        product.COMM_ValidFrom__c = DEFAULT_PRODUCT_COMM_VALIDFROM;
        product.COMM_ValidTo__c = DEFAULT_PRODUCT_COMM_VALIDTO;
        product.COMM_SubCategory__c = orderItem.subcategory;
        product.COMM_PaymentType__c = orderItem.paymentType;
        product.COMM_SAPLocation__c = orderItem.sapLocation;
        if (orderItem.recordTypeId != null) {
            product.RecordTypeId = orderItem.recordTypeId;
        }
        return product;
    }

    /**
     * @description Creates ConnectApi error
     * @return ConnectApi error
     */
    public static ConnectApi.OrderSummaryOutputRepresentation createConnectApiError() {
        ConnectApi.OrderSummaryOutputRepresentation output = new ConnectApi.OrderSummaryOutputRepresentation();
        output.success = false;
        ConnectApi.ErrorResponse error = new ConnectApi.ErrorResponse();
        error.errorCode = COMM_OMS_Constants.CONNECT_API_ERROR;
        error.message = COMM_OMS_Constants.UNKNOWN;
        output.errors = new List<ConnectApi.ErrorResponse>{ error };
        return output;
    }

    /**
     * @description Creates pricebook entry
     * @param unitPrice Unit price
     * @param productId Product Id (createProduct)
     * @return PricebookEntry
     */
    public static PricebookEntry createPricebookEntry(Decimal unitPrice, Id productId) {
        PricebookEntry priceBookEntry = new PriceBookEntry();
        priceBookEntry.IsActive = true;
        priceBookEntry.UnitPrice = unitPrice;
        priceBookEntry.Pricebook2Id = Test.getStandardPricebookId();
        priceBookEntry.Product2Id = productId;

        priceBookEntry.COMM_First15MinuteUnit__c = 1;
        priceBookEntry.COMM_Second15MinuteUnit__c = 1;
        priceBookEntry.COMM_Third15MinuteUnit__c = 1;
        priceBookEntry.COMM_Remaining15MinuteUnit__c = 1;
        priceBookEntry.COMM_FirstPeriodStartDay__c = 1;
        priceBookEntry.COMM_FirstPeriodEndDay__c = 366;
        priceBookEntry.COMM_FirstPeriodDailyMaximum__c = 1;
        return priceBookEntry;
    }

    /**
     * @description Creates account
     * @param firstName First name of the account
     * @param lastName Last name of the account
     * @param email Email address of the account
     * @return Account
     */
    public static Account createAccount(String firstName, String lastName, String email) {
        Account account = new Account();
        account.FirstName = firstName;
        account.LastName = lastName;
        account.PersonEmail = email;

        List<RecordType> personAccountRecordTypes = [
            SELECT Id
            FROM RecordType
            WHERE IsPersonType = TRUE AND IsActive = TRUE AND SobjectType = 'Account'
        ];
        if (!personAccountRecordTypes.isEmpty()) {
            account.RecordTypeId = personAccountRecordTypes[0].Id;
        }

        return account;
    }

    /**
     * @description Creates saleschannel
     * @param saleschannelName Saleschannel name
     * @return Saleschannel
     */
    public static Saleschannel createSaleschannel(string saleschannelName) {
        Saleschannel saleschannel = new Saleschannel();
        saleschannel.SaleschannelName = saleschannelName;
        return saleschannel;
    }

    /**
     * @description Creates order
     * @param accountId Account Id (createAccount)
     * @param saleschannelId Saleschannel Id (createSaleschannel)
     * @return Order
     */
    public static Order createOrder(Id accountId, Id saleschannelId) {
        Order order = new Order();
        order.AccountId = accountId;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        order.SalesChannelId = saleschannelId;
        order.COMM_Language__c = DEFAULT_ORDER_LANGUAGE;
        order.COMM_BillingName__c = DEFAULT_BILLING_NAME;
        order.BillingEmailAddress = DEFAULT_BILLING_EMAIL;
        order.COMM_BillingVATNumber__c = DEFAULT_BILLING_VAT;
        order.OrderedDate = DateTime.now().addDays(-10);
        Integer randomNumber = Math.round((Math.random() * (900000) + 100000));
        order.OrderReferenceNumber = DEFAULT_NAME + String.valueOf(randomNumber);
        return order;
    }

    /**
     * @description Creates order delivery method
     * @return OrderDeliveryMethod
     */
    public static OrderDeliveryMethod createOrderDeliveryMethod() {
        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod();
        orderDeliveryMethod.Name = DEFAULT_NAME;
        orderDeliveryMethod.ReferenceNumber = DEFAULT_NAME;
        return orderDeliveryMethod;
    }

    /**
     * @description Creates order
     * @param orderId Order Id (createOrder)
     * @param orderDeliveryMethodId Order delivery method Id (createOrderDeliveryMethod)
     * @return OrderDeliveryGroup
     */
    public static OrderDeliveryGroup createOrderDeliveryGroup(Id orderId, Id orderDeliveryMethodId) {
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup();
        orderDeliveryGroup.OrderId = orderId;
        orderDeliveryGroup.OrderDeliveryMethodId = orderDeliveryMethodId;
        orderDeliveryGroup.DeliverToName = DEFAULT_NAME;
        orderDeliveryGroup.DeliverToCountry = 'Portugal';
        orderDeliveryGroup.EmailAddress = 'test@anaaeroportos.pt';
        orderDeliveryGroup.DeliverToCity = DEFAULT_NAME;
        orderDeliveryGroup.DeliverToPostalCode = DEFAULT_NAME;
        orderDeliveryGroup.DeliverToStreet = DEFAULT_NAME;
        return orderDeliveryGroup;
    }

    /**
     * @description Creates order
     *   suppress reason: ignore
     * @param orderId Order Id (createOrder)
     * @param productId Product Id (createProduct)
     * @param priceBookEntryId Pricebook entry Id (createPricebookEntry)
     * @param unitPrice Unit price
     * @param quantity Quantity
     * @param orderDeliveryGroupId Order delivery group Id (createOrderDeliveryGroup)
     * @param orderProductType Order item type
     * @return OrderDeliveryGroup
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static OrderItem createOrderItem(
        Id orderId,
        Id productId,
        Id priceBookEntryId,
        Decimal unitPrice,
        Integer quantity,
        Id orderDeliveryGroupId,
        String orderProductType
    ) {
        OrderItem item = new OrderItem();
        item.OrderId = orderId;
        item.Product2Id = productId;
        item.PricebookentryId = priceBookEntryId;
        item.UnitPrice = unitPrice;
        item.Quantity = quantity;
        item.Type = orderProductType;
        item.OrderDeliveryGroupId = orderDeliveryGroupId;
        item.TotalLineAmount = unitPrice * quantity;
        item.ReservedAtLocationId = [SELECT Id FROM Location WHERE name = 'Default' LIMIT 1].Id;
        item.COMM_ReservationName__c = DEFAULT_ORDERITEMSUMMARY_COMM_RESERVATIONNAME;
        item.COMM_ReservationStart__c = Date.today();
        return item;
    }

    /**
     * @description Creates location
     * @param name Location name
     * @param locationType Location type (LocationType enum)
     * @return Location
     */
    public static Schema.Location createLocation(String name, String locationType) {
        Schema.Location location = new Schema.Location();
        location.Name = name;
        location.ExternalReference = name;
        location.LocationType = locationType;
        return location;
    }

    /**
     * @description Creates order item tax
     *   suppress reason: ignore
     * @param name Name
     * @param orderItemId Order item Id (createOrderItem)
     * @param type Tax type
     * @param amount Tax amount
     * @param rate Tax rate
     * @return OrderItemTaxLineItem
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static OrderItemTaxLineItem createOrderItemTaxLineItem(String name, Id orderItemId, String type, Double amount, Double rate) {
        OrderItemTaxLineItem itemTax = new OrderItemTaxLineItem();
        itemTax.Name = name;
        itemTax.OrderItemId = orderItemId;
        itemTax.Type = type;
        itemTax.Amount = amount;
        itemTax.Rate = rate;
        itemTax.TaxEffectiveDate = Date.today();
        return itemTax;
    }

    /**
     * @description Creates Order Item Adjustment Line Item
     *   suppress reason: ignore
     * @param name Name
     * @param orderItemId Order item Id (createOrderItem)
     * @param orderAdjustmentGroupId Order Adjustment Group Id
     * @param amount Tax amount
     * @return OrderItemAdjustmentLineItem
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static OrderItemAdjustmentLineItem createOrderItemAdjustmentLineItem(
        String name,
        Id orderItemId,
        Id orderAdjustmentGroupId,
        Double amount
    ) {
        OrderItemAdjustmentLineItem orderItemAdjustmentLineItemRecord = new OrderItemAdjustmentLineItem();
        orderItemAdjustmentLineItemRecord.Name = name;
        orderItemAdjustmentLineItemRecord.OrderItemId = orderItemId;
        orderItemAdjustmentLineItemRecord.OrderAdjustmentGroupId = orderAdjustmentGroupId;
        orderItemAdjustmentLineItemRecord.Amount = amount;
        return orderItemAdjustmentLineItemRecord;
    }

    /**
     * @description Creates payment group
     * @param sourceObjectId Id of object
     * @return PaymentGroup
     */
    public static PaymentGroup createPaymentGroup(String sourceObjectId) {
        PaymentGroup paymentGroup = new PaymentGroup();
        paymentGroup.SourceObjectId = sourceObjectId;
        return paymentGroup;
    }

    /**
     * @description Creates ContentVersion
     * @param data
     * @return ContentVersion
     */
    public static ContentVersion createContentVersion(String data) {
        ContentVersion contentVersion = new ContentVersion(Title = 'Test', PathOnClient = 'test.csv', VersionData = Blob.valueof(data));
        return contentVersion;
    }

    /**
     * @description Creates a new user
     * @param username
     * @return User
     */
    public static User createUser(String username) {
        //   UserRole userRole = [SELECT Id FROM UserRole WHERE Name = 'Aristocrazy' LIMIT 1];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User user = new User(
            Alias = username.substring(0, 7),
            Email = username,
            Username = username,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            // UserRoleId = userRole.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        return user;
    }

    /**
     * @description Creates payment authorization
     * @param amount Payment amount
     * @param paymentGroupId Payment group Id (createPaymentGroup)
     * @return PaymentAuthorization
     */
    public static PaymentAuthorization createPaymentAuthorization(Double amount, String paymentGroupId) {
        PaymentAuthorization paymentAuthorization = new PaymentAuthorization();
        paymentAuthorization.Amount = amount;
        paymentAuthorization.Status = 'Processed';
        paymentAuthorization.ProcessingMode = 'External';
        paymentAuthorization.PaymentGroupId = paymentGroupId;
        paymentAuthorization.GatewayRefNumber = '132456723456wertywer';
        return paymentAuthorization;
    }

    /**
     * @description  Creates payment
     * @author Ioana Tabarcea (Gherasim) | 06-16-2021
     * @param amount
     * @param paymentAuthorizationId
     * @return Payment
     **/
    public static Payment createPayment(Double amount, String paymentAuthorizationId) {
        Payment payment = new Payment();
        payment.PaymentAuthorizationId = paymentAuthorizationId;
        payment.EffectiveDate = Datetime.now();
        payment.Type = 'Capture';
        payment.Amount = amount;
        payment.Status = 'Processed';
        payment.ProcessingMode = 'External';
        return payment;
    }

    /**
     * @description Creates payment for loyalty payment capture
     * @param amount
     * @param paymentAuthorizationId
     * @return Payment
     */
    public static Payment createPaymentForLoyaltyPaymentCapture(Double amount, String paymentAuthorizationId) {
        Payment payment = new Payment();
        payment.PaymentAuthorizationId = paymentAuthorizationId;
        payment.EffectiveDate = Datetime.now();
        payment.Type = 'Capture';
        payment.Amount = amount;
        payment.ProcessingMode = 'External';
        return payment;
    }

    /**
     * @description Creates payment with pending status
     * @param amount Payment amount
     * @param paymentAuthorizationId Payment authorization Id (createPaymentAuthorization)
     * @return Payment
     */
    public static Payment createPendingPayment(Double amount, String paymentAuthorizationId) {
        Payment payment = new Payment();
        payment.PaymentAuthorizationId = paymentAuthorizationId;
        payment.EffectiveDate = Datetime.now();
        payment.Type = 'Capture';
        payment.Amount = amount;
        payment.Status = 'Pending';
        payment.ProcessingMode = 'SALESFORCE';
        payment.GatewayRefNumber = '132456723456wertywer';

        return payment;
    }

    /**
     * @description Creates order payment authorization
     * @return PaymentAuthorization
     */
    public static PaymentAuthorization createOrderAndPaymentAuthorization() {
        Schema.Location location = createLocation('Default', 'Warehouse');
        insert location;

        Id orderId = createOrderAndRelated();
        PaymentGroup paymentGroup = createPaymentGroup(orderId);
        insert paymentGroup;

        PaymentAuthorization paymentAuthorization = createPaymentAuthorization((Double) 60, paymentGroup.Id);
        insert paymentAuthorization;

        Payment payment = createPayment((Double) 60, paymentAuthorization.Id);
        insert payment;

        return paymentAuthorization;
    }
    /**
     * @description Creates order payment authorization
     * @return PaymentAuthorization
     */
    public static Id createSimpleOrder() {
        Schema.Location location = createLocation('Default', 'Warehouse');
        insert location;

        Id orderId = createOrderAndRelated();
        PaymentGroup paymentGroup = createPaymentGroup(orderId);
        insert paymentGroup;

        return orderId;
    }
    /**
     * @description Creates Order for test methods
     *   Test class containing a test setup method cannot
     *   have any methods annotated with "SeeAllData=true"
     * @return Id of the Order
     */
    public static Id createOrderAndRelated() {
        Schema.Location location = COMM_OMS_TestDataFactory.createLocation('Default', 'Warehouse');
        insert location;

        List<COMM_OMS_TestDataFactory.CreateOrderItem> orderItemList = new List<COMM_OMS_TestDataFactory.CreateOrderItem>();

        // #1 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product1 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product1.type = 'Order Product';
        product1.productCode = '001';
        product1.quantity = 2;
        product1.unitPrice = 0;
        product1.family = DEFAULT_PRODUCT_FAMILY;

        // #2 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product2 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product2.type = 'Order Product';
        product2.productCode = '002';
        product2.quantity = 2;
        product2.unitPrice = 0;
        product2.family = DEFAULT_PRODUCT_FAMILY;

        // #3 order item
        COMM_OMS_TestDataFactory.CreateOrderItem shipping = new COMM_OMS_TestDataFactory.CreateOrderItem();
        shipping.type = 'Delivery Charge';
        shipping.productCode = '003';
        shipping.quantity = 2;
        shipping.unitPrice = 0;
        shipping.family = DEFAULT_PRODUCT_FAMILY;

        // #4 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product3 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product3.type = 'Order Product';
        product3.productCode = '004';
        product3.quantity = 2;
        product3.unitPrice = 0;
        product3.family = PRODUCT_FAMILY_FAST_TRACK;

        // #5 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product4 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product4.type = 'Order Product';
        product4.productCode = '005';
        product4.quantity = 2;
        product4.unitPrice = 1;
        product4.paymentType = 'VD';
        product4.sapLocation = 'SAP_LOCATION';
        product4.family = PRODUCT_FAMILY_GIFT_CARD;

        // #6 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product5 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product5.recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId;
        product5.type = 'Order Product';
        product5.productCode = '006';
        product5.quantity = 2;
        product5.unitPrice = 1;
        product5.family = PRODUCT_FAMILY_SUBSCRIPTION;
        product5.subcategory = 'Park';

        orderItemList.add(product1);
        orderItemList.add(product2);
        orderItemList.add(shipping);
        orderItemList.add(product3);
        orderItemList.add(product4);
        orderItemList.add(product5);

        return COMM_OMS_TestDataFactory.createOrderAndRelatedObjects(orderItemList, location.Id)?.Id;
    }

    /**
     * @description Create standard pricebook
     * @return Pricebook
     */
    public static Pricebook2 setStandardPricebookData() {
        Id standardPriceBookId = Test.getStandardPricebookId();
        Integer currentYear = Date.today().year();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPriceBookId,
            IsActive = true,
            Type__c = 'Public',
            COMM_ValidFrom__c = DateTime.newInstance(currentYear, 1, 1, 0, 0, 0),
            COMM_ValidTo__c = DateTime.newInstance(currentYear, 12, 31, 23, 59, 0)
        );

        return standardPricebook;
    }

    public static List<COMM_Capacity__c> createDefaultCapacities(List<Product2> products) {
        List<COMM_Capacity__c> capacities = new List<COMM_Capacity__c>();
        for (Product2 prod : products) {
            Id recordTypeId;
            if (prod.RecordTypeId == Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId) {
                recordTypeId = Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId;
            } else {
                recordTypeId = Schema.SObjectType.COMM_Capacity__c.getRecordTypeInfosByDeveloperName().get('COMM_Capacity').RecordTypeId;
            }
            capacities.add(
                new COMM_Capacity__c(
                    COMM_Capacity__c = 50,
                    COMM_IsDefaultCapacity__c = true,
                    COMM_Product__c = prod.Id,
                    COMM_ValidFrom__c = System.now().addDays(1),
                    COMM_ValidTo__c = System.now().addDays(100),
                    COMM_ProcessStatus__c = 'NOT PROCESSED',
                    RecordTypeId = recordTypeId
                )
            );
        }
        return capacities;
    }

    public static void activateProducts(List<Product2> products) {
        for (Product2 prod : products) {
            prod.IsActive = true;
        }
        update products;
    }

    /**
     * @description Create order and related objects
     * @param orderItemList CreateOrderItem list
     * @param locationId Location id
     * @return Order
     */
    public static Order createOrderAndRelatedObjects(List<CreateOrderItem> orderItemList, String locationId) {
        //Reseller account
        Account resellerAccount = createResellerAccount(DEFAULT_NAME, DEFAULT_RESELLER_ID);
        insert resellerAccount;

        // Product2
        Map<String, Product2> codeToProduct = new Map<String, Product2>();
        List<COMM_ResellerAssortment__c> reselerAssortments = new List<COMM_ResellerAssortment__c>();
        for (CreateOrderItem orderItem : orderItemList) {
            codeToProduct.put(orderItem.productCode, createProduct(orderItem));
        }
        insert codeToProduct.values();
        List<COMM_Capacity__c> capacities = createDefaultCapacities(codeToProduct.values());
        insert capacities;

        activateProducts(codeToProduct.values());

        for (Product2 prod : codeToProduct.values()) {
            reselerAssortments.add(createResellerAssortment(prod.Id, reselleraccount.Id));
        }
        insert reselerAssortments;

        //Pricebook
        Pricebook2 pricebook = setStandardPricebookData();
        update pricebook;

        // PricebookEntry
        Map<String, PricebookEntry> codeToPricebookEntry = new Map<String, PricebookEntry>();
        for (CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            codeToPricebookEntry.put(orderItem.productCode, createPricebookEntry(orderItem.unitPrice, product.Id));
        }
        insert codeToPricebookEntry.values();

        // Account
        Account account = createAccount(DEFAULT_NAME, DEFAULT_NAME, 'rui.salgado@capgemini.com');
        insert account;

        // Saleschannel
        Saleschannel saleschannel = createSaleschannel(DEFAULT_NAME);
        Saleschannel resellerSalesChannel = createSaleschannel(RESELLER_SALESCHANNEL_NAME);
        insert new List<Saleschannel>{ saleschannel, resellerSalesChannel };

        // Order
        Order order = createOrder(account.Id, saleschannel.Id);
        order.BillingStreet = 'Test Street';
        order.BillingPostalCode = '1111-111';
        order.BillingCity = 'Évora';
        order.BillingCountryCode = 'pt';
        insert order;

        // OrderDeliveryMethod
        OrderDeliveryMethod orderDeliveryMethod = createOrderDeliveryMethod();
        insert orderDeliveryMethod;

        // OrderDeliveryGroup
        OrderDeliveryGroup orderDeliveryGroup = createOrderDeliveryGroup(order.Id, orderDeliveryMethod.Id);
        insert orderDeliveryGroup;

        // OrderItem
        Map<String, OrderItem> codeToOrderItem = new Map<String, OrderItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            PricebookEntry pricebookEntry = codeToPricebookEntry.get(orderItem.productCode);

            OrderItem standardOrderItem = createOrderItem(
                order.Id,
                product.Id,
                pricebookEntry.Id,
                orderItem.unitPrice,
                orderItem.quantity,
                orderDeliveryGroup.Id,
                orderItem.type.toString()
            );
            standardOrderItem.COMM_ReservationStart__c = Date.today();
            standardOrderItem.COMM_ReservationEnd__c = Date.today();

            codeToOrderItem.put(orderItem.productCode, standardOrderItem);
        }
        insert codeToOrderItem.values();

        // OrderItemTaxLineItem
        List<OrderItemTaxLineItem> orderItemTaxLineItems = new List<OrderItemTaxLineItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            if (orderItem.applyTax) {
                OrderItem standardOrderItem = codeToOrderItem.get(orderItem.productCode);

                OrderItemTaxLineItem orderItemTaxLineItem = createOrderItemTaxLineItem(
                    DEFAULT_NAME,
                    standardOrderItem.Id,
                    'Estimated',
                    orderItem.taxAmount,
                    orderItem.taxRate
                );
                orderItemTaxLineItems.add(orderItemTaxLineItem);
            }
        }
        if (!orderItemTaxLineItems.isEmpty()) {
            insert orderItemTaxLineItems;
        }

        order.Status = 'Activated';
        update order;

        return order;
    }

    /**
     * @description Creates order payment authorization
     * @return PaymentAuthorization
     */
    public static Id createSimpleOrderWithDiscount() {
        Schema.Location location = createLocation('Default', 'Warehouse');
        insert location;

        Id orderId = createOrderWithDiscountAndRelated();
        PaymentGroup paymentGroup = createPaymentGroup(orderId);
        insert paymentGroup;

        return orderId;
    }
    /**
     * @description Creates Order for test methods
     *   Test class containing a test setup method cannot
     *   have any methods annotated with "SeeAllData=true"
     * @return Id of the Order
     */
    public static Id createOrderWithDiscountAndRelated() {
        Schema.Location location = COMM_OMS_TestDataFactory.createLocation('Default', 'Warehouse');
        insert location;

        List<COMM_OMS_TestDataFactory.CreateOrderItem> orderItemList = new List<COMM_OMS_TestDataFactory.CreateOrderItem>();

        // #1 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product1 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product1.type = 'Order Product';
        product1.productCode = '001';
        product1.quantity = 2;
        product1.unitPrice = 0;
        product1.family = DEFAULT_PRODUCT_FAMILY;

        // #2 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product2 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product2.type = 'Order Product';
        product2.productCode = '002';
        product2.quantity = 2;
        product2.unitPrice = 0;
        product2.family = DEFAULT_PRODUCT_FAMILY;

        // #3 order item
        COMM_OMS_TestDataFactory.CreateOrderItem shipping = new COMM_OMS_TestDataFactory.CreateOrderItem();
        shipping.type = 'Delivery Charge';
        shipping.productCode = '003';
        shipping.quantity = 2;
        shipping.unitPrice = 0;
        shipping.family = DEFAULT_PRODUCT_FAMILY;

        // #4 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product3 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product3.type = 'Order Product';
        product3.productCode = '004';
        product3.quantity = 2;
        product3.unitPrice = 0;
        product3.family = PRODUCT_FAMILY_FAST_TRACK;
        product3.subcategory = PRODUCT_FAMILY_FAST_TRACK;

        // #4 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product4 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product4.type = 'Order Product';
        product4.productCode = '005';
        product4.quantity = 2;
        product4.unitPrice = 1;
        product4.family = PRODUCT_FAMILY_GIFT_CARD;

        COMM_OMS_TestDataFactory.CreateOrderItem product5 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product5.recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId;
        product5.type = 'Order Product';
        product5.productCode = '006';
        product5.quantity = 2;
        product5.unitPrice = 1;
        product5.family = PRODUCT_FAMILY_SUBSCRIPTION;
        product5.subcategory = 'Staff Individual';

        orderItemList.add(product1);
        orderItemList.add(product2);
        orderItemList.add(shipping);
        orderItemList.add(product3);
        orderItemList.add(product4);
        orderItemList.add(product5);

        return COMM_OMS_TestDataFactory.createOrderWithDiscountAndRelatedObjects(orderItemList, location.Id)?.Id;
    }

    /**
     * @description Create order and related objects
     * @param orderItemList CreateOrderItem list
     * @param locationId Location id
     * @return Order
     */
    public static Order createOrderWithDiscountAndRelatedObjects(List<CreateOrderItem> orderItemList, String locationId) {
        // Product2
        Map<String, Product2> codeToProduct = new Map<String, Product2>();
        for (CreateOrderItem orderItem : orderItemList) {
            codeToProduct.put(orderItem.productCode, createProduct(orderItem));
        }
        insert codeToProduct.values();

        // PricebookEntry
        Map<String, PricebookEntry> codeToPricebookEntry = new Map<String, PricebookEntry>();
        for (CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            codeToPricebookEntry.put(orderItem.productCode, createPricebookEntry(orderItem.unitPrice, product.Id));
        }
        insert codeToPricebookEntry.values();

        // Account
        Account account = createAccount(DEFAULT_NAME, DEFAULT_NAME, 'rui.salgado@capgemini.com');
        insert account;

        // Saleschannel
        Saleschannel saleschannel = createSaleschannel(DEFAULT_NAME);
        insert saleschannel;

        // Order
        Order order = createOrder(account.Id, saleschannel.Id);
        order.BillingStreet = 'Test Street';
        order.BillingPostalCode = '1111-111';
        order.BillingCity = 'Évora';
        order.BillingCountryCode = 'pt';
        insert order;

        // OrderDeliveryMethod
        OrderDeliveryMethod orderDeliveryMethod = createOrderDeliveryMethod();
        insert orderDeliveryMethod;

        // OrderDeliveryGroup
        OrderDeliveryGroup orderDeliveryGroup = createOrderDeliveryGroup(order.Id, orderDeliveryMethod.Id);
        insert orderDeliveryGroup;

        // OrderItem
        Map<String, OrderItem> codeToOrderItem = new Map<String, OrderItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            PricebookEntry pricebookEntry = codeToPricebookEntry.get(orderItem.productCode);

            OrderItem standardOrderItem = createOrderItem(
                order.Id,
                product.Id,
                pricebookEntry.Id,
                orderItem.unitPrice,
                orderItem.quantity,
                orderDeliveryGroup.Id,
                orderItem.type.toString()
            );
            standardOrderItem.COMM_ReservationStart__c = Date.today();
            standardOrderItem.COMM_ReservationEnd__c = Date.today();

            codeToOrderItem.put(orderItem.productCode, standardOrderItem);
        }
        insert codeToOrderItem.values();

        // OrderItemTaxLineItem
        List<OrderItemTaxLineItem> orderItemTaxLineItems = new List<OrderItemTaxLineItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            if (orderItem.applyTax) {
                OrderItem standardOrderItem = codeToOrderItem.get(orderItem.productCode);

                OrderItemTaxLineItem orderItemTaxLineItem = createOrderItemTaxLineItem(
                    DEFAULT_NAME,
                    standardOrderItem.Id,
                    'Estimated',
                    orderItem.taxAmount,
                    orderItem.taxRate
                );
                orderItemTaxLineItems.add(orderItemTaxLineItem);
            }
        }
        if (!orderItemTaxLineItems.isEmpty()) {
            insert orderItemTaxLineItems;
        }

        // OrderItemAdjustmentLineItem
        OrderAdjustmentGroup orderAdjustmentGroupRecord = new OrderAdjustmentGroup(
            Name = 'PromotionTest_20%offOrderAmountOver100',
            Description = 'PromotionTest_20%offOrderAmountOver100',
            Type = 'Header',
            OrderId = order.Id
        );
        insert orderAdjustmentGroupRecord;
        Map<String, OrderItemAdjustmentLineItem> orderItemAdjustmentLineItemByOrderItemId = new Map<String, OrderItemAdjustmentLineItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            OrderItem standardOrderItem = codeToOrderItem.get(orderItem.productCode);
            OrderItemAdjustmentLineItem orderItemAdjustmentLineItemRecord = createOrderItemAdjustmentLineItem(
                standardOrderItem.Id + ': Discount 20%',
                standardOrderItem.Id,
                orderAdjustmentGroupRecord.Id,
                (Double) (standardOrderItem.TotalLineAmount * 0.2)
            );
            orderItemAdjustmentLineItemByOrderItemId.put(standardOrderItem.Id, orderItemAdjustmentLineItemRecord);
        }
        insert orderItemAdjustmentLineItemByOrderItemId.values();

        // OrderItemTaxLineItem
        List<OrderItemTaxLineItem> promotionOrderItemTaxLineItems = new List<OrderItemTaxLineItem>();
        for (CreateOrderItem orderItem : orderItemList) {
            if (orderItem.applyTax) {
                OrderItem standardOrderItem = codeToOrderItem.get(orderItem.productCode);

                OrderItemTaxLineItem orderItemTaxLineItem = createOrderItemTaxLineItem(
                    DEFAULT_NAME,
                    standardOrderItem.Id,
                    'Estimated',
                    (Double) (orderItem.taxAmount * 0.2),
                    orderItem.taxRate
                );
                orderItemTaxLineItem.OrderItemAdjustmentLineItemId = orderItemAdjustmentLineItemByOrderItemId.get(standardOrderItem.Id).Id;
                promotionOrderItemTaxLineItems.add(orderItemTaxLineItem);
            }
        }
        if (!promotionOrderItemTaxLineItems.isEmpty()) {
            insert promotionOrderItemTaxLineItems;
        }

        order.Status = 'Activated';
        update order;

        return order;
    }

    /**
     * @description Creates order payment summary
     * @param orderId Order Id (createOrder)
     * @param orderSummaryId Order summary Id
     * @param amount Amount
     * @return ConnectApi.CreateOrderPaymentSummaryOutputRepresentation
     */
    public static ConnectApi.CreateOrderPaymentSummaryOutputRepresentation createOrderPaymentSummary(
        String orderId,
        String orderSummaryId,
        Double amount
    ) {
        PaymentGroup paymentGroup = createPaymentGroup(orderId);
        insert paymentGroup;

        PaymentAuthorization paymentAuthorization = createPaymentAuthorization(amount, paymentGroup.Id);
        insert paymentAuthorization;

        Payment payment = createPayment(amount, String.valueOf(paymentAuthorization.Id));
        insert payment;

        ConnectApi.CreateOrderPaymentSummaryInputRepresentation orderPaymentSummaryInput = new ConnectApi.CreateOrderPaymentSummaryInputRepresentation();
        orderPaymentSummaryInput.orderSummaryId = orderSummaryId;

        List<String> paymentList = new List<String>();
        paymentList.add(payment.Id);

        orderPaymentSummaryInput.paymentIds = paymentList;
        orderPaymentSummaryInput.paymentAuthorizationId = paymentAuthorization.Id;
        return ConnectAPI.OrderPaymentSummary.createOrderPaymentSummary(orderPaymentSummaryInput);
    }

    /**
     * @description Model to use to create
     *   OrderItem in test classes
     */
    public class CreateOrderItem {
        /**
         * @description Set default values
         */
        public CreateOrderItem() {
            this.applyTax = false;
        }

        /**
         * @description Product code of the item
         */
        public String productCode { get; set; }

        /**
         * @description Quantity of the item
         */
        public Integer quantity { get; set; }

        /**
         * @description Unit price of the item
         */
        public Double unitPrice { get; set; }

        /**
         * @description Type of the item
         *   DELIVERY CHARGE|ORDER PRODUCT
         */
        public String type { get; set; }

        /**
         * @description Family of the item
         *   LOUNGE | FAST TRACK | Parking
         */
        public String family { get; set; }

        /**
         * @description Sub-Category of the item
         *
         */
        public String subcategory { get; set; }

        /**
         * @description Record Type identifier of the item
         *
         */
        public String recordTypeId { get; set; }

        /**
         * @description Tax amount for the item (optional)
         */
        public Double taxAmount { get; set; }

        /**
         * @description Tax rate for the item (optional)
         */
        public Double taxRate { get; set; }

        /**
         * @description Payment Type for the item (optional)
         */
        public String paymentType { get; set; }

        /**
         * @description SAP Location for the item (optional)
         */
        public String sapLocation { get; set; }

        /**
         * @description Apply tax
         */
        public Boolean applyTax { get; set; }
    }

    /**
     * @description Creates fulfillment order
     * @param orderSummaryId  Order Summary Id
     * @return Fulfillment order
     */
    public static ConnectApi.FulfillmentOrderOutputRepresentation createFulfillmentOrder(Id orderSummaryId) {
        Schema.Location location = createLocation('Default', 'Warehouse');
        insert location;

        ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput.orderSummaryId = orderSummaryId;

        List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryList = [
            SELECT Id, (SELECT Id, Quantity FROM OrderItemSummaries)
            FROM OrderDeliveryGroupSummary
            WHERE OrderSummaryId = :orderSummaryId
        ];

        for (OrderDeliveryGroupSummary orderDeliveryGroupSummary : orderDeliveryGroupSummaryList) {
            fulfillmentOrderInput.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;

            List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
            ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
            fulfillmentGroup.fulfilledFromLocationId = location.Id;
            fulfillmentGroup.fulfillmentType = 'Warehouse';

            List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

            for (OrderItemSummary orderItemSummary : orderDeliveryGroupSummary.OrderItemSummaries) {
                ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
                oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
                oisInputRepresentation.quantity = orderItemSummary.quantity;
                orderItemSummaries.add(oisInputRepresentation);
            }

            fulfillmentGroup.orderItemSummaries = orderItemSummaries;
            fulfillmentGroups.add(fulfillmentGroup);
            fulfillmentOrderInput.fulfillmentGroups = fulfillmentGroups;
        }

        return ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput);
    }

    /**
     * @description Creates return order line item for return order
     * @param orderSummaryId  Order Summary Id
     * @param orderItemSummariesWithCount
     * @return Return order line item list
     */
    public static List<ReturnOrderLineItem> createReturnOrderLineItem(
        String orderSummaryId,
        Map<OrderItemSummary, Integer> orderItemSummariesWithCount
    ) {
        ReturnOrder returnOrder = new ReturnOrder(OrderSummaryId = orderSummaryId, Status = 'Submitted');
        insert returnOrder;
        ReturnOrderLineItem[] results = new List<ReturnOrderLineItem>();
        for (OrderItemSummary ord : orderItemSummariesWithCount.keyset()) {
            results.add(
                new ReturnOrderLineItem(
                    ReturnOrderId = returnOrder.Id,
                    Product2Id = ord.Product2Id,
                    QuantityReturned = orderItemSummariesWithCount.get(ord),
                    QuantityExpected = orderItemSummariesWithCount.get(ord),
                    OrderItemSummaryId = ord.Id
                )
            );
        }

        insert results;
        return results;
    }

    /**
     * @description Creates credit memo
     * @param orderSummaryId  Order Summary Id
     * @param itemsWithQuantity
     * @return Credit memo id
     */
    public static String createCreditMemo(String orderSummaryId, Map<OrderItemSummary, Integer> itemsWithQuantity) {
        ConnectApi.ChangeInputRepresentation changeInput = new ConnectApi.ChangeInputRepresentation();
        List<ConnectApi.ChangeItemInputRepresentation> items = new List<ConnectApi.ChangeItemInputRepresentation>();
        for (OrderItemSummary item : itemsWithQuantity.keySet()) {
            ConnectApi.ChangeItemInputRepresentation itemInput = new ConnectApi.ChangeItemInputRepresentation();
            itemInput.orderItemSummaryId = item.Id;
            itemInput.quantity = itemsWithQuantity.get(item);
            itemInput.reason = 'Unknown';
            itemInput.shippingReductionFlag = false;
            items.add(itemInput);
        }

        try {
            changeInput.changeItems = items;
            ConnectApi.SubmitReturnOutputRepresentation submitReturnOutput = ConnectApi.OrderSummary.submitReturn(orderSummaryId, changeInput);

            ConnectApi.CreateCreditMemoInputRepresentation creditMemoInput = new ConnectApi.CreateCreditMemoInputRepresentation();
            creditMemoInput.changeOrderIds = new List<String>{ submitReturnOutput.changeOrderId };
            ConnectApi.CreateCreditMemoOutputRepresentation creditMemoOutput = ConnectApi.OrderSummary.createCreditMemo(
                orderSummaryId,
                creditMemoInput
            );

            CreditMemo creditMemo = [SELECT Id, TotalAmountWithTax FROM CreditMemo WHERE Id = :creditMemoOutput.creditMemoId];
            ConnectApi.EnsureRefundsAsyncInputRepresentation refundInput = new ConnectApi.EnsureRefundsAsyncInputRepresentation();
            refundInput.creditMemoId = creditMemoOutput.creditMemoId;
            ConnectApi.OrderSummary.ensureRefundsAsync(orderSummaryId, refundInput);

            Refund refund = createRefund(orderSummaryId, creditMemo.TotalAmountWithTax);
            insert refund;

            return creditMemoOutput.creditMemoId;
        } catch (ConnectApi.ConnectApiException ex) {
            throw ex;
        }
    }

    /**
     * @description Creates refund
     * @param orderSummaryId  Order Summary Id
     * @param amount
     * @return Refund
     */
    public static Refund createRefund(String orderSummaryId, Decimal amount) {
        OrderSummary order = [
            SELECT Id, AccountId, (SELECT Id FROM OrderPaymentSummaries)
            FROM OrderSummary
            WHERE Id = :orderSummaryId
        ];
        Refund refund = new Refund();
        refund.AccountId = order.AccountId;
        refund.EffectiveDate = Datetime.now();
        refund.Type = 'Referenced';
        refund.Amount = amount;
        refund.Status = 'Processed';
        refund.ProcessingMode = 'External';
        refund.GatewayDate = Datetime.now();
        refund.GatewayRefNumber = DEFAULT_NAME;
        if (!order.OrderPaymentSummaries.isEmpty()) {
            refund.OrderPaymentSummaryId = order.OrderPaymentSummaries[0].Id;
        }
        return refund;
    }
}