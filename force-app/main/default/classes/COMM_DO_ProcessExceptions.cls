/**
 * @author Rui Salgado
 * @description Domain class to handle Process Exceptions objects
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Diogo Gonçalves  10/05/2024       ECOMM-133: Added resolveByOrderSummaries and resolveByAttached
 **/

public with sharing class COMM_DO_ProcessExceptions {
    // Categories
    public static final String CPMS_CATEGORY = 'CPMS';
    public static final String VOUCHER_CATEGORY = 'Voucher Email';
    public static final String QR_CODE_CATEGORY = 'QR Code';
    public static final String SAP_CATEGORY = 'SAP';
    public static final String GIFTCARD_CATEGORY = 'Gift Card';

    // Priority
    public static final String PRIO_HIGH = 'High';
    public static final String PRIO_LOW = 'Low';

    // Severity
    public static final String SEV_HIGH = 'High';
    public static final String SEV_LOW = 'Low';

    // Status
    public static final String VOIDED = 'Voided';
    public static final String PAUSED = 'Paused';
    public static final String TRIAGED = 'Triaged';
    public static final String NEW_S = 'New';
    public static final String RESOLVED = 'Resolved';
    public static final String IGNORED = 'Ignored';

    //Repo
    private static final COMM_IREP_ProcessExceptions PROCESS_EXCEPTION_REPO = new COMM_REP_ProcessExceptions();

    /**
     * Create a process exception
     * @param attachedTo
     * @param OrderSummaryId
     * @param category
     * @param severity
     * @param priority
     * @param message
     * @param description
     * @param status
     * @return  `ProcessException`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static ProcessException createProcessException(
        String attachedTo,
        String orderSummaryId,
        String category,
        String severity,
        String priority,
        String message,
        String description,
        String status
    ) {
        ProcessException processException = new ProcessException();
        processException.AttachedToId = attachedTo;
        if (String.isNotBlank(orderSummaryId)) {
            processException.OrderSummaryId = orderSummaryId;
        }
        processException.Category = category;
        processException.Severity = severity;
        processException.Priority = priority;
        processException.Message = message;
        processException.Description = description;
        processException.Status = status;

        return processException;
    }

    /**
     * Update status a process exception
     * @param category
     * @param attachedTo
     * @param OrderSummaryId
     * @param oldStatus
     * @param newStatus
     * @return  `ProcessException`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<ProcessException> updateStatus(
        String category,
        String attachedTo,
        String orderSummaryId,
        List<String> oldStatus,
        String newStatus
    ) {
        COMM_REP_ProcessExceptions repProcessExceptions = new COMM_REP_ProcessExceptions();
        List<ProcessException> previousExceptions = repProcessExceptions.getByCategoryAttachedStatus(category, attachedTo, orderSummaryId, oldStatus);

        for (ProcessException pe : previousExceptions) {
            pe.status = newStatus;
        }
        return previousExceptions;
    }

    /**
     * Update status a process exception
     * @param category
     * @param attachedTo
     * @param OrderSummaryId
     * @param oldStatus
     * @param newStatus
     * @return  `ProcessException`
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<ProcessException> updateStatusBulk(
        String category,
        Set<String> attachedToSet,
        Set<String> orderSummaryIdSet,
        List<String> oldStatus,
        String newStatus
    ) {
        COMM_REP_ProcessExceptions repProcessExceptions = new COMM_REP_ProcessExceptions();
        List<ProcessException> previousExceptions = repProcessExceptions.getByCategoryAttachedStatusBulk(category, attachedToSet, orderSummaryIdSet, oldStatus);

        for (ProcessException pe : previousExceptions) {
            pe.status = newStatus;
        }
        return previousExceptions;
    }

    /**
     * Update process exceptions status from a list of OrderSummaries
     * NOTE: Ignores attachedTo field
     * @param category
     * @param OrderSummaryId
     * @param oldStatus
     * @return  `ProcessException`
     */
    public static List<ProcessException> resolveByOrderSummaries(String category, List<String> orderSummaryIds, List<String> oldStatus) {
        List<ProcessException> previousExceptions = PROCESS_EXCEPTION_REPO.getByOrderSummary(category, orderSummaryIds, oldStatus);

        for (ProcessException pe : previousExceptions) {
            pe.status = RESOLVED;
        }
        return previousExceptions;
    }

    /**
     * Update process exceptions status from a list of attached ids
     * @param category
     * @param OrderSummaryId
     * @param oldStatus
     * @return  `ProcessException`
     */
    public static List<ProcessException> resolveByAttached(String category, List<String> attatchedIds, List<String> oldStatus) {
        List<ProcessException> previousExceptions = PROCESS_EXCEPTION_REPO.getByAttatched(category, attatchedIds, oldStatus);

        for (ProcessException pe : previousExceptions) {
            pe.status = RESOLVED;
        }
        return previousExceptions;
    }
}