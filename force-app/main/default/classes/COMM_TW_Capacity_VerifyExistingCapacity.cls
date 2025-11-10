/**
 * @author Daniel Lascas
 * @description Trigger worker that checks if a Capacity Record with the same
 * Product and interceting Valid Dates exists.
 * If it does throw a Validation Error.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024		Original version
 **/
public class COMM_TW_Capacity_VerifyExistingCapacity {
    private COMM_IREP_Capacity capacityRep;

    /**
     * @description Class Constructor to initiate REP Classes
     */
    public COMM_TW_Capacity_VerifyExistingCapacity() {
        this.capacityRep = new COMM_REP_Capacity();
    }

    @TestVisible
    private COMM_TW_Capacity_VerifyExistingCapacity(COMM_IREP_Capacity capacityRep) {
        this.capacityRep = capacityRep;
    }

    /**
     * @description Execute Trigger Worker Logic
     *
     * @param newCapacityList List with the Capacity Records in New Context
     * @param oldCapacityMap Map with the Capacity Records in Old Context
     */
    public void execute(List<COMM_Capacity__c> newCapacityList, Map<Id, COMM_Capacity__c> oldCapacityMap) {
        //Sets and Map to store new record values
        Map<Id, List<COMM_Capacity__c>> productWithCapacityMap = new Map<Id, List<COMM_Capacity__c>>();
        Set<Id> capacityToIgnoreIdSet = new Set<Id>();

        //Check if new record require checking for existing records (if Product or Valid Values changed)
        //For Default Capacity, the check is skipped
        for (COMM_Capacity__c newCapacity : newCapacityList) {
            if (
                !newCapacity.COMM_IsDefaultCapacity__c &&
                (COMM_GEN_Utility.isChangedField(newCapacity, oldCapacityMap, COMM_Capacity__c.COMM_ValidFrom__c) ||
                COMM_GEN_Utility.isChangedField(newCapacity, oldCapacityMap, COMM_Capacity__c.COMM_ValidTo__c) ||
                COMM_GEN_Utility.isChangedField(newCapacity, oldCapacityMap, COMM_Capacity__c.COMM_Product__c))
            ) {
                processNewRecords(newCapacity, productWithCapacityMap, capacityToIgnoreIdSet);
            }
        }
        if (!productWithCapacityMap.isEmpty()) {
            capacityToIgnoreIdSet.remove(null);
            existingCapacityCheck(productWithCapacityMap, capacityToIgnoreIdSet);
        }
    }

    /**
     * @description Process new records. Checks if the Valid Dates among the new records have overlap among them.
     * If they do add error message and skips them from further processing.
     *
     * @param newCapacity Record to check dates against other processed records
     * @param productWithCapacityMap Map with already processed record (Key = Capacity's Product Id)
     * @param capacityToIgnoreIdSet Set with Ids of the new records to be processed (to filter query done later, value will be null in case of insert or in case of update if record is to be skipped)
     */
    private void processNewRecords(
        COMM_Capacity__c newCapacity,
        Map<Id, List<COMM_Capacity__c>> productWithCapacityMap,
        Set<Id> capacityToIgnoreIdSet
    ) {
        Id productId = newCapacity.COMM_Product__c;
        if (productWithCapacityMap.containsKey(productId)) {
            Boolean foundExisting = false;
            for (COMM_Capacity__c processedCapacity : productWithCapacityMap.get(productId)) {
                foundExisting = checkExistingDate(newCapacity, processedCapacity);
                if (foundExisting) {
                    break;
                }
            }
            //If an existing record was found among the new records then add error message and skip to next record
            if (foundExisting) {
                newCapacity.addError(System.Label.COMM_CAPACITY_ALREADY_EXISTS);
                return;
            } else {
                productWithCapacityMap.get(productId).add(newCapacity);
            }
        } else {
            productWithCapacityMap.put(productId, new List<COMM_Capacity__c>{ newCapacity });
        }
        capacityToIgnoreIdSet.add(newCapacity.Id);
    }

    /**
     * @description Check if newly created/updated Capacity Records dates coincide with existing record dates
     *
     * @param capacityRecord Record to check dates against another record (ex: new record)
     * @param capacityToCheckAgainst Record that is being checked against (ex: existing record)
     * @return True if record's Valid Dates cross each other, false otherwise
     */
    private Boolean checkExistingDate(COMM_Capacity__c capacityRecord, COMM_Capacity__c capacityToCheckAgainst) {
        //Check if Record Date is inside existing record date
        //First Check to see if new Record dates are inside existing record dates
        //Second Check to see if existing record dates are inside the new Record dates
        return (capacityToCheckAgainst.COMM_ValidFrom__c <= capacityRecord.COMM_ValidFrom__c &&
            capacityToCheckAgainst.COMM_ValidTo__c > capacityRecord.COMM_ValidFrom__c) ||
            (capacityToCheckAgainst.COMM_ValidFrom__c >= capacityRecord.COMM_ValidFrom__c &&
            capacityToCheckAgainst.COMM_ValidFrom__c < capacityRecord.COMM_ValidTo__c);
    }

    /**
     * @description Check if newly created/updated Capacity Records match existing Capacity records. If they do add error message.
     *
     * @param productWithCapacityMap Map with the newly created/updated Capacity Records to check
     * @param capacityToIgnoreIdSet Set of Id's of the records that are being processed. Used in query to ignore them since they changed
     */
    private void existingCapacityCheck(Map<Id, List<COMM_Capacity__c>> productWithCapacityMap, Set<Id> capacityToIgnoreIdSet) {
        for (COMM_Capacity__c foundCapacity : capacityRep.getNonDefaultCapacityByProductIds(productWithCapacityMap.keySet(), capacityToIgnoreIdSet)) {
            Id productId = foundCapacity.COMM_Product__c;
            if (productWithCapacityMap.containsKey(productId)) {
                for (COMM_Capacity__c processedCapacity : productWithCapacityMap.get(productId)) {
                    if (checkExistingDate(processedCapacity, foundCapacity)) {
                        processedCapacity.addError(System.Label.COMM_CAPACITY_ALREADY_EXISTS);
                    }
                }
            }
        }
    }
}