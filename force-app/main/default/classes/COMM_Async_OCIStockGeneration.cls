/**
 * @author Ruben Rodrigues
 * @description Batch class to generate Stock in OCI based on configurations in COMM_Capacity__c
 * Each product can have multiple configurations. All Product configurations need to be processed within the same thread.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues         11/03/2024		Original version
 * Jose Passos             16/04/2024		Handle errors on upload process
 * Jose Passos             10/05/2024       ECOMM-984 - Lock records before processing
 **/
public class COMM_Async_OCIStockGeneration extends FW_AsyncHandler implements Database.Batchable<SObject>, Database.Stateful {
    //batch framework parameters (used by the framework to pass values to the batch dynamically)
    @TestVisible
    private final static String PARAMETER_PRODLIST = 'ProductList';
    private final static String ERROR_UPLOADING = 'ConnectAPI Error on Upload: ';
    private final static List<String> STATUS_TO_PROCESS_LIST = new List<String>{
        COMM_OCI_Constants.PROCESS_STATUS_NOT_PROCESSED,
        COMM_OCI_Constants.PROCESS_STATUS_PENDING,
        COMM_OCI_Constants.PROCESS_STATUS_RUNNING
    };
    private final static List<String> PRODUCT_FAMILY_TO_PROCESS_LIST = new List<String>{
        COMM_OCI_Constants.PRODUCT_FAMILY_PARKING,
        COMM_OCI_Constants.PRODUCT_FAMILY_LOUNGE,
        COMM_OCI_Constants.PRODUCT_FAMILY_FAST_TRACK,
        COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION
    };

    private FW_ISObjectRep sObjectRep;
    private COMM_IREP_Capacity capacityRep;

    /**
     * @description Class Constructor to initialize REP class
     */
    public COMM_Async_OCIStockGeneration() {
        this.sObjectRep = new FW_SObjectRep();
        this.capacityRep = new COMM_REP_Capacity();
    }

    @testVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_Async_OCIStockGeneration(
        FW_ISObjectRep sObjectRep,
        COMM_IREP_Capacity capacityRep,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.sObjectRep = sObjectRep;
        this.capacityRep = capacityRep;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field has a date set a specific number of months ago.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());
        FW_QueryBuilder query;
        try {
            String objectName = 'Product2';
            SObjectType sobjType = Schema.getGlobalDescribe().get(objectName);
            String productCodesString = getParameterValue(PARAMETER_PRODLIST);
            if (productCodesString != null) {
                List<String> productCodeList = getParameterValue(PARAMETER_PRODLIST).split(',');
                query = new FW_QueryBuilder(sobjType)
                    .selectFields(new List<String>{ 'ProductCode' })
                    .whereIn('ProductCode', productCodeList)
                    .whereIn('Family', PRODUCT_FAMILY_TO_PROCESS_LIST)
                    .whereEquals('IsActive', true);
            } else {
                query = new FW_QueryBuilder(sobjType)
                    .selectFields(new List<String>{ 'ProductCode' })
                    .whereIn('Family', PRODUCT_FAMILY_TO_PROCESS_LIST)
                    .whereEquals('IsActive', true);
            }
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'Error on Start: ', 'COMM_Async_OCIStockGeneration');
        }
        return executeQuery(query);
    }

    /**
     * @description Batch Execute Method. Deletes the records obtained in the start method's query.
     *
     * @param bc Context Information of the executed batch
     * @param productsList List of Capacity records (distinct ProductCodes) that were obtained on the start method's query
     */
    @SuppressWarnings('PMD.CognitiveComplexity')
    public void execute(Database.BatchableContext bc, List<Product2> productsList) {
        // Add all product Codes into a List
        List<String> productList = new List<String>();
        for (Product2 product : productsList) {
            productList.add(product.ProductCode);
        }

        // Query all Capacity records to update stock (status is pending, running or not processed
        // This will have to be processed in order to ensure several configurations for the same Product
        // are processed in order
        List<COMM_Capacity__c> capacityToProcessList = capacityRep.getCapacityRecordsToProcessByProductCodes(productList, STATUS_TO_PROCESS_LIST);

        // Separate the records to upload from the ones to check the upload status
        Set<Id> idList = new Set<Id>();
        List<COMM_Capacity__c> capacityToUploadList = new List<COMM_Capacity__c>();
        List<COMM_Capacity__c> capacityToGetStatusList = new List<COMM_Capacity__c>();
        List<COMM_Capacity__c> capacityFinalList = new List<COMM_Capacity__c>();
        for (COMM_Capacity__c capacityRec : capacityToProcessList) {
            idList.add(capacityRec.id);
            if (capacityRec.COMM_ProcessStatus__c == COMM_OCI_Constants.PROCESS_STATUS_NOT_PROCESSED) {
                capacityToUploadList.add(capacityRec);
            } else {
                capacityToGetStatusList.add(capacityRec);
            }
        }

        // Lock records
        capacityRep.lockCapacityRecords(idList);

        // Call Upload stock
        if (!capacityToUploadList.isEmpty()) {
            capacityToUploadList = doUpload(capacityToUploadList);
            for (COMM_Capacity__c capacityRec : capacityToUploadList) {
                if (String.isBlank(capacityRec.COMM_ProcessId__c)) {
                    capacityFinalList.add(capacityRec);
                } else {
                    capacityToGetStatusList.add(capacityRec);
                }
            }
        }

        // Get Upload status from the upload job IDs for the current and previous uploads
        if (!capacityToGetStatusList.isEmpty()) {
            capacityToGetStatusList = getUploadStatus(capacityToGetStatusList);
            capacityFinalList.addAll(capacityToGetStatusList);
        }

        // update processed capacity records with JobId, Status and Status Message
        if (!capacityFinalList.isEmpty()) {
            capacityRep.updateSObjects(capacityFinalList);
        }
    }

    /**
     * @description Receives a list of capacity records to update stock position and returns
     * the list updated with the jobId
     *
     * @param capacityListInput List of Capacity records to upload/update Stock position in OCI
     * @return List<COMM_Capacity__c> List of Capacity records updated with the upload Job Id
     */
    public List<COMM_Capacity__c> doUpload(List<COMM_Capacity__c> capacityListInput) {
        COMM_SL_OCIStockGeneration stockUploadService = new COMM_SL_OCIStockGeneration();
        List<COMM_Capacity__c> capacityListOutput = new List<COMM_Capacity__c>();

        // Call upload service with the list of capacity records
        ConnectApi.OCIUploadInventoryAvailabilityOutputRepresentation output;
        output = stockUploadService.uploadStock(capacityListInput);

        // handle Error response
        String errors = ERROR_UPLOADING;
        if (!output.success) {
            for (ConnectApi.ErrorResponse error : output.errors) {
                errors = errors + ' ' + error.message;
            }
        }

        for (COMM_Capacity__c capacityRec : capacityListInput) {
            capacityRec.COMM_ProcessId__c = output.uploadId;
            capacityRec.COMM_StatusMessage__c = errors;
            capacityListOutput.add(capacityRec);
        }
        return capacityListOutput;
    }

    /**
     * @description Receives a list of capacity records to get the process upload job status
     *
     * @param capacityListInput List of Capacity records to upload/update Stock position in OCI
     * @return List<COMM_Capacity__c> List of Capacity records updated with the upload status and message
     */
    public List<COMM_Capacity__c> getUploadStatus(List<COMM_Capacity__c> capacityListInput) {
        COMM_SL_OCIStockGeneration stockUploadService = new COMM_SL_OCIStockGeneration();
        List<COMM_Capacity__c> capacityListOutput = new List<COMM_Capacity__c>();

        List<String> errorMessageList;
        String previousJobId = '-1';
        String previousStatus;
        String previousStatusMessage;

        for (COMM_Capacity__c capacityRec : capacityListInput) {
            errorMessageList = new List<String>();
            if (previousJobId != capacityRec.COMM_ProcessId__c) {
                previousJobId = capacityRec.COMM_ProcessId__c;
                previousStatus = stockUploadService.getJobIdStatus(previousJobId, errorMessageList);
                if (!errorMessageList.isEmpty()) {
                    previousStatusMessage = String.join(errorMessageList, ',');
                }
            }
            capacityRec.COMM_ProcessId__c = previousJobId;
            capacityRec.COMM_ProcessStatus__c = previousStatus;
            capacityRec.COMM_StatusMessage__c = previousStatusMessage;
            capacityListOutput.add(capacityRec);
        }

        return capacityListOutput;
    }

    /**
     * @description Batch Finish Method. Initiates the Framework batch finished process.
     *
     * @param bc Context Information of the executed batch
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}