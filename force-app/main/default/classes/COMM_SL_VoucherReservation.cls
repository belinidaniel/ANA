/**
 * @author           Diogo Gonçalves
 * @description      Service class to handle Voucher Reservations for Fast-track and lounges
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    01/04/2024     ECOMM-105: Original version
 **/

public without sharing class COMM_SL_VoucherReservation {
    private static final List<String> PRODUCT_FAMILIES = new List<String>{ 'Fast Track', 'Lounge' };
    private static final String ENTITY_ITEM_TYPE = 'Order Product';
    private static final String PNG_FILE_TYPE = 'img/png';
    private static final FW_ISObjectRep SOBJECT_REPO = new FW_SObjectRep();
    private static final String QR_CODE_VALUE_ERR_MESSAGE = 'QR Code value was not generated. Check the product SubCategory, Airport and Reservation Date.';
    private static final String QR_CODE_IMG_ERR_MESSAGE = 'QR Code image was not create.';
    private static final String PROCESS_EXCEPTION_MESSAGE = 'Error creating the voucher QR Codes';

    private static List<ProcessException> exceptions = new List<ProcessException>();

    /**
     * @description: method to create reservation vouchers on Order Item Summary records,
     * @param {list<Id>} invoiceIds
     */
    @InvocableMethod(
        category='OMS'
        label='Create Reservation Vouchers'
        description='Create Reservation References (lounge and fast-track) on Order Product Summaries to be used in the QR Codes'
    )
    public static List<String> createReservationVouchers(List<String> invoiceIds) {
        //Set object repositories
        List<String> successList = new List<String>{ 'false' };
        COMM_IREP_InvoiceLine invoiceLineRep = new COMM_REP_InvoiceLine();
        COMM_IREP_OrderItemSummary itemSummaryRep = new COMM_REP_OrderItemSummary();

        //fetch corresponding order item summaries
        List<InvoiceLine> invoicesLines = invoiceLineRep.getInvoiceLinesByFamilyAndType(invoiceIds, PRODUCT_FAMILIES, ENTITY_ITEM_TYPE);
        List<String> orderItemSummaryIds = COMM_GEN_Utility.getTextFieldValues(invoicesLines, 'ReferenceEntityItemId');
        List<OrderItemSummary> orderItemSummaries = itemSummaryRep.getOrderItemSummariesById(orderItemSummaryIds);

        try {
            List<OrderItemSummary> toUpdate = setReservationVoucherCodes(orderItemSummaries);
            resolveProcessExceptions(orderItemSummaries);
            if (!toUpdate.isEmpty()) {
                invoiceLineRep.updateSObjects(orderItemSummaries);
                successList.set(0, 'true');
            }
            if (!exceptions.isEmpty()) {
                SOBJECT_REPO.insertSObjects(exceptions);
                successList.set(0, 'false');
            }
        } catch (Exception e) {
            createProcessExceptions(e, orderItemSummaries);
            successList.set(0, 'false');
        } finally {
            COMM_OMS_DatabaseUtil.commitChanges();
        }
        return successList;
    }

    /**
     * @description: Method to set voucher codes on order item summary records
     * @param {list<OrderItemSummary>} orderItemSummaries
     * @return {list<OrderItemSummary>}
     */
    private static List<OrderItemSummary> setReservationVoucherCodes(List<OrderItemSummary> orderItemSummaries) {
        List<OrderItemSummary> updatedRecords = new List<orderItemSummary>();
        for (OrderItemSummary ois : OrderItemSummaries) {
            try {
                setQRCode(ois);
                updatedRecords.add(ois);
            } catch (Exception e) {
                String errorMessage = e.getMessage() + '; COMM_SL_SendVouchersEmail: line: ' + e.getLineNumber();
                exceptions.add(createProcessException(e.getMessage(), ois));
            }
        }
        return updatedRecords;
    }

    /**
     * @description Set the QR Code value and image on the OrderItemSummary
     * @param orderItemSummary
     * @return {OrderItemSummary}
     */
    private static void setQRCode(OrderItemSummary ois) {
        String qrCode = COMM_GEN_Utility.generateQRCodeValue(
            ois.Product2.Family,
            ois.Product2.COMM_SubCategory__c,
            ois.Product2.COMM_Airport__c,
            ois.COMM_ReservationStart__c,
            ois.COMM_TimeZoneByAirport__c
        );
        if (String.isBlank(qrCode)) {
            throw new COMM_SL_CreateVoucherException(QR_CODE_VALUE_ERR_MESSAGE);
        }

        ois.COMM_QRCode__c = qrCode;
        ois.COMM_QRCodeImage__c = COMM_GEN_Utility.generateQRCodeImage(ois.COMM_QRCode__c);

        if (String.isBlank(ois.COMM_QRCodeImage__c)) {
            throw new COMM_SL_CreateVoucherException(QR_CODE_IMG_ERR_MESSAGE);
        }
    }

    /**
     * @description Create a process exception for the order item summary with the given description
     * @param {string} description
     * @param {Id} orderSummaryId
     * @return {ProcessException}
     */
    private static void createProcessExceptions(Exception e, List<OrderItemSummary> summaries) {
        List<ProcessException> exceptions = new List<ProcessException>();
        String errorMessage = e.getMessage() + '; COMM_SL_SendVouchersEmail: line: ' + e.getLineNumber();

        for (OrderItemSummary ois : summaries) {
            exceptions.add(createProcessException(errorMessage, ois));
        }

        if (!exceptions.isEmpty()) {
            SOBJECT_REPO.insertSObjects(exceptions);
        }
    }

    /**
     * @description Create a process exception for the order item summary with the given description
     * @param {string} description
     * @param {Id} orderSummaryId
     * @return {ProcessException}
     */
    private static ProcessException createProcessException(String description, OrderItemSummary ois) {
        return COMM_DO_ProcessExceptions.createProcessException(
            ois.Id,
            ois.OrderSummaryId,
            COMM_DO_ProcessExceptions.QR_CODE_CATEGORY,
            COMM_DO_ProcessExceptions.SEV_HIGH,
            COMM_DO_ProcessExceptions.PRIO_HIGH,
            PROCESS_EXCEPTION_MESSAGE,
            description,
            COMM_DO_ProcessExceptions.NEW_S
        );
    }

    /**
     * @description resolve the process exceptions related with the given order item summaries
     * @param orderItemSummaries
     * @return void
     */
    private static void resolveProcessExceptions(List<OrderItemSummary> orderItemSummaries) {
        Map<Id, OrderItemSummary> orderItemSummariesById = new Map<Id, OrderItemSummary>(orderItemSummaries);
        List<Id> orderItemSummaryIds = new List<Id>(orderItemSummariesById.keySet());
        List<String> statusFilter = new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED };
        List<ProcessException> exceptionsToUpdate = COMM_DO_ProcessExceptions.resolveByAttached(
            COMM_DO_ProcessExceptions.QR_CODE_CATEGORY,
            orderItemSummaryIds,
            statusFilter
        );
        if (!exceptionsToUpdate.isEmpty()) {
            SOBJECT_REPO.updateSObjects(exceptionsToUpdate);
        }
    }
}