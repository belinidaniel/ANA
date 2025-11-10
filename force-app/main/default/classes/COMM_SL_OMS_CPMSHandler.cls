/**
 * @author Rui Salgado
 * @description Service for CPMS Communication
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Diogo Gonçalves  19/06/2024       ECOMM-1420 Create QR Code image
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class COMM_SL_OMS_CPMSHandler {
    private static final String CALLOUT_CPMS_CREATE_RESERVATION = 'CPMSCreateReservation';
    private static final String CALLOUT_CPMS_UPDATE_RESERVATION = 'CPMSUpdateReservation';
    private static final String CALLOUT_CPMS_CANCEL_RESERVATION = 'CPMSCancelReservation';
    private static final String CPMS_STAUTS_ERROR = 'Error';
    private static final String CPMS_STAUTS_CANCELLED = 'Cancelled';
    private static final String CPMS_STAUTS_RESERVED = 'Reserved';
    private static final String DEFAULT_CURRENCY = 'EUR';
    private static final String FAMILY = 'Parking';
    private static final String ORDER_ITEM_SUMMARY_STATUS_FULFILLED = 'Fulfilled';
    private static final String ORDER_ITEM_SUMMARY_STATUS_RETURNED = 'Returned';
    private static final String PE_MESSAGE = 'Communication with CPMS failed';
    private static final String PRODUCTYPE = 'Charge';
    private static final String SUCCESS = 'SUCCESS';
    private static final Integer CPMS_LAST_LOG_MAXSIZE = 255;

    private static COMM_IREP_CalloutSettingMdt calloutSettingsRep = new COMM_REP_CalloutSettingMdt();
    private static COMM_IREP_Invoice invoiceRep = new COMM_REP_Invoice();
    private static COMM_IREP_OrderItemSummary orderItemSummaryRep = new COMM_REP_OrderItemSummary();
    //private static COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();

    /**
     * @description Core action to invoke from FLOW
     * @param docIds List of invoice/creditMemo Ids to send to CPMS
     */
    @InvocableMethod(Category='CPMS' description='Sync CPMS Reservation by Invoice Id' label='Sync CPMS Reservation')
    public static void invocableMethod(List<Id> invoiceIds) {
        COMM_SL_OMS_CPMSHandler.doCall(invoiceIds);
    }

    /**
     * @description Worker method to do the CPMS callout to Mulesoft
     * @param invoiceIds List of invoice Ids to send to CPMS
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.CognitiveComplexity')
    @future(callout=true)
    public static void doCall(List<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            return;
        }
        Map<String, SObject> orderItemSummaryMap = new Map<String, SObject>();
        FW_ISObjectRep sObjectRep = new FW_SObjectRep();
        List<ProcessException> processExceptionsList = new List<ProcessException>();
        
        Map<Id, Boolean> newProcessExceptionsByInvoice = new Map<Id, Boolean>();
        Map<Id, Boolean> newProcessExceptionsByOrderSummary = new Map<Id, Boolean>();

        Boolean newProcessExceptions = false;
        Map<String, OrderSummary> orderSumaryMap = new Map<String, OrderSummary>();
        Id currentInvoiceId;
        try {
            List<Invoice> invoices = invoiceRep.getForCPMS(invoiceIds, FAMILY, PRODUCTYPE);
            List<Id> orderItemSummaryIds = new List<Id>();
            for (Invoice inv : invoices) {
                for (InvoiceLine invLine : inv.invoiceLines) {
                    orderItemSummaryIds.add(invLine.ReferenceEntityItemId);
                }
            }

            List<OrderItemSummary> orderItemSummaries = orderItemSummaryRep.getForCPMS(orderItemSummaryIds);
            orderItemSummaryMap = COMM_GEN_Utility.convertListToMap(orderItemSummaries, 'Id');

            COMM_OMS_CalloutSettings__mdt calloutConfiguration = new COMM_OMS_CalloutSettings__mdt();
                        
            for (Invoice invoice : invoices) {
                currentInvoiceId = invoice.Id;
                Map<String, List<COMM_OMS_CPMSReservationRequest>> invoiceRequests = buildInvoiceRequest(invoice, orderItemSummaryMap);
                for (String reservationCallout : invoiceRequests.keySet()) {
                    calloutConfiguration = calloutSettingsRep.getCalloutSetting(reservationCallout);
                    Map<String, String> headers = COMM_OMS_CalloutUtil.parseHeaders(calloutConfiguration.HTTP_Headers__c);
                    HttpResponse response = COMM_OMS_CalloutUtil.doCallout(
                        calloutConfiguration.Endpoint_Server__c + calloutConfiguration.Endpoint_URI__c,
                        calloutConfiguration.HTTP_Method__c,
                        headers,
                        // remove null fields from request
                        transformRequest(JSON.serialize(invoiceRequests.get(reservationCallout), true)),
                        calloutConfiguration.Timeout__c
                    );

                    if (response != null && response.getStatusCode() == COMM_OMS_Constants.HTTP_SUCCESS_CODE) {
                        String errorMessage = handleResponse(orderItemSummaryMap, response, reservationCallout);
                        if (errorMessage != '') {
                            // create a process exception linked to the Order Summary
                            processExceptionsList.add(
                                COMM_DO_ProcessExceptions.createProcessException(
                                    invoice.ReferenceEntity.Id,
                                    invoice.ReferenceEntity.Id,
                                    COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                                    COMM_DO_ProcessExceptions.SEV_HIGH,
                                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                                    PE_MESSAGE,
                                    errorMessage,
                                    COMM_DO_ProcessExceptions.NEW_S
                                )
                            );
                            processExceptionsList.add(
                                COMM_DO_ProcessExceptions.createProcessException(
                                    invoice.Id,
                                    null, 
                                    COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                                    COMM_DO_ProcessExceptions.SEV_HIGH,
                                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                                    PE_MESSAGE,
                                    errorMessage,
                                    COMM_DO_ProcessExceptions.NEW_S
                                )
                            );
                            newprocessExceptionsByInvoice.put(invoice.Id, true);
                            newProcessExceptionsByOrderSummary.put(invoice.ReferenceEntity.Id, true);
                        } else {
                            //Resolve previous Process exceptions for same Order Summary.
                            /*
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                                    invoice.ReferenceEntity.Id,
                                    invoice.ReferenceEntity.Id,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            processExceptionsList.addAll(
                                COMM_DO_ProcessExceptions.updateStatus(
                                    COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                                    invoice.Id,
                                    null,
                                    new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                                    COMM_DO_ProcessExceptions.RESOLVED
                                )
                            );
                            */
                        }
                    } else {
                        // create a process exception linked to the Order Summary
                        processExceptionsList.add(
                            COMM_DO_ProcessExceptions.createProcessException(
                                invoice.ReferenceEntity.Id,
                                invoice.ReferenceEntity.Id,
                                COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                                COMM_DO_ProcessExceptions.SEV_HIGH,
                                COMM_DO_ProcessExceptions.PRIO_HIGH,
                                PE_MESSAGE,
                                'Communication with CPMS failed with HTTP Status = ' + response.getStatusCode(),
                                COMM_DO_ProcessExceptions.NEW_S
                            )
                        );
                        newprocessExceptionsByInvoice.put(invoice.Id, true);
                        newProcessExceptionsByOrderSummary.put(invoice.ReferenceEntity.Id, true);
                    }
                }
            }
            currentInvoiceId = null;

            // Update Order Summary CPMS Status with the overall status of Order Product Summary CPMS Status
            orderSumaryMap = updateOrderSummaryStatusMap(orderItemSummaryMap);

            //Select ProcessExceptions to update and avoid duplications on the list
            Map<Id, ProcessException> processExceptionToUpdate = new Map<Id, ProcessException>();
            for (Invoice invoice : invoices) {
                //For all order summaries without new processExceptions, Resolve previous Process exceptions 
                if (!newProcessExceptionsByOrderSummary.containsKey(invoice.ReferenceEntity.Id)) {
                    List<ProcessException> lOrderPE = COMM_DO_ProcessExceptions.updateStatus(
                            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                            invoice.ReferenceEntity.Id,
                            invoice.ReferenceEntity.Id,
                            new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                            COMM_DO_ProcessExceptions.RESOLVED
                        );
                    for(ProcessException pe : lOrderPE){
                        if(!processExceptionToUpdate.containsKey(pe.Id)){
                            processExceptionToUpdate.put(pe.Id, pe);
                        }
                    }
                }

                //For all invoices without new processExceptions, Resolve previous Process exceptions 
                if (!newProcessExceptionsByInvoice.containsKey(invoice.Id)) {
                    List<ProcessException> lInvoicePE = COMM_DO_ProcessExceptions.updateStatus(
                            COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                            invoice.Id,
                            null,
                            new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                            COMM_DO_ProcessExceptions.RESOLVED
                        );
                    for(ProcessException pe : lInvoicePE){
                        if(!processExceptionToUpdate.containsKey(pe.Id)){
                            processExceptionToUpdate.put(pe.Id, pe);
                        }
                    }
                }
            }

            if(!processExceptionToUpdate.values().isEmpty()){
                processExceptionsList.addAll(processExceptionToUpdate.values());
            }

        } catch (Exception ex) {
            COMM_GEN_Utility.logError(
                ex,
                'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                'COMM_SL_OMS_CPMSHandler'
            );
            if(currentInvoiceId != null){
                processExceptionsList.add(
                    COMM_DO_ProcessExceptions.createProcessException(
                        currentInvoiceId,
                        null, // Order Summary Id
                        COMM_DO_ProcessExceptions.CPMS_CATEGORY,
                        COMM_DO_ProcessExceptions.SEV_HIGH,
                        COMM_DO_ProcessExceptions.PRIO_HIGH,
                        PE_MESSAGE,
                        'An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                        COMM_DO_ProcessExceptions.NEW_S
                    )
                );
            }
        } finally {
            if (!orderItemSummaryMap.isEmpty()) {
                sObjectRep.updateSObjects(orderItemSummaryMap.values());
            }
            if (!orderSumaryMap.isEmpty()) {
                sObjectRep.updateSObjects(orderSumaryMap.values());
            }
            if (!processExceptionsList.isEmpty()) {
                sObjectRep.upsertSObjects(processExceptionsList);
            }

            COMM_OMS_DatabaseUtil.commitChanges();
        }
    }

    /**
     * @description Converts "currencyCode" substring into "currency" for Mulesoft request
     *              Note: Salesforce does not allow to create variables with reserved word "currency"
     * @param requestBody String
     * @return String error message
     */
    private static String transformRequest(String requestBody) {
        return requestBody.replace('currencyCode', 'currency');
    }

    /**
     * @description Get an Order Summary Map with overall CPMS status from all order product summary lines
     * @param Map<String,OrderSummary> orderItemSummaryMap lines with each individual CPMS status
     * @return Map<String,OrderSummary> orderSummaryMap with CPMS status
     */
    private static Map<String, OrderSummary> updateOrderSummaryStatusMap(Map<String, SObject> orderItemSummaryMap) {
        Map<String, OrderSummary> orderSummaryMap = new Map<String, OrderSummary>();
        // Iterate through each order item summary
        for (OrderItemSummary itemSummary : (List<OrderItemSummary>) (orderItemSummaryMap.values())) {
            String statusConcatenated = itemSummary.COMM_CPMSStatus__c; // Initialize with the first status

            // Check if the order ID exists in the order summary map
            if (orderSummaryMap.containsKey(itemSummary.OrderSummaryId)) {
                OrderSummary summary = orderSummaryMap.get(itemSummary.OrderSummaryId);
                // Concatenate status if the order summary already exists and does not contain CPMSStatus
                if (!statusConcatenated.contains(summary.COMM_CPMSStatus__c)) {
                    statusConcatenated = summary.COMM_CPMSStatus__c + ';' + statusConcatenated;
                }
            }

            // Create or update the order summary with concatenated status
            OrderSummary summary = new OrderSummary();
            summary.Id = itemSummary.OrderSummaryId;
            summary.COMM_CPMSStatus__c = statusConcatenated;
            orderSummaryMap.put(summary.Id, summary);
        }
        return orderSummaryMap;
    }

    /**
     * @description Update input Map based on the HTTP Response
     * @param orderItemSummaryMap Map of Order Item Summaries indexed by CPMS reservation id
     * @param response Mulesoft HTTP response
     * @return String error message
     */
    private static String handleResponse(Map<String, SObject> orderItemSummaryMap, HttpResponse response, String reservationCallout) {
        // Response can be a list of errors
        String errorMessage = '';

        List<COMM_OMS_CPMSReservationResponse> responses = COMM_OMS_CPMSReservationResponse.parse(response.getBody());
        for (COMM_OMS_CPMSReservationResponse cpmsResponse : responses) {
            // cpmsResponse.reservationId == Order Item Summary Id
            OrderItemSummary ois = (OrderItemSummary) orderItemSummaryMap.get(cpmsResponse.reservationId);
            ois.COMM_CPMSLastLog__c = cpmsResponse.resultDesc?.left(CPMS_LAST_LOG_MAXSIZE);
            ois.COMM_ReservationIdCPMS__c = cpmsResponse.cpmsReservationId;
            if (cpmsResponse.resultCode <> SUCCESS) {
                errorMessage = errorMessage + ' ' + cpmsResponse.resultDesc?.left(CPMS_LAST_LOG_MAXSIZE);
                ois.COMM_CPMSStatus__c = CPMS_STAUTS_ERROR;
            } else {
                if (reservationCallout == CALLOUT_CPMS_CANCEL_RESERVATION) {
                    ois.COMM_CPMSStatus__c = CPMS_STAUTS_CANCELLED;
                } else {
                    ois.COMM_CPMSStatus__c = CPMS_STAUTS_RESERVED;
                    ois.COMM_BarcodeType__c = cpmsResponse.barcodeType;
                    ois.COMM_Barcode__c = cpmsResponse.barcodeString;
                    OIS.COMM_QRCodeImage__c = COMM_GEN_Utility.generateQRCodeImage(cpmsResponse.barcodeString);
                }
            }
        }
        return errorMessage;
    }

    /**
     * @description Build CPMS request based on the invoice
     * @param invoice Invoie Id
     * @param orderItemSummaryMap Map of Order Item Summaries indexed by OrderItemSummary Id
     * @return List<COMM_OMS_CPMSReservationRequest>
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.CognitiveComplexity')
    private static Map<String, List<COMM_OMS_CPMSReservationRequest>> buildInvoiceRequest(Invoice invoice, Map<String, SObject> orderItemSummaryMap) {
        Map<String, List<COMM_OMS_CPMSReservationRequest>> allRequests = new Map<String, List<COMM_OMS_CPMSReservationRequest>>();

        List<COMM_OMS_CPMSReservationRequest> createReservationRequestList = new List<COMM_OMS_CPMSReservationRequest>();
        List<COMM_OMS_CPMSReservationRequest> updateReservationRequestList = new List<COMM_OMS_CPMSReservationRequest>();
        List<COMM_OMS_CPMSReservationRequest> cancelReservationRequestList = new List<COMM_OMS_CPMSReservationRequest>();
        for (InvoiceLine invoiceLine : invoice.InvoiceLines) {
            COMM_OMS_CPMSReservationRequest request = new COMM_OMS_CPMSReservationRequest();
            OrderItemSummary orderItemSummary = (OrderItemSummary) orderItemSummaryMap.get(invoiceLine.ReferenceEntityItemId);
            if (orderItemSummary == null) {
                continue;
            }
            // No need to send request.CPMS ID as mulesfot will derive it from mappings
            request.reservationId = invoiceLine.ReferenceEntityItemId;
            request.cpmsReservationId = orderItemSummary.COMM_ReservationIdCPMS__c;
            request.aeroportId = invoiceLine.Product2.COMM_Airport__c.toUpperCase();
            request.carParkId = invoiceLine.Product2.COMM_Park__c;
            request.validFrom = orderItemSummary.COMM_ReservationStart__c;
            request.validTo = orderItemSummary.COMM_ReservationEnd__c;
            request.barcodeType = orderItemSummary.COMM_BarcodeType__c;
            request.barcodeString = orderItemSummary.COMM_Barcode__c;
            COMM_OMS_CPMSReservationRequest.Contact contact = new COMM_OMS_CPMSReservationRequest.Contact();
            // Split COMM_ReservationName__c
            contact.firstName = '';
            contact.lastName = '';
            if (orderItemSummary.COMM_ReservationName__c != null) {
                List<String> parts = orderItemSummary.COMM_ReservationName__c.split(' ');
                contact.firstName = parts[0];
                if (parts.size() > 1) {
                    contact.lastName = parts[parts.size() - 1];
                }
            }
            contact.email = orderItemSummary.OrderDeliveryGroupSummary.EmailAddress;
            contact.telephone = orderItemSummary.OrderDeliveryGroupSummary.PhoneNumber;
            request.contact = contact;
            COMM_OMS_CPMSReservationRequest.PrepaidFee prepaidFee = new COMM_OMS_CPMSReservationRequest.PrepaidFee();
            prepaidFee.amount = invoiceLine.ChargeAmountWithTax;
            prepaidFee.currencyCode = DEFAULT_CURRENCY;
            request.prepaidFee = prepaidFee;

            if (String.isBlank(orderItemSummary.COMM_ReservationIdCPMS__c)) {
                createReservationRequestList.add(request);
            } else {
                if (orderItemSummary.Status == ORDER_ITEM_SUMMARY_STATUS_FULFILLED) {
                    updateReservationRequestList.add(request);
                } else if (
                    orderItemSummary.Status == ORDER_ITEM_SUMMARY_STATUS_RETURNED &&
                    !String.isBlank(orderItemSummary.COMM_ReservationIdCPMS__c) &&
                    orderItemSummary.COMM_CPMSStatus__c != CPMS_STAUTS_CANCELLED
                ) {
                    cancelReservationRequestList.add(request);
                }
            }

            if (!createReservationRequestList.isEmpty()) {
                allRequests.put(CALLOUT_CPMS_CREATE_RESERVATION, createReservationRequestList);
            }
            if (!updateReservationRequestList.isEmpty()) {
                allRequests.put(CALLOUT_CPMS_UPDATE_RESERVATION, updateReservationRequestList);
            }
            if (!cancelReservationRequestList.isEmpty()) {
                allRequests.put(CALLOUT_CPMS_CANCEL_RESERVATION, cancelReservationRequestList);
            }
        }
        return allRequests;
    }
}