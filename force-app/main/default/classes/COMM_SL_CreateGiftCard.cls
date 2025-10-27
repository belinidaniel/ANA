/**
 * @author           Diogo Gonçalves
 * @description      Class with an invocable method to create a Gift Cards
 *                   Performs callout to SFCC
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  19/04/2024      Original version
 * Diogo Gonçalves  17/09/2024      ECOMM-481: Changed the API endpoint
 */
public inherited sharing class COMM_SL_CreateGiftCard {
    private static final List<String> PRODUCT_FAMILIES = new List<String>{ COMM_DO_Product2.CATEGORY_GIFTCARD };
    private static final String ENTITY_ITEM_TYPE = 'Order Product';
    private static final String ISSUED_STATUS = 'issued';

    /**
     * @description      Invocable method to create Gift Cards.
     * @param {List<Id>}    invoiceIds     List of Invoices ids that have Gift Card to create
     * @return void
     */
    @InvocableMethod(label='Create Gift Card in SFCC' description='Creates Gift Card in SFCC' callout=true category='OMS')
    public static void createGiftCard(List<Id> invoiceIds) {
        List<ProcessException> processExceptionsList = new List<ProcessException>();
        if (invoiceIds.isEmpty()) {
            return;
        }
        try {
            //Get gift cars OrderItemSummary objects
            COMM_IREP_InvoiceLine invoiceLineRep = new COMM_REP_InvoiceLine();
            COMM_IREP_OrderItemSummary itemSummaryRep = new COMM_REP_OrderItemSummary();
            List<InvoiceLine> invoicesLines = invoiceLineRep.getInvoiceLinesByFamilyAndType(invoiceIds, PRODUCT_FAMILIES, ENTITY_ITEM_TYPE);
            List<String> orderItemSummaryIds = COMM_GEN_Utility.getTextFieldValues(invoicesLines, 'ReferenceEntityItemId');
            List<OrderItemSummary> orderItemSummaries = itemSummaryRep.getForGiftCard(orderItemSummaryIds);

            try {
                if (!orderItemSummaries.isEmpty()) {
                    //Generate Gift Card Wrapper
                    COMM_SL_GiftCertificateWrapper giftCertificateWrapper = getGiftCertificateWrapper(orderItemSummaries);
                    //Resolve previous Process exceptions for same Order Summary.
                    processExceptionsList.addAll(
                        COMM_DO_ProcessExceptions.updateStatus(
                            COMM_DO_ProcessExceptions.GIFTCARD_CATEGORY,
                            orderItemSummaries[0].Id,
                            orderItemSummaries[0].OrderSummaryId,
                            new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                            COMM_DO_ProcessExceptions.RESOLVED
                        )
                    );
                    processExceptionsList.addAll(
                        COMM_DO_ProcessExceptions.updateStatus(
                            COMM_DO_ProcessExceptions.GIFTCARD_CATEGORY,
                            invoiceIds[0],
                            null,
                            new List<String>{ COMM_DO_ProcessExceptions.NEW_S, COMM_DO_ProcessExceptions.TRIAGED },
                            COMM_DO_ProcessExceptions.RESOLVED
                        )
                    );
                    // send callout to create a Gift Card in OCAPI
                    COMM_SL_SCAPI.createGiftCertificates(giftCertificateWrapper);
                }
            } catch (Exception ex) {
                processExceptionsList.add(
                    COMM_DO_ProcessExceptions.createProcessException(
                        orderItemSummaries[0].Id, //attachedToId
                        orderItemSummaries[0].OrderSummaryId, // Order Summary Id
                        COMM_DO_ProcessExceptions.GIFTCARD_CATEGORY,
                        COMM_DO_ProcessExceptions.SEV_HIGH,
                        COMM_DO_ProcessExceptions.PRIO_HIGH,
                        'Communication with SCAPI failed',
                        'GiftCard - An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                        COMM_DO_ProcessExceptions.NEW_S
                    )
                );
            }
        } catch (Exception ex) {
            processExceptionsList.add(
                COMM_DO_ProcessExceptions.createProcessException(
                    invoiceIds[0], //attachedToId
                    null, // Order Summary Id
                    COMM_DO_ProcessExceptions.GIFTCARD_CATEGORY,
                    COMM_DO_ProcessExceptions.SEV_HIGH,
                    COMM_DO_ProcessExceptions.PRIO_HIGH,
                    'Gift Card - Error on creation',
                    'GiftCard - An error occurred while doing callout: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString(),
                    COMM_DO_ProcessExceptions.NEW_S
                )
            );
        } finally {
            //Insert process exception records
            if (!processExceptionsList.isEmpty()) {
                FW_ISObjectRep sObjectRep = new FW_SObjectRep();
                sObjectRep.upsertSObjects(processExceptionsList);
            }
            //Inserts OMS logs, created in COMM_OMS_CalloutUtil to database
            COMM_OMS_DatabaseUtil.commitChanges();
        }
    }

    /**
     * @description Get the wrapper with the gift certificates to create
     * @param {List<OrderItemSummary>} orderItemSummaries List of Order Item Summaries
     * @return {COMM_SL_GiftCertificateWrapper}
     */
    private static COMM_SL_GiftCertificateWrapper getGiftCertificateWrapper(List<OrderItemSummary> orderItemSummaries) {
        COMM_SL_GiftCertificateWrapper giftCertificateWrapper = new COMM_SL_GiftCertificateWrapper();

        for (OrderItemSummary orderItemSummary : orderItemSummaries) {
            COMM_SL_GiftCertificateWrapper.GiftCertificate giftCertificate = new COMM_SL_GiftCertificateWrapper.GiftCertificate();

            giftCertificate.amount = orderItemSummary.TotalAmtWithTax;
            giftCertificate.orderNumber = orderItemSummary.OrderSummary.OrderNumber;
            giftCertificate.description = orderItemSummary.Product2.Description;
            giftCertificate.recipientName = orderItemSummary.OrderSummary.Account.Name;
            giftCertificate.recipientEmail = orderItemSummary.OrderDeliveryGroupSummary.EmailAddress;
            giftCertificate.senderName = COMM_OMS_Constants.ANA_AEROPORTOS;
            giftCertificate.sendEmail = true;
            for (Integer i = 0; i < orderItemSummary.Quantity; i++) {
                giftCertificateWrapper.addGiftCertificate(giftCertificate); //TODO are we going to send multiple emails to the recipient?
            }
        }
        return giftCertificateWrapper;
    }
}