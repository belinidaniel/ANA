/**
 * @author Diogo Gonçalves
 * @description Class to test COMM_SL_WS_ResellerOrder.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date        Coverage             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  02/10/2024  78                  Original version
 * Daniel Reto      04/11/2024  93                  ECOMM-327
 **/
@isTest
private class COMM_SL_WS_ResellerOrderTest {
    @TestSetup
    static void makeData() {
        Schema.Location location = COMM_OMS_TestDataFactory.createLocation('Default', 'Warehouse');
        insert location;

        List<COMM_OMS_TestDataFactory.CreateOrderItem> orderItemList = new List<COMM_OMS_TestDataFactory.CreateOrderItem>();

        // #1 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product1 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product1.type = 'Order Product';
        product1.productCode = '001';
        product1.quantity = 2;
        product1.unitPrice = 0;
        product1.family = 'Parking';

        // #2 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product2 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product2.type = 'Order Product';
        product2.productCode = '002';
        product2.quantity = 2;
        product2.unitPrice = 0;
        product2.family = 'Parking';

        // #3 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product3 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product3.type = 'Order Product';
        product3.productCode = '004';
        product3.quantity = 2;
        product3.unitPrice = 0;
        product3.family = 'Fast Track';
        
        // #4 order item
        COMM_OMS_TestDataFactory.CreateOrderItem product4 = new COMM_OMS_TestDataFactory.CreateOrderItem();
        product4.type = 'Order Product';
        product4.productCode = '007';
        product4.quantity = 2;
        product4.unitPrice = 0;
        product4.family = 'Bundle';

        orderItemList.add(product1);
        orderItemList.add(product2);
        orderItemList.add(product3);
        orderItemList.add(product4);

        //Reseller account
        Account resellerAccount = COMM_OMS_TestDataFactory.createResellerAccount('default', 'resellerId');
        insert resellerAccount;

        // Product2
        Map<String, Product2> codeToProduct = new Map<String, Product2>();
        List<COMM_ResellerAssortment__c> reselerAssortments = new List<COMM_ResellerAssortment__c>();
        for (COMM_OMS_TestDataFactory.CreateOrderItem orderItem : orderItemList) {
            codeToProduct.put(orderItem.productCode, COMM_OMS_TestDataFactory.createProduct(orderItem));
        }
        insert codeToProduct.values();
        List<COMM_Capacity__c> capacities = COMM_OMS_TestDataFactory.createDefaultCapacities(codeToProduct.values());
        insert capacities;

        COMM_OMS_TestDataFactory.activateProducts(codeToProduct.values());

        List<Product2> productList = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN ('001', '002', '004', '007') ORDER By ProductCode DESC];
        productList[0].COMM_ProductType__c = 'bundle';
        productList[1].COMM_ProductType__c = 'single';
        productList[2].COMM_ProductType__c = 'single';
        update productList;
        //Pricebook
        Pricebook2 pricebook = COMM_OMS_TestDataFactory.setStandardPricebookData();
        update pricebook;
        //Mock Pricebook Configuration Record
        Pricebook2 customPbs = (Pricebook2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Pricebook2',
            new Map<String, Object>{
                'Name' => 'Custom Reseller Price Book',
                'Description' => 'Custom Reseller Price Book',
                'Type__c' => 'Reseller',
                'IsActive' => true,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(5)
            }
        )[0];
        customPbs.COMM_ValidFrom__c = System.now().addDays(-1);
        update customPbs;
        
        //Mock Product Variation Configuration Record
        COMM_ProductVariations__c variationRecord1 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'COMM_MasterProduct__c' => productList[0].Id,
                'COMM_RelatedProduct__c' => productList[1].Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 48
            }
        )[0];
        COMM_ProductVariations__c variationRecord2 = (COMM_ProductVariations__c) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductVariations__c',
            new Map<String, Object>{
                'COMM_MasterProduct__c' => productList[0].Id,
                'COMM_RelatedProduct__c' => productList[2].Id,
                'COMM_Quantity__c' => 2,
                'COMM_NumberOfHours__c' => 48
            }
        )[0];
        //Mock Reseller Assortment Record
        COMM_ResellerAssortment__c resellerAssortment1 = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_Product__c' => productList[0].Id,
                'COMM_Pricebook__c' => customPbs.Id,
                'COMM_CurrentDailyQuantity__c' => 5,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        reselerAssortments.add(resellerAssortment1);
        COMM_ResellerAssortment__c resellerAssortment2 = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_Product__c' => productList[1].Id,
                'COMM_Pricebook__c' => customPbs.Id,
                'COMM_CurrentDailyQuantity__c' => 0,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        reselerAssortments.add(resellerAssortment2);
        COMM_ResellerAssortment__c resellerAssortment3 = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_Product__c' => productList[2].Id,
                'COMM_Pricebook__c' => customPbs.Id,
                'COMM_CurrentDailyQuantity__c' => 0,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        reselerAssortments.add(resellerAssortment3);
        COMM_ResellerAssortment__c resellerAssortment4 = (COMM_ResellerAssortment__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_ResellerAssortment__c',
            new Map<String, Object>{
                'COMM_Account__c' => resellerAccount.Id,
                'COMM_Product__c' => productList[3].Id,
                'COMM_Pricebook__c' => customPbs.Id,
                'COMM_CurrentDailyQuantity__c' => 0,
                'COMM_DailyLimit__c' => 10
            }
        )[0];
        reselerAssortments.add(resellerAssortment4);
        insert reselerAssortments;

        // PricebookEntry
        Map<String, PricebookEntry> codeToPricebookEntry = new Map<String, PricebookEntry>();
        for (COMM_OMS_TestDataFactory.CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            codeToPricebookEntry.put('standard' + orderItem.productCode, COMM_OMS_TestDataFactory.createPricebookEntry(orderItem.unitPrice, product.Id));
            PricebookEntry priceBookEntry = new PriceBookEntry();
            priceBookEntry.IsActive = true;
            priceBookEntry.UnitPrice = orderItem.unitPrice;
            priceBookEntry.Pricebook2Id = customPbs.Id;
            priceBookEntry.Product2Id = product.Id;
            priceBookEntry.COMM_First15MinuteUnit__c = 1;
            priceBookEntry.COMM_Second15MinuteUnit__c = 1;
            priceBookEntry.COMM_Third15MinuteUnit__c = 1;
            priceBookEntry.COMM_Remaining15MinuteUnit__c = 1;
            priceBookEntry.COMM_FirstPeriodStartDay__c = 1;
            priceBookEntry.COMM_FirstPeriodEndDay__c = 366;
            priceBookEntry.COMM_FirstPeriodDailyMaximum__c = 1;
            codeToPricebookEntry.put(orderItem.productCode, priceBookEntry);
        }
        insert codeToPricebookEntry.values();

        // Saleschannel
        Saleschannel saleschannel = COMM_OMS_TestDataFactory.createSaleschannel('default');
        Saleschannel resellerSalesChannel = COMM_OMS_TestDataFactory.createSaleschannel('reseller');
        insert new List<Saleschannel>{ saleschannel, resellerSalesChannel };

        // Order
        Order order = new Order();
        order.AccountId = resellerAccount.Id;
        order.Pricebook2Id = customPbs.Id;
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        order.SalesChannelId = saleschannel.Id;
        order.COMM_Language__c = 'pt_PT';
        order.COMM_BillingName__c = 'Billing Name';
        order.BillingEmailAddress = 'test@test.com';
        order.COMM_BillingVATNumber__c = '999999999';
        order.OrderedDate = DateTime.now().addDays(-10);
        Integer randomNumber = Math.round((Math.random() * (900000) + 100000));
        order.OrderReferenceNumber = 'default' + String.valueOf(randomNumber);
        order.BillingStreet = 'Test Street';
        order.BillingPostalCode = '1111-111';
        order.BillingCity = 'Évora';
        order.BillingCountryCode = 'pt';
        insert order;

        // OrderDeliveryMethod
        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod();
        orderDeliveryMethod.Name = 'default';
        orderDeliveryMethod.ReferenceNumber = 'default';
        insert orderDeliveryMethod;

        // OrderDeliveryGroup
        OrderDeliveryGroup orderDeliveryGroup = COMM_OMS_TestDataFactory.createOrderDeliveryGroup(order.Id, orderDeliveryMethod.Id);
        insert orderDeliveryGroup;

        // OrderItem
        Map<String, OrderItem> codeToOrderItem = new Map<String, OrderItem>();
        for (COMM_OMS_TestDataFactory.CreateOrderItem orderItem : orderItemList) {
            Product2 product = codeToProduct.get(orderItem.productCode);
            PricebookEntry pricebookEntry = codeToPricebookEntry.get(orderItem.productCode);

            OrderItem standardOrderItem = COMM_OMS_TestDataFactory.createOrderItem(
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
        for (COMM_OMS_TestDataFactory.CreateOrderItem orderItem : orderItemList) {
            if (orderItem.applyTax) {
                OrderItem standardOrderItem = codeToOrderItem.get(orderItem.productCode);

                OrderItemTaxLineItem orderItemTaxLineItem = COMM_OMS_TestDataFactory.createOrderItemTaxLineItem(
                    'default',
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
        
    }

    @IsTest
    static void testCreateResellerOrder() {
        Account testReseller = [SELECT Id FROM Account WHERE Name = 'default' LIMIT 1];
        String dateFormat = 'yyyy-MM-dd\'T\'HH:mm:ss';
        String startDate = System.now().addDays(1).format(dateFormat);
        String endDate = System.now().addDays(2).format(dateFormat);
        String orderId = 'O98765';

        // Mock service Input
        COMM_WS_ResellerOrderInput rOrderInput = COMM_WS_ResellerOrderInput.parse(
            '{"resellerId":"resellerId","orderId":"' +
                orderId +
                '","orderItems":[{"orderLineId":"OL123","productId":"001","startDate":"' +
                startDate +
                '","endDate":"' +
                endDate +
                '","passengerName":"John Doe","licensePlate":"XYZ1234"},{"orderLineId":"OL124","productId":"002","startDate":"' +
                startDate +
                '","endDate":"' +
                endDate +
                '","passengerName":"Jane Smith","licensePlate":"ABC5678"},' +
                '{"orderLineId":"OL125","productId":"002", "bundleProductId": "007", "bundleLineId": "1","startDate":"' +
                startDate +
                '","endDate":"' +
                endDate +
                '","passengerName":"John Doe","licensePlate":"XYZ1234"},{"orderLineId":"OL125",' +
                '"productId":"004", "bundleProductId": "007", "bundleLineId": "2"' +
                ',"startDate":"' +
                startDate +
                '","endDate":"' +
                endDate +
                '","passengerName":"Jane Smith","licensePlate":"ABC5678"}' +
                ']}'
        );

        Test.startTest();
        COMM_SL_WS_ResellerOrder.createResellerOrder(rOrderInput);
        Test.stopTest();

        // Assert that the Order was created
        List<Order> orders = [SELECT Id, EffectiveDate, Status, (SELECT Id FROM OrderItems) FROM Order WHERE OrderReferenceNumber = :orderId];
        Assert.areEqual(1, orders.size(), 'No order was created');

        // Assert that the OrderItems were created
        List<OrderItem> orderItems = [SELECT Id, Product2Id, Quantity FROM OrderItem WHERE OrderId = :orders[0].Id];
        Assert.areEqual(4, orderItems.size(), '2 order items were expected');

        // Assert that the tax lines were created
        List<OrderItemTaxLineItem> taxLines = [SELECT Id, Name, Type, Rate, Amount FROM OrderItemTaxLineItem WHERE OrderId = :orders[0].Id];
        Assert.areEqual(orderItems.size(), taxLines.size(), orderItems.size() + ' order items were expected');

        // Assert that the PaymentMethod was created
        List<CardPaymentMethod> paymentMethods = [SELECT Id, AccountId FROM CardPaymentMethod WHERE AccountId = :testReseller.Id];
        Assert.areEqual(1, paymentMethods.size(), '2 payment methods were expected');
    }
}