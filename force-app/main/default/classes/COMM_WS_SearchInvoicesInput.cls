/**
 * @author Hugo Manera
 * @description Descrição da classe
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Hugo Manera      27/05/2025      Original version
 **/

global class COMM_WS_SearchInvoicesInput {
    global String accountId;
    global Integer page;
    global Integer pageSize;
    global Date invoiceStartDate;
    global Date invoiceEndDate;
    global String invoiceNumber;
    global String orderNumber;
    global String sapDocumentId;
    global List<String> status;
    global String invoiceExtraFilter;

    public static COMM_WS_SearchInvoicesInput parse(String json) {
        return (COMM_WS_SearchInvoicesInput) System.JSON.deserialize(json, COMM_WS_SearchInvoicesInput.class);
    }

    private static final String INVALID_INVOICEDATE_PARAMETER_ERROR = 'When \'invoiceStartDate\' or \'invoiceEndDate\' are set, both parameters are required!';
    private static final String INVALID_INVOICESTARTDATE_PARAMETER_ERROR = '\'invoiceStartDate\' must be equal or greater than \'invoiceEndDate\'!';

    /**
     * @description Check Input request exceptions.
     * @param  COMM_WS_SearchInvoicesInput inputRequest - Input request received
     */
    public static void checkInputRequestRules(COMM_WS_SearchInvoicesInput inputRequest) {
        // Validate date parameters
        if (
            (inputRequest.invoiceStartDate == null && inputRequest.invoiceEndDate != null) ||
            (inputRequest.invoiceStartDate != null &&
            inputRequest.invoiceEndDate == null)
        ) {
            throw new COMM_SL_WS_SearchCustomerInvoicesException(INVALID_INVOICEDATE_PARAMETER_ERROR);
        }

        // Check date range validity with null safety
        if (
            inputRequest.invoiceStartDate != null &&
            inputRequest.invoiceEndDate != null &&
            inputRequest.invoiceStartDate > inputRequest.invoiceEndDate
        ) {
            throw new COMM_SL_WS_SearchCustomerInvoicesException(INVALID_INVOICESTARTDATE_PARAMETER_ERROR);
        }

        // Security validations
        validateInputSecurity(inputRequest);
    }

    /**
     * @description Validate input parameters for security issues
     * @param inputRequest The input request to validate
     */
    private static void validateInputSecurity(COMM_WS_SearchInvoicesInput inputRequest) {
        // Validate invoice number for potential injection attempts
        if (String.isNotBlank(inputRequest.invoiceNumber)) {
            if (containsSqlInjectionPatterns(inputRequest.invoiceNumber)) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Invalid invoice number format');
            }
            // Limit length to prevent buffer overflow attacks
            if (inputRequest.invoiceNumber.length() > 255) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Invoice number exceeds maximum length');
            }
        }

        if (String.isBlank(inputRequest.sapDocumentId)) {
            if (containsSqlInjectionPatterns(inputRequest.sapDocumentId)) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Invalid SAP document ID format');
            }
        }

        // Validate order number for potential injection attempts
        if (String.isNotBlank(inputRequest.orderNumber)) {
            if (containsSqlInjectionPatterns(inputRequest.orderNumber)) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Invalid order number format');
            }
            if (inputRequest.orderNumber.length() > 255) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Order number exceeds maximum length');
            }
        }

        // Validate status values
        if (inputRequest.status != null && !inputRequest.status.isEmpty()) {
            for (String status : inputRequest.status) {
                if (String.isNotBlank(status)) {
                    if (containsSqlInjectionPatterns(status)) {
                        throw new COMM_SL_WS_SearchCustomerInvoicesException('Invalid status format');
                    }
                }
            }
        }

        if (String.isNotBlank(inputRequest.invoiceExtraFilter)) {
            if (containsSqlInjectionPatterns(inputRequest.invoiceExtraFilter)) {
                throw new COMM_SL_WS_SearchCustomerInvoicesException('Invalid invoice extra filter format');
            }
        }

        // Validate pagination parameters
        if (inputRequest.page != null && inputRequest.page < 0) {
            throw new COMM_SL_WS_SearchCustomerInvoicesException('Page number cannot be negative');
        }
    }

    /**
     * @description Check for common SQL injection patterns
     * @param input The input string to check
     * @return True if suspicious patterns are found
     */
    private static Boolean containsSqlInjectionPatterns(String input) {
        if (String.isBlank(input)) {
            return false;
        }

        String lowerInput = input.toLowerCase();
        List<String> suspiciousPatterns = new List<String>{
            'union',
            'select',
            'insert',
            'update',
            'delete',
            'drop',
            'create',
            'alter',
            'exec',
            'execute',
            'sp_',
            'xp_',
            '--',
            '/*',
            '*/',
            ';',
            'script',
            'javascript',
            'vbscript',
            'onload',
            'onerror'
        };

        for (String pattern : suspiciousPatterns) {
            if (lowerInput.contains(pattern)) {
                return true;
            }
        }

        // Check for encoded attempts
        if (lowerInput.contains('%') || lowerInput.contains('\\x') || lowerInput.contains('\\u')) {
            return true;
        }

        return false;
    }

    /**
     * @description Salesforce adapter exception
     */
    public class COMM_SL_WS_SearchCustomerInvoicesException extends Exception {
    }
}