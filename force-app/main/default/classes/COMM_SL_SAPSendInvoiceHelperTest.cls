/**
 * @author Daniel Lascas
 * @description COMM_SL_SAPSendInvoiceHelper test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_SL_SAPSendInvoiceHelperTest {
    @isTest
    static void buildWhereClauseTest() {
        List<COMM_MonthlyFiscalDocumentControl__c> controllerList = (List<COMM_MonthlyFiscalDocumentControl__c>) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_MonthlyFiscalDocumentControl__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_DocumentMonth__c' => System.today().addMonths(-1).month(),
                'COMM_DocumentYear__c' => System.today().addMonths(-1).year()
            }
        );
        Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>> controlMap = new Map<Id, List<COMM_MonthlyFiscalDocumentControl__c>>();

        Test.startTest();
        String whereClause = COMM_SL_SAPSendInvoiceHelper.buildWhereClause(controllerList, controlMap);
        Test.stopTest();

        Assert.areEqual('CreatedDate = N_MONTHS_AGO:1', whereClause, 'where clause does not match expected');
        Assert.isFalse(controlMap.isEmpty(), 'expected map to have been updated');
    }

    @isTest
    static void obtainInvoiceForMonthListTest() {
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        Date controlDate = System.today().addMonths(-1);
        invoiceList[0] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[0],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[1] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[1],
            new Map<String, Object>{ 'CreatedDate' => controlDate.addMonths(-2) }
        );

        Test.startTest();
        List<COMM_SubscriptionInvoice__c> parsedList = COMM_SL_SAPSendInvoiceHelper.obtainInvoiceForMonthList(
            controlDate,
            fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
            invoiceList,
            null,
            null
        );
        Test.stopTest();

        Assert.areEqual(1, parsedList.size(), 'expected list to only have one invoice record');
        Assert.areEqual(invoiceList[0], parsedList[0], 'parsed record doens\'t match expected');
    }

    @isTest
    static void obtainInvoiceForMonthListWithExemptionStaffTest() {
        //Scenario: 9 invoices for Staff Company Subscription were generated. Account has a ratio of 1.5.
        //Expected: 3 of the invoices are set for exemption of payment
        Product2 subProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.sObjectType),
                'COMM_SubCategory__c' => COMM_DO_Product2.SUBCATEGORY_STAFF_COMPANY
            }
        )[0];
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            9,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        Date controlDate = System.today();
        invoiceList[0] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[0],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[0].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[1] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[1],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[1].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[2] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[2],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[2].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[3] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[3],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[3].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[4] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[4],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[4].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[5] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[5],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[5].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[6] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[6],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[6].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[7] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[7],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[7].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[8] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[8],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[8].COMM_SubscriptonProduct__r = subProduct;

        Test.startTest();
        List<COMM_SubscriptionInvoice__c> parsedList = COMM_SL_SAPSendInvoiceHelper.obtainInvoiceForMonthList(
            controlDate,
            fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType),
            invoiceList,
            '2/3',
            null
        );
        Test.stopTest();

        Assert.areEqual(9, parsedList.size(), 'expected list to only have nine invoice record');
        Assert.isFalse(parsedList[0].COMM_ExemptPayment__c, 'expected invoice 1 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[1].COMM_ExemptPayment__c, 'expected invoice 2 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[2].COMM_ExemptPayment__c, 'expected invoice 3 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[3].COMM_ExemptPayment__c, 'expected invoice 4 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[4].COMM_ExemptPayment__c, 'expected invoice 5 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[5].COMM_ExemptPayment__c, 'expected invoice 6 to NOT be set as exempt from payment');
        Assert.isTrue(parsedList[6].COMM_ExemptPayment__c, 'expected invoice 7 to be set as exempt from payment');
        Assert.isTrue(parsedList[7].COMM_ExemptPayment__c, 'expected invoice 8 to be set as exempt from payment');
        Assert.isTrue(parsedList[8].COMM_ExemptPayment__c, 'expected invoice 9 to be set as exempt from payment');
    }

    @isTest
    static void obtainInvoiceForMonthListWithExemptionEntityTest() {
        //Scenario: 9 invoices for Official Entity Subscription were generated. Account has a ratio of 1.5.
        //Expected: 3 of the invoices are set for exemption of payment
        Product2 subProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.sObjectType),
                'COMM_SubCategory__c' => COMM_DO_Product2.SUBCATEGORY_OFFICIAL_ENTITY
            }
        )[0];
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            9,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        Date controlDate = System.today();
        invoiceList[0] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[0],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[0].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[1] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[1],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[1].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[2] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[2],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[2].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[3] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[3],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[3].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[4] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[4],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[4].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[5] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[5],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[5].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[6] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[6],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[6].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[7] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[7],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[7].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[8] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[8],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[8].COMM_SubscriptonProduct__r = subProduct;

        Test.startTest();
        List<COMM_SubscriptionInvoice__c> parsedList = COMM_SL_SAPSendInvoiceHelper.obtainInvoiceForMonthList(
            controlDate,
            fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
            invoiceList,
            null,
            '2/3'
        );
        Test.stopTest();

        Assert.areEqual(9, parsedList.size(), 'expected list to only have nine invoice record');
        Assert.isFalse(parsedList[0].COMM_ExemptPayment__c, 'expected invoice 1 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[1].COMM_ExemptPayment__c, 'expected invoice 2 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[2].COMM_ExemptPayment__c, 'expected invoice 3 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[3].COMM_ExemptPayment__c, 'expected invoice 4 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[4].COMM_ExemptPayment__c, 'expected invoice 5 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[5].COMM_ExemptPayment__c, 'expected invoice 6 to NOT be set as exempt from payment');
        Assert.isTrue(parsedList[6].COMM_ExemptPayment__c, 'expected invoice 7 to be set as exempt from payment');
        Assert.isTrue(parsedList[7].COMM_ExemptPayment__c, 'expected invoice 8 to be set as exempt from payment');
        Assert.isTrue(parsedList[8].COMM_ExemptPayment__c, 'expected invoice 9 to be set as exempt from payment');
    }

    @isTest
    static void obtainInvoiceForMonthListWithCourtesyTest() {
        //Scenario: 4 invoices for Courtesy Subscription were generated. Another 5 were generated wihtout being Courtesy.
        //Expected: Courtesy invoices are set for exemption of payment. The remaining 5 aren't.
        Product2 courtesySubProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Product2.sObjectType),
                'COMM_SubCategory__c' => COMM_DO_Product2.SUBCATEGORY_COURTESY
            }
        )[0];
        Product2 subProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(Product2.sObjectType), 'COMM_SubCategory__c' => null }
        )[0];
        COMM_Subscription__c courtesySub = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType),
                'COMM_PaymentMethod__c' => COMM_DO_Subscription.PAYMENT_COURTESY
            }
        )[0];
        COMM_Subscription__c nonCourtesySub = (COMM_Subscription__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_Subscription__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_Subscription__c.sObjectType), 'COMM_PaymentMethod__c' => null }
        )[0];
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            9,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        Date controlDate = System.today();
        invoiceList[0] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[0],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[0].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[0].COMM_Subscripton__r = nonCourtesySub;
        invoiceList[1] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[1],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[1].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[1].COMM_Subscripton__r = nonCourtesySub;
        invoiceList[2] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[2],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[2].COMM_SubscriptonProduct__r = courtesySubProduct;
        invoiceList[2].COMM_Subscripton__r = courtesySub;
        invoiceList[3] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[3],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[3].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[3].COMM_Subscripton__r = nonCourtesySub;
        invoiceList[4] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[4],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[4].COMM_SubscriptonProduct__r = courtesySubProduct;
        invoiceList[4].COMM_Subscripton__r = courtesySub;
        invoiceList[5] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[5],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[5].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[5].COMM_Subscripton__r = nonCourtesySub;
        invoiceList[6] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[6],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[6].COMM_SubscriptonProduct__r = courtesySubProduct;
        invoiceList[6].COMM_Subscripton__r = courtesySub;
        invoiceList[7] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[7],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[7].COMM_SubscriptonProduct__r = courtesySubProduct;
        invoiceList[7].COMM_Subscripton__r = courtesySub;
        invoiceList[8] = (COMM_SubscriptionInvoice__c) COMM_TestDataFactory.setField(
            invoiceList[8],
            new Map<String, Object>{ 'CreatedDate' => controlDate }
        );
        invoiceList[8].COMM_SubscriptonProduct__r = subProduct;
        invoiceList[8].COMM_Subscripton__r = nonCourtesySub;

        Test.startTest();
        List<COMM_SubscriptionInvoice__c> parsedList = COMM_SL_SAPSendInvoiceHelper.obtainInvoiceForMonthList(
            controlDate,
            fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType),
            invoiceList,
            null,
            '4/9'
        );
        Test.stopTest();

        Assert.areEqual(9, parsedList.size(), 'expected list to only have nine invoice record');
        Assert.isFalse(parsedList[0].COMM_ExemptPayment__c, 'expected invoice 1 to NOT be set as exempt from payment');
        Assert.isFalse(parsedList[1].COMM_ExemptPayment__c, 'expected invoice 2 to NOT be set as exempt from payment');
        Assert.isTrue(parsedList[2].COMM_ExemptPayment__c, 'expected invoice 3 to be set as exempt from payment');
        Assert.isFalse(parsedList[3].COMM_ExemptPayment__c, 'expected invoice 4 to NOT be set as exempt from payment');
        Assert.isTrue(parsedList[4].COMM_ExemptPayment__c, 'expected invoice 5 to be set as exempt from payment');
        Assert.isFalse(parsedList[5].COMM_ExemptPayment__c, 'expected invoice 6 to NOT be set as exempt from payment');
        Assert.isTrue(parsedList[6].COMM_ExemptPayment__c, 'expected invoice 7 to be set as exempt from payment');
        Assert.isTrue(parsedList[7].COMM_ExemptPayment__c, 'expected invoice 8 to be set as exempt from payment');
        Assert.isFalse(parsedList[8].COMM_ExemptPayment__c, 'expected invoice 9 to NOT be set as exempt from payment');
    }

    @isTest
    static void verifySAPResponseSuccessTest() {
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        COMM_SL_SAPDocumentResponse documentResponse = new COMM_SL_SAPDocumentResponse();
        documentResponse.documentId = 'testid';
        documentResponse.resultCode = COMM_SL_SAPSendInvoiceHelper.RESPONSE_STATUS_CODE_OK;
        documentResponse.resultDesc = 'doc success';

        COMM_MonthlyFiscalDocumentControl__c controlRecord = (COMM_MonthlyFiscalDocumentControl__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_MonthlyFiscalDocumentControl__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_RetryCounter__c' => 0
            }
        )[0];

        List<COMM_SubscriptionInvoice__c> invoiceToUpdateList = new List<COMM_SubscriptionInvoice__c>();

        Test.startTest();
        COMM_SL_SAPSendInvoiceHelper.verifySAPResponse(invoiceList, documentResponse, controlRecord, invoiceToUpdateList);
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_MonthlyFiscalDocumentControl.PROCESSED_STATUS,
            controlRecord.COMM_ProcessStatus__c,
            'expected control record\'s status to be updated to processed'
        );
        Assert.areEqual(
            documentResponse.documentId,
            controlRecord.COMM_SAPDocumentId__c,
            'expected control record\'s sap document id field to be updated'
        );
        Assert.areEqual(0, controlRecord.COMM_RetryCounter__c, 'expected control record\'s retry counter to not be updated');
        Assert.areEqual(
            documentResponse.documentId,
            invoiceToUpdateList[0].COMM_SAPNumber__c,
            'expected invoice record\'s sap number field to be updated'
        );
        Assert.areEqual(
            documentResponse.documentId,
            invoiceToUpdateList[1].COMM_SAPNumber__c,
            'expected invoice record\'s sap number field to be updated'
        );
    }

    @isTest
    static void verifySAPResponseFailureTest() {
        List<COMM_SubscriptionInvoice__c> invoiceList = (List<COMM_SubscriptionInvoice__c>) COMM_TestDataFactory.insertRecords(
            2,
            false,
            'COMM_SubscriptionInvoice__c',
            new Map<String, Object>{ 'Id' => fflib_IDGenerator.generate(COMM_SubscriptionInvoice__c.sObjectType) }
        );

        COMM_SL_SAPDocumentResponse documentResponse = new COMM_SL_SAPDocumentResponse();
        documentResponse.documentId = null;
        documentResponse.resultCode = '400';
        documentResponse.resultDesc = 'doc failed';

        COMM_MonthlyFiscalDocumentControl__c controlRecord = (COMM_MonthlyFiscalDocumentControl__c) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'COMM_MonthlyFiscalDocumentControl__c',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(COMM_MonthlyFiscalDocumentControl__c.sObjectType),
                'COMM_Account__c' => fflib_IDGenerator.generate(Account.sObjectType),
                'COMM_RetryCounter__c' => 0
            }
        )[0];

        List<COMM_SubscriptionInvoice__c> invoiceToUpdateList = new List<COMM_SubscriptionInvoice__c>();

        Test.startTest();
        COMM_SL_SAPSendInvoiceHelper.verifySAPResponse(invoiceList, documentResponse, controlRecord, invoiceToUpdateList);
        Test.stopTest();

        Assert.areEqual(
            COMM_DO_MonthlyFiscalDocumentControl.ERROR_STATUS,
            controlRecord.COMM_ProcessStatus__c,
            'expected control record\'s status to be updated to error'
        );
        Assert.areEqual(1, controlRecord.COMM_RetryCounter__c, 'expected control record\'s retry counter to be updated');
        Assert.isTrue(invoiceToUpdateList.isEmpty(), 'expected no invoice record to be updated');
    }
}