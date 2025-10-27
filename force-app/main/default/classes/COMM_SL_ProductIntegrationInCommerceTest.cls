/**
 * @author Carlos Fusco
 * @description COMM_HttpCallout_Utility test class
 *
 * Modification Log
 * -----------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco     19/03/2024		100            Original version
 * Daniel Lascas    24/03/2024		95             ECOMM-803: Updated tests for new logic
 * Daniel Lascas    01/07/2024		99             ECOMM-1598: Updated tests
 **/
@isTest
private class COMM_SL_ProductIntegrationInCommerceTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_SL_VerifyAvailabilityAndPricing GET_PRICING_SL = (COMM_SL_VerifyAvailabilityAndPricing) MOCKS.mock(
        COMM_SL_VerifyAvailabilityAndPricing.class
    );
    private static final Map<String, Object> HTTP_REQUEST_JSON_BODY = new Map<String, Object>{
        'id' => 'PARK-LC-00001',
        'name' => 'Low Cost Parking',
        'short_description' => 'Parking Low Cost',
        'long_description' => 'Parking for a Low Cost',
        'tax_class_id' => 'Continente',
        'valid_from' => '2024-04-25 09:00:00',
        'valid_to' => '2024-04-25 23:59:59',
        'c_coreSubCategory' => 'Terminal',
        'c_soldInStore' => 'LIS',
        'c_requiresAirportStaff' => 'true',
        'c_externalPricing' => 'false',
        'online_flag' => 'true',
        'c_Family' => 'Parking',
        'c_externalAvailability' => 'false',
        'c_timeToTerminal' => '15',
        'c_productFeature' => 'reserved space under roof',
        'brand' => 'P0',
        'c_offerType' => 'Economy'
    };

    /**
     * @description Mock class for HTTP Callouts
     */
    public class HttpResponseMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('Success');
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Mock class for unsuccessfull HTTP Callout Response
     */
    public class HttpResponseFailureMock implements HttpCalloutMock {
        /**
         * @description Method to setup HTTP Callout response mock
         *
         * @param request HTTP request for mock
         * @return mock HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('Failure');
            response.setStatusCode(400);
            return response;
        }
    }

    @isTest
    static void getProductsIntegratedInCommerceTest() {
        //Scenario: Product is set for integration with Commerce
        //Expected: Product returned as integrated
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => false,
                'COMM_AvailabilityDeterminedInCore__c' => true,
                'COMM_PriceDeterminedInCore__c' => true
            }
        );

        //Mock Get Pricing Method
        MOCKS.startStubbing();
        ((COMM_SL_VerifyAvailabilityAndPricing) MOCKS.doAnswer(new VerifyAvailabilityPricingMock(), GET_PRICING_SL))
            .verifyProductHasPricingAndAvailableByCode(
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject()
            );
        MOCKS.stopStubbing();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD
        );
        Test.stopTest();

        Assert.isFalse(integratedProducts.isEmpty(), 'Products list should not be empty');
        Assert.isTrue(integratedProducts.get(0).COMM_IsIntegratedInCommerce__c, 'Product COMM_IsIntegratedInCommerce__c should be true');
    }

    @isTest
    static void productUpdateSuccessTest() {
        //Scenario: Product that was previously set for integration with Commerce has update to be sent.
        //Expected: Product returned as updated.
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => true,
                'COMM_HasUpdateForCommerce__c' => true,
                'COMM_AvailabilityDeterminedInCore__c' => false,
                'COMM_PriceDeterminedInCore__c' => false
            }
        );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PATCH_METHOD
        );
        Test.stopTest();

        Assert.isFalse(integratedProducts.isEmpty(), 'Products list should not be empty');
        Assert.isFalse(integratedProducts.get(0).COMM_HasUpdateForCommerce__c, 'Product COMM_HasUpdateForCommerce__c should be false');
    }

    @isTest
    static void getProductsIntegratedInCommerceFailureTest() {
        //Scenario: Product is set for integration. Commerce returns error message.
        //Expected: Product isn't integrated and Error Log Record is Generated
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => false,
                'COMM_AvailabilityDeterminedInCore__c' => true,
                'COMM_PriceDeterminedInCore__c' => true
            }
        );

        //Mock Get Pricing Method
        MOCKS.startStubbing();
        ((COMM_SL_VerifyAvailabilityAndPricing) MOCKS.doAnswer(new VerifyAvailabilityPricingMock(), GET_PRICING_SL))
            .verifyProductHasPricingAndAvailableByCode(
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject()
            );
        MOCKS.stopStubbing();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseFailureMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD
        );
        Test.stopTest();

        Assert.isTrue(integratedProducts.isEmpty(), 'Products list should be empty');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been created');
    }

    @isTest
    static void makeCommerceHttpCalloutTest() {
        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => true
            }
        );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce();
        HTTPResponse httpResponse = productIntegrationInCommerce.makeCommerceHttpCallout(
            (Product2) products.get(0),
            COMM_HttpCallout_Utility.HTTP_PATCH_METHOD
        );
        Test.stopTest();

        Assert.areEqual(200, httpResponse.getStatusCode(), 'HTTP Response status code should be 200');
        Assert.areEqual('Success', httpResponse.getBody(), 'HTTP Response body should be Success');
    }

    @isTest
    static void setProductIntegrationHttpRequestBodyTest() {
        Test.startTest();
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce();
        String httpRequestBody = productIntegrationInCommerce.setProductIntegrationHttpRequestBody(
            JSON.serialize(HTTP_REQUEST_JSON_BODY),
            COMM_HttpCallout_Utility.HTTP_PATCH_METHOD
        );

        Test.stopTest();
        Assert.isFalse(String.isBlank(httpRequestBody), 'HTTP Request Body should not be empty');
        Assert.isTrue(httpRequestBody.contains('short_description'), 'HTTP Request Body should contain short_description as a key');
    }

    @isTest
    static void productMissingFieldsTest() {
        //Scenario: Integration is done for a Product that has missing required fields
        //Expected: Product isn't integrated and a error log record is generated

        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'Family' => COMM_DO_Product2.CATEGORY_SUBSCRIPTION,
                'COMM_IntegrationRequestBody__c' => '{}',
                'COMM_IsIntegratedInCommerce__c' => false
            }
        );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD
        );
        Test.stopTest();

        Assert.isTrue(integratedProducts.isEmpty(), 'Products list should be empty');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been created');
    }

    @isTest
    static void productMissingPricingTest() {
        //Scenario: Integration is done for a Product that has Pricing Missing
        //Expected: Product isn't integrated and a error log record is generated

        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'Family' => COMM_DO_Product2.CATEGORY_PARKING,
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => false,
                'COMM_AvailabilityDeterminedInCore__c' => true,
                'COMM_PriceDeterminedInCore__c' => true
            }
        );

        //Mock Get Pricing Method
        MOCKS.startStubbing();
        ((COMM_SL_VerifyAvailabilityAndPricing) MOCKS.doAnswer(new MissingPricingMock(), GET_PRICING_SL))
            .verifyProductHasPricingAndAvailableByCode(
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject()
            );
        MOCKS.stopStubbing();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD
        );
        Test.stopTest();

        Assert.isTrue(integratedProducts.isEmpty(), 'Products list should be empty');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been created');
    }

    @isTest
    static void productMissingAvailabilityTest() {
        //Scenario: Integration is done for a Product that isn't Available
        //Expected: Product isn't integrated and a error log record is generated

        List<Object> products = COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Product2',
            new Map<String, Object>{
                'ProductCode' => 'PARK-LC-00001',
                'COMM_IntegrationRequestBody__c' => JSON.serialize(HTTP_REQUEST_JSON_BODY),
                'COMM_IsIntegratedInCommerce__c' => false,
                'COMM_AvailabilityDeterminedInCore__c' => true,
                'COMM_PriceDeterminedInCore__c' => true
            }
        );

        //Mock Get Pricing Method
        MOCKS.startStubbing();
        ((COMM_SL_VerifyAvailabilityAndPricing) MOCKS.doAnswer(new NoAvailabilityMock(), GET_PRICING_SL))
            .verifyProductHasPricingAndAvailableByCode(
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject(),
                (Set<String>) fflib_Match.anyObject()
            );
        MOCKS.stopStubbing();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpResponseMock());
        COMM_SL_ProductIntegrationInCommerce productIntegrationInCommerce = new COMM_SL_ProductIntegrationInCommerce(GET_PRICING_SL);
        List<Product2> integratedProducts = productIntegrationInCommerce.getProductsIntegratedInCommerce(
            (List<Product2>) products,
            COMM_HttpCallout_Utility.HTTP_PUT_METHOD
        );
        Test.stopTest();

        Assert.isTrue(integratedProducts.isEmpty(), 'Products list should be empty');
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'expected an error log to have been created');
    }

    /**
     * @description Mock SL Class that verifies availability and pricing using fflib_Answer
     */
    private class VerifyAvailabilityPricingMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            Set<String> availabilitySet = (Set<String>) invocation.getArgument(1);
            Set<String> pricingSet = (Set<String>) invocation.getArgument(2);
            availabilitySet.add('PARK-LC-00001');
            pricingSet.add('PARK-LC-00001');
            return new Set<String>{ 'PARK-LC-00001' };
        }
    }

    /**
     * @description Mock SL Class that verifies availability and pricing using fflib_Answer
     * Returns Product has missing Pricing
     */
    private class MissingPricingMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            Set<String> availabilitySet = (Set<String>) invocation.getArgument(1);
            availabilitySet.add('PARK-LC-00001');
            return new Set<String>();
        }
    }

    /**
     * @description Mock SL Class that verifies availability and pricing using fflib_Answer
     * Returns Product isn't available
     */
    private class NoAvailabilityMock implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            Set<String> pricingSet = (Set<String>) invocation.getArgument(2);
            pricingSet.add('PARK-LC-00001');
            return new Set<String>();
        }
    }
}