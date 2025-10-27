/**
 * @author Daniel Lascas
 * @description Queuable class to send an OCAPI request to
 * Commerce to update Customer Data
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer         Date          Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas     12/06/2024    Original version
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class COMM_Async_UpdateCustomerInCommQueuable implements Queueable {
    private List<Id> sobjectIdsList;
    private String sobjectName;

    //Max number of Accounts Processed per Future method
    //Limit is impossed due to Queuable and Future having a 100 callout limit (each Record might require multiple callouts)
    private final static Integer MAX_LIMIT = 20;

    //Custom Metadata Setting with Callouts
    private static final COMM_CalloutSetting__mdt CUSTOMER_SEARCH_CALLOUT = COMM_CalloutSetting__mdt.getInstance('CustomerSearch');
    private static final COMM_CalloutSetting__mdt CUSTOMER_UPDATE_CALLOUT = COMM_CalloutSetting__mdt.getInstance('CustomerUpdate');
    private static final COMM_CalloutSetting__mdt CUSTOMER_ADDRESS_UPDATE_CALLOUT = COMM_CalloutSetting__mdt.getInstance('CustomerAddressUpdate');
    private static final COMM_CalloutSetting__mdt CUSTOMER_ADDRESS_CREATE_CALLOUT = COMM_CalloutSetting__mdt.getInstance('CustomerAddressCreate');
    private static final String CUSTOMER_LIST_ID = COMM_CommerceConfiguration__mdt.getInstance('DefaultCustomerList').COMM_Value__c;
    private static final String BILLING_ADDRESS_ID = COMM_CommerceConfiguration__mdt.getInstance('BillingAddressId').COMM_Value__c;
    private static final String BILLING_COMPANY_ADDRESS_ID = COMM_CommerceConfiguration__mdt.getInstance('BillingCompanyAddressId').COMM_Value__c;

    //Body of the Request to be used in Search Endpoint. Used to query Customers by their email.
    private static final String SEARCH_QUERY_BODY_START =
        '{"select":"(count,hits.(data.(customer_no,c_externalAccountId,c_comm_contactId)))"' +
        ', "query":{"text_query":{"fields":["email"], "search_phrase":"';
    private static final String SEARCH_QUERY_BODY_END = '"}}}';

    @TestVisible
    private static final String NOT_FOUND_ERROR_STATUS = 'Not Found';
    @TestVisible
    private static final Integer NOT_FOUND_ERROR_CODE = 404;

    //Salesforce Fields API Name
    private static final String CONTACT_EMAIL_FIELD_NAME = String.valueOf(Contact.Email);
    private static final String PERSON_ACCOUNT_EMAIL_FIELD_NAME = String.valueOf(Account.PersonEmail);
    private static final String PERSON_CONTACT_ID_FIELD_NAME = String.valueOf(Account.PersonContactId);
    private static final String IS_PERSON_ACCCOUNT_FIELD_NAME = String.valueOf(Account.IsPersonAccount);
    private static final String CUSTOMER_NUMBER_FIELD_NAME = String.valueOf(Contact.COMM_CustomerNumber__c);
    private static final String PERSON_CUSTOMER_NUMBER_FIELD_NAME = String.valueOf(Account.COMM_CustomerNumber__pc);
    private static final String REQUEST_BODY_API_FIELD_NAME = String.valueOf(Account.COMM_IntegrationRequestBody__c);

    //Required Fields in Address Request
    private static final String ADDRESS_ID_FIELD = 'address_id';
    private static final String LAST_NAME_FIELD = 'last_name';
    private static final String COUNTRY_CODE_FIELD = 'country_code';
    private static final String EMPTY_VALUE = '';

    //Messages for Error Logging
    private static final String UPDATE_CALLOUT_ERROR = ' update callout returned error: ';
    private static final String SEARCH_CALLOUT_ERROR = ' search callout returned error: ';
    private static final String EXCEPTION_THROWN_ERROR = ' exception caught during future method';
    private static final String NO_REQUEST_BODY_ERROR = ' record doesn\'t have body to send to Commerce';
    private static final String UPDATE_BILLING_CALLOUT_ERROR = ' update billing address callout returned error: ';
    private static final String UPDATE_COMPANY_BILLING_CALLOUT_ERROR = ' update company billing address callout returned error: ';
    private static final String SEARCH_CALLOUT_CUSTOMER_NOT_FOUND_ERROR = ' search callout did not find customer: ';

    /**
     * @description Queuable Constructor to receive parameters
     *
     * @param sobjectIdsList List of Salesforce Records Ids whose data will be sent to Commerce
     * @param sobjectName Name of the SObject the Ids belong to
     */
    public COMM_Async_UpdateCustomerInCommQueuable(List<Id> sobjectIdsList, String sobjectName) {
        this.sobjectIdsList = sobjectIdsList;
        this.sobjectName = sobjectName;
    }

    /**
     * @description Method to execute Queuable class.
     * Due to governance limits queuable splits account to update into future methods to perform callouts.
     *
     * @param context Queuable context
     */
    public void execute(QueueableContext context) {
        List<Set<Id>> idsList = new List<Set<Id>>();
        Set<Id> idSet = new Set<Id>();
        for (Id recordId : sobjectIdsList) {
            idSet.add(recordId);
            //Verify if current Accounts to process pass MAX limit
            if (idSet.size() >= MAX_LIMIT) {
                idsList.add(idSet);
                idSet = new Set<Id>();
            }
        }
        //Add remaining accounts to process
        if (!idSet.isEmpty()) {
            idsList.add(idSet);
        }
        //Send callouts
        for (Set<Id> recordIds : idsList) {
            sendUpdateCallout(recordIds, sobjectName);
        }
    }

    /**
     * @description Send callout to Commerce (using OCAPI) to update customer data
     *
     * @param accountIds List of Record Ids to send update data
     * @param sobjectName API Name of the SObject the Id's belong to
     */
    @future(callout=true)
    private static void sendUpdateCallout(Set<Id> recordIds, String sobjectName) {
        if (String.valueOf(Contact.sObjectType).equals(sobjectName)) {
            COMM_REP_Contact contactRep = new COMM_REP_Contact();
            List<Contact> contactList = contactRep.getContactWithRequestFieldsByIds(recordIds);
            processRecords(contactList, true);
        } else {
            COMM_REP_Account accountRep = new COMM_REP_Account();
            List<Account> accountList = accountRep.getAccountWithRequestFieldsByIds(recordIds);
            processRecords(accountList, false);
        }
    }

    /**
     * @description Process List of Records
     * @param recordList List of Salesforce Records to sync with Commerce
     * @param isContact Boolean indicating that records are Contact (True) or Account (False)
     */
    private static void processRecords(List<SObject> recordList, Boolean isContact) {
        try {
            FW_SObjectRep sobjectRep = new FW_SObjectRep();
            List<SObject> recordUpdateList = new List<SObject>();
            for (SObject salesforceRecord : recordList) {
                //Verify if Record has a request body to send
                if (salesforceRecord.get(REQUEST_BODY_API_FIELD_NAME) == null) {
                    logError(salesforceRecord.Id, NO_REQUEST_BODY_ERROR);
                    continue;
                }

                //Verify if Record is a Business Account (B2B)
                if (!isContact && !Boolean.valueOf(salesforceRecord.get(IS_PERSON_ACCCOUNT_FIELD_NAME))) {
                    verifyBusinessAccount((Account) salesforceRecord, recordUpdateList);
                } else {
                    verifyCustomer(salesforceRecord, isContact, recordUpdateList, null);
                }
            }
            if (!recordUpdateList.isEmpty()) {
                sobjectRep.updateSObjects(recordUpdateList);
            }
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, EXCEPTION_THROWN_ERROR, 'COMM_Async_UpdateCustomerInCommQueuable');
        }
    }

    /**
     * @description Method to send Customer data to Commerce
     * @param salesforceRecord Salesforce Record with Customer Data
     * @param isContact Boolean indicating if Records is Contact (True) or Account (False)
     * @param recordUpdateList List of Records to be updated in Salesforce
     * @param parentRequestBody Body of Request when Update is for a Parent Record (ex: Affiliate Account Update for every Customer associated with Account)
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void verifyCustomer(SObject salesforceRecord, Boolean isContact, List<SObject> recordUpdateList, String parentRequestBody) {
        String customerNumberField = isContact ? CUSTOMER_NUMBER_FIELD_NAME : PERSON_CUSTOMER_NUMBER_FIELD_NAME;
        //Verify if Record has Customer Number (Commerce Id). If not then perform search callout to obtain it.
        if (!verifyCustomerNumber(salesforceRecord, isContact, recordUpdateList)) {
            return;
        }

        //Extract Customer Number from Salesforce Record
        String customerNumber = (String) salesforceRecord.get(customerNumberField);

        //Extract Update Request and split into Personal Data, Billing Data and Company Billing Data
        Map<String, Object> updateRequestMap = (Map<String, Object>) JSON.deserializeUntyped(
            String.isBlank(parentRequestBody) ? (String) salesforceRecord.get(REQUEST_BODY_API_FIELD_NAME) : parentRequestBody
        );
        Map<String, Object> billingMap = (Map<String, Object>) updateRequestMap.get(BILLING_ADDRESS_ID);
        updateRequestMap.remove(BILLING_ADDRESS_ID);
        Map<String, Object> billingCompanyMap = (Map<String, Object>) updateRequestMap.get(BILLING_COMPANY_ADDRESS_ID);
        updateRequestMap.remove(BILLING_COMPANY_ADDRESS_ID);

        //Update Customer Personal Data if Request contains data after removing address data
        if (!updateRequestMap.isEmpty()) {
            HttpResponse updateResponse = makeUpdateHttpCallout(customerNumber, JSON.serialize(updateRequestMap));
            //Log Error if Response from Commerce is Error
            if (!COMM_HttpCallout_Utility.isHttpResponseSuccesfull(updateResponse)) {
                logError(salesforceRecord.Id, UPDATE_CALLOUT_ERROR + updateResponse.getBody());
                return;
            }
        }

        //Update Billing Address if Request contains address data
        if (billingMap != null && !billingMap.isEmpty()) {
            //Add Address Id
            billingMap.put(ADDRESS_ID_FIELD, BILLING_ADDRESS_ID);
            //Verify if required Country Code or Last Name are null.
            //If they are then convert to empty string since null isn't a valid value.
            if (!billingMap.containsKey(LAST_NAME_FIELD) || billingMap.get(LAST_NAME_FIELD) == null) {
                billingMap.put(LAST_NAME_FIELD, EMPTY_VALUE);
            }
            if (!billingMap.containsKey(COUNTRY_CODE_FIELD) || billingMap.get(COUNTRY_CODE_FIELD) == null) {
                billingMap.put(COUNTRY_CODE_FIELD, EMPTY_VALUE);
            }
            //Send Update Callout and check if success
            HttpResponse billingAddressUpdateResponse = makeAddressUpdateHttpCallout(customerNumber, BILLING_ADDRESS_ID, JSON.serialize(billingMap)); //Log Error if Response from Commerce is Error
            if (!COMM_HttpCallout_Utility.isHttpResponseSuccesfull(billingAddressUpdateResponse)) {
                logError(salesforceRecord.Id, UPDATE_BILLING_CALLOUT_ERROR + billingAddressUpdateResponse.getBody());
            }
        }

        //Update Company Billing Address if Request contains address data
        if (billingCompanyMap != null && !billingCompanyMap.isEmpty()) {
            //Add Address Id and empty Last Name (required for update call)
            billingCompanyMap.put(ADDRESS_ID_FIELD, BILLING_COMPANY_ADDRESS_ID);
            billingCompanyMap.put(LAST_NAME_FIELD, EMPTY_VALUE);
            //Verify if required Country Code is null. If it is then convert to empty string since null isn't a valid value.
            if (!billingCompanyMap.containsKey(COUNTRY_CODE_FIELD) || billingCompanyMap.get(COUNTRY_CODE_FIELD) == null) {
                billingCompanyMap.put(COUNTRY_CODE_FIELD, EMPTY_VALUE);
            }
            //Send Update Callout and check if success
            HttpResponse companyAddressUpdateResponse = makeAddressUpdateHttpCallout(
                customerNumber,
                BILLING_COMPANY_ADDRESS_ID,
                JSON.serialize(billingCompanyMap)
            );
            //Log Error if Response from Commerce is Error
            if (!COMM_HttpCallout_Utility.isHttpResponseSuccesfull(companyAddressUpdateResponse)) {
                logError(salesforceRecord.Id, UPDATE_COMPANY_BILLING_CALLOUT_ERROR + companyAddressUpdateResponse.getBody());
            }
        }
    }

    /**
     * @description Verify if Customer Number (Identifier in Commerce) is filled in Salesforce. If not perform callout to obtain from Commerce and update record.
     * @param salesforceRecord Salesforce Record with Customer Data
     * @param isContact Boolean indicating if Records is Contact (True) or Account (False)
     * @param recordUpdateList List of Records to be updated in Salesforce
     * @return Boolean indicating if Record has Customer Number (True) or is missing (False)
     */
    private static Boolean verifyCustomerNumber(SObject salesforceRecord, Boolean isContact, List<SObject> recordUpdateList) {
        String customerNumberField = isContact ? CUSTOMER_NUMBER_FIELD_NAME : PERSON_CUSTOMER_NUMBER_FIELD_NAME;
        if (salesforceRecord.get(customerNumberField) == null) {
            //Call Service to Search for Customer in Commerce and obtain Customer Number
            searchCustomer(
                salesforceRecord,
                isContact ? (String) salesforceRecord.get(CONTACT_EMAIL_FIELD_NAME) : (String) salesforceRecord.get(PERSON_ACCOUNT_EMAIL_FIELD_NAME),
                isContact
            );
            //Verify if Record instance was updated with Customer Number
            if (salesforceRecord.get(customerNumberField) == null) {
                return false;
            } else {
                //Set Record for Update to add Customer Number
                recordUpdateList.add(
                    isContact
                        ? (SObject) new Contact(Id = salesforceRecord.Id, COMM_CustomerNumber__c = (String) salesforceRecord.get(customerNumberField))
                        : (SObject) new Account(
                              Id = salesforceRecord.Id,
                              COMM_CustomerNumber__pc = (String) salesforceRecord.get(customerNumberField)
                          )
                );
            }
        }
        return true;
    }

    /**
     * @description Verify for a B2B Account all Customers associated with it and call method to send address update to all.
     *
     * @param accountRecord B2B Account to process
     * @param recordUpdateList List of Records to be updated in Salesforce
     */
    private static void verifyBusinessAccount(Account accountRecord, List<SObject> recordUpdateList) {
        //Send Update Calls to Contacts related to Account
        for (Contact contactRecord : accountRecord.Contacts) {
            verifyCustomer(contactRecord, true, recordUpdateList, accountRecord.COMM_IntegrationRequestBody__c);
        }
    }

    /**
     * @description Method to make callout to search endpoint to retrieve Customer Number
     *
     * @param customerRecord Salesforce Record where Customer Number found will be stored
     * @param customerEmail Email of the Customer used in search
     * @param isContact Boolean indicating if record is a Contact (True) or Account (False)
     */
    private static void searchCustomer(SObject customerRecord, String customerEmail, Boolean isContact) {
        HttpResponse getResponse = makeSearchHttpCallout(customerEmail);

        //Log Error if Response from Commerce is Error
        if (!COMM_HttpCallout_Utility.isHttpResponseSuccesfull(getResponse)) {
            logError(customerRecord.Id, SEARCH_CALLOUT_ERROR + getResponse.getBody());
            return;
        }

        //Verify if Search found Customer
        SearchCustomerResponse searchResponse = (SearchCustomerResponse) JSON.deserialize(getResponse.getBody(), SearchCustomerResponse.class);
        if (searchResponse.count > 0) {
            for (SearchCustomerHits customerFound : searchResponse.hits) {
                //Verify that Customer Found's Contact Id matches Salesforce Contact Id
                String contactId = isContact ? customerRecord.Id : (String) customerRecord.get(PERSON_CONTACT_ID_FIELD_NAME);
                if (contactId.equals(customerFound.data?.c_comm_contactId)) {
                    customerRecord.put(isContact ? CUSTOMER_NUMBER_FIELD_NAME : PERSON_CUSTOMER_NUMBER_FIELD_NAME, customerFound.data.customer_no);
                    return;
                }
            }
        }
        logError(customerRecord.Id, SEARCH_CALLOUT_CUSTOMER_NOT_FOUND_ERROR + getResponse.getBody());
    }

    /**
     * @description Perform HTTP Callout to Commerce against Customer (update)
     *
     * @param customerId Id of the Customer in Commerce
     * @param requestBody JSON with the callout body
     * @return HTTPResponse with the result of HTTP callout request to Commerce
     */
    private static HTTPResponse makeUpdateHttpCallout(String customerId, String requestBody) {
        String commerceEndpoint =
            CUSTOMER_UPDATE_CALLOUT.COMM_NamedCredential__c +
            String.format(CUSTOMER_UPDATE_CALLOUT.COMM_Path__c, new List<Object>{ CUSTOMER_LIST_ID });
        return COMM_HttpCallout_Utility.httpPatchCallout(
            commerceEndpoint + customerId,
            new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
            requestBody
        );
    }

    /**
     * @description Perform HTTP Callout to Commerce against Customer (Search)
     *
     * @param customerEmail Email of the Customer
     * @return HTTPResponse with the result of HTTP callout request to Commerce
     */
    private static HTTPResponse makeSearchHttpCallout(String customerEmail) {
        String commerceEndpoint =
            CUSTOMER_SEARCH_CALLOUT.COMM_NamedCredential__c +
            String.format(CUSTOMER_SEARCH_CALLOUT.COMM_Path__c, new List<Object>{ CUSTOMER_LIST_ID });
        String requestBody = SEARCH_QUERY_BODY_START + customerEmail + SEARCH_QUERY_BODY_END;

        return COMM_HttpCallout_Utility.httpPostCallout(
            commerceEndpoint,
            new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
            requestBody
        );
    }

    /**
     * @description Perform HTTP Callout to Commerce to update Customer Address.
     * If callout fails due to Address not existing then a callout to create it is sent after.
     *
     * @param customerId Id of the Customer in Commerce
     * @param addressId Id of the Address to update in Commerce
     * @param requestBody JSON with the callout body
     * @return HTTPResponse with the result of HTTP callout request to Commerce
     */
    private static HTTPResponse makeAddressUpdateHttpCallout(String customerId, String addressId, String requestBody) {
        String commerceEndpoint =
            CUSTOMER_ADDRESS_UPDATE_CALLOUT.COMM_NamedCredential__c +
            String.format(CUSTOMER_ADDRESS_UPDATE_CALLOUT.COMM_Path__c, new List<Object>{ CUSTOMER_LIST_ID, customerId });
        HttpResponse calloutResponse = COMM_HttpCallout_Utility.httpPatchCallout(
            commerceEndpoint + addressId,
            new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
            requestBody
        );

        //If Update Fails due to Address not existing, send create callout
        if (calloutResponse.getStatusCode() == NOT_FOUND_ERROR_CODE && NOT_FOUND_ERROR_STATUS.equals(calloutResponse.getStatus())) {
            String createEndpoint =
                CUSTOMER_ADDRESS_CREATE_CALLOUT.COMM_NamedCredential__c +
                String.format(CUSTOMER_ADDRESS_CREATE_CALLOUT.COMM_Path__c, new List<Object>{ CUSTOMER_LIST_ID, customerId });
            calloutResponse = COMM_HttpCallout_Utility.httpPostCallout(
                createEndpoint,
                new Map<String, String>{ COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE => COMM_HttpCallout_Utility.HEADER_CONTENT_TYPE_JSON },
                requestBody
            );
        }
        return calloutResponse;
    }

    /**
     * @description Method to log error related to Callout Service
     *
     * @param recordId Id of the Record that was being processed
     * @param errorMessage Message to add to Error Log to be generated
     */
    private static void logError(String recordId, String errorMessage) {
        COMM_HttpCallout_Utility.CalloutServiceException ex = new COMM_HttpCallout_Utility.CalloutServiceException('Record Id: ' + recordId);
        COMM_GEN_Utility.logError(ex, errorMessage, 'COMM_Async_UpdateCustomerInCommQueuable');
    }

    /**
     * @description Class that represents the Response received from the Search Customer API
     * Object that contains number of customers found that match query and list with data
     */
    private class SearchCustomerResponse {
        public Integer count;
        public List<SearchCustomerHits> hits;
    }
    /**
     * @description Class that represents the Response received from the Search Customer API
     * Object that contains search hits (customers whose data matches query)
     */
    private class SearchCustomerHits {
        public SearchCustomerData data;
    }
    /**
     * @description Class that represents the Response received from the Search Customer API.
     * Object that contains Customer Data (ex: customer number, external account id).
     */
    @SuppressWarnings('PMD.FieldNamingConventions')
    private class SearchCustomerData {
        public String customer_no;
        public String c_comm_contactId;
    }
}