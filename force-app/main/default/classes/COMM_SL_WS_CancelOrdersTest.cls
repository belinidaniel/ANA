/**
 * @author Daniel Reto
 * @description COMM_SL_WS_CancelOrders Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Daniel Reto      03/07/2024    86           Original version
 **/
@isTest
private class COMM_SL_WS_CancelOrdersTest {
    @TestSetup
    static void makeData() {
        COMM_OMS_TestDataFactory.createOrderAndRelated();
    }

    @isTest
    static void cancelOrderByIdTest() {
        // generate input request
        List<OrderSummary> orderSummayList = [
            SELECT Id, Status, OrderNumber, AccountId, (SELECT Id FROM OrderItemSummaries WHERE AdjustedLineAmtWithTax > 0)
            FROM OrderSummary
        ];
        Assert.areEqual(orderSummayList.isEmpty(), false, 'Order Summary not found.');
        COMM_WS_CancelOrdersInput inputRequest = new COMM_WS_CancelOrdersInput();
        inputRequest.accountId = orderSummayList[0].AccountId;
        inputRequest.orderSummaryId = orderSummayList[0].Id;
        inputRequest.partial = true;
        inputRequest.orderProductSummaryIds = new List<String>();
        inputRequest.orderProductSummaryIds.add(orderSummayList[0].OrderItemSummaries[0].Id);

        // run specific method
        Test.startTest();
        COMM_SL_WS_CancelOrders cancelOrderService = new COMM_SL_WS_CancelOrders();
        COMM_WS_CancelOrdersOutput outputRequest = cancelOrderService.cancelOrder(inputRequest);
        Test.stopTest();

        COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
        OrderItemSummary expectedOrderItemSummaryRecord = orderItemSummaryRep.getOrderItemSummariesById(inputRequest.orderProductSummaryIds)[0];

        // Assert
        Assert.areEqual(null, outputRequest.errorMsg, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(null, outputRequest.errorCode, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(true, outputRequest.success, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(
            inputRequest.orderProductSummaryIds,
            outputRequest.orderProductSummaryIds,
            'The result should have the same value as the OrderSummary'
        );
        Assert.areEqual(
            COMM_DO_OrderItemSummary.RETURNED_STATUS,
            expectedOrderItemSummaryRecord.Status,
            'The result should have the same value as the OrderSummary'
        );
    }

    @isTest
    static void cancelOrderByOrderNumberTest() {
        // generate input request
        List<OrderSummary> orderSummayList = [SELECT Id, Status, OrderNumber, AccountId, (SELECT Id, Status FROM OrderItemSummaries WHERE  Type = 'Order Product') FROM OrderSummary];
        Assert.areEqual(orderSummayList.isEmpty(), false, 'Order Summary not found.');
        COMM_WS_CancelOrdersInput inputRequest = new COMM_WS_CancelOrdersInput();
        inputRequest.accountId = orderSummayList[0].AccountId;
        inputRequest.orderNumber = orderSummayList[0].OrderNumber;
        inputRequest.partial = false;
        inputRequest.orderProductSummaryIds = new List<String>{ '123456789' };
        Set<String> expectedOrderProductSummaryIds = new Set<String>();
        for (OrderItemSummary orderItemSummaryRecord : orderSummayList[0].OrderItemSummaries) {
            expectedOrderProductSummaryIds.add(orderItemSummaryRecord.Id);
        }

        // run specific method
        Test.startTest();
        COMM_SL_WS_CancelOrders cancelOrderService = new COMM_SL_WS_CancelOrders();
        COMM_WS_CancelOrdersOutput outputRequest = cancelOrderService.cancelOrder(inputRequest);
        Test.stopTest();

        // Assert
        Assert.areEqual(null, outputRequest.errorMsg, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(null, outputRequest.errorCode, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(true, outputRequest.success, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(
            expectedOrderProductSummaryIds,
            new Set<String>(outputRequest.orderProductSummaryIds),
            'The result should have the same value as the OrderSummary'
        );
    }

    @isTest
    static void cancelOrderAccountIdAndEmailEmptyTest() {
        // generate input request
        List<OrderSummary> orderSummayList = [SELECT Id, Status, OrderNumber, AccountId, (SELECT Id FROM OrderItemSummaries) FROM OrderSummary];
        Assert.areEqual(orderSummayList.isEmpty(), false, 'Order Summary not found.');
        COMM_WS_CancelOrdersInput inputRequest = new COMM_WS_CancelOrdersInput();
        inputRequest.orderSummaryId = orderSummayList[0].Id;
        inputRequest.partial = true;
        inputRequest.orderProductSummaryIds = new List<String>();
        for (OrderItemSummary orderItemSummaryRecord : orderSummayList[0].OrderItemSummaries) {
            inputRequest.orderProductSummaryIds.add(orderItemSummaryRecord.Id);
            break;
        }

        // run specific method
        Test.startTest();
        COMM_SL_WS_CancelOrders cancelOrderService = new COMM_SL_WS_CancelOrders();
        COMM_WS_CancelOrdersOutput outputRequest = cancelOrderService.cancelOrder(inputRequest);
        Test.stopTest();

        // Assert
        Assert.areEqual(
            'Data received doesn\'t match Salesforce Data!',
            outputRequest.errorMsg,
            'The result should have the same value as the OrderSummary'
        );
        Assert.areEqual('ERROR_FOUND', outputRequest.errorCode, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(false, outputRequest.success, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(
            inputRequest.orderProductSummaryIds,
            outputRequest.orderProductSummaryIds,
            'The result should have the same value as the OrderSummary'
        );
    }

    @isTest
    static void cancelOrderWrongOrderItemSummaryIdTest() {
        // generate input request
        List<OrderSummary> orderSummayList = [SELECT Id, Status, OrderNumber, AccountId, (SELECT Id FROM OrderItemSummaries) FROM OrderSummary];
        Assert.areEqual(orderSummayList.isEmpty(), false, 'Order Summary not found.');
        COMM_WS_CancelOrdersInput inputRequest = new COMM_WS_CancelOrdersInput();
        inputRequest.accountId = orderSummayList[0].AccountId;
        inputRequest.orderSummaryId = orderSummayList[0].Id;
        inputRequest.partial = true;
        inputRequest.orderProductSummaryIds = new List<String>{ '123456789' };

        // run specific method
        Test.startTest();
        COMM_SL_WS_CancelOrders cancelOrderService = new COMM_SL_WS_CancelOrders();
        COMM_WS_CancelOrdersOutput outputRequest = cancelOrderService.cancelOrder(inputRequest);
        Test.stopTest();

        // Assert
        Assert.areEqual(
            'Some Order Item Summary Ids do not exist: 123456789 ',
            outputRequest.errorMsg,
            'The result should have the same value as the OrderSummary'
        );
        Assert.areEqual('ERROR_FOUND', outputRequest.errorCode, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(false, outputRequest.success, 'The result should have the same value as the OrderSummary');
        Assert.areEqual(
            inputRequest.orderProductSummaryIds,
            outputRequest.orderProductSummaryIds,
            'The result should have the same value as the OrderSummary'
        );
    }
}