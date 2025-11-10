/**
 * @author Daniel Lascas
 * @description Trigger worker that verifies if there is a default capacity record for
 * the product in context. Throw an error if the default capacity rule it's not compliant
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    20/02/2024		Original version
 **/
public class COMM_TW_Capacity_VerifyDefaultCapacities {
    private COMM_IREP_Capacity capacityRep;
    private COMM_IREP_Product2 productRep;

    //Map to Store Product's current Default Capacity that are set to change
    private Map<Id, COMM_Capacity__c> oldProductsMap;

    /**
     * @description Class Constructor to initiate REP Classes
     */
    public COMM_TW_Capacity_VerifyDefaultCapacities() {
        this.capacityRep = new COMM_REP_Capacity();
        this.productRep = new COMM_REP_Product2();
    }

    @TestVisible
    private COMM_TW_Capacity_VerifyDefaultCapacities(COMM_IREP_Capacity capacityRep, COMM_IREP_Product2 productRep) {
        this.capacityRep = capacityRep;
        this.productRep = productRep;
    }

    /**
     * @description Execute Trigger Worker Logic
     *
     * @param capacityList List with the Capacity Records that are being created/updated/deleted
     * @param capacityOldMap Map with old Values of the Capacity Record before update/delete
     * @param isDelete Boolean to determine if Records are being deleted (to separate delete logic from insert/update)
     */
    public void execute(List<COMM_Capacity__c> capacityList, Map<Id, COMM_Capacity__c> capacityOldMap, Boolean isDelete) {
        //Sets and Map to store new record values
        Map<Id, ProcessCapacityWrapper> productWithCapacityMap = new Map<Id, ProcessCapacityWrapper>();
        Set<Id> capacityToIgnoreSet = new Set<Id>();

        if (isDelete) {
            verifyDeletedDefaultCapacities(capacityList, productWithCapacityMap, capacityToIgnoreSet);
        } else {
            verifyInsertedOrUpdatedCapacities(capacityList, productWithCapacityMap, capacityToIgnoreSet, capacityOldMap);
        }

        //Check if there are Capacity Records for further verification
        if (!productWithCapacityMap.isEmpty()) {
            addErrorOnDefaultCapacities(productWithCapacityMap, capacityToIgnoreSet, isDelete);
        }
    }

    /**
     * @description Check if Capacity Records set for deletion are Active Default Capacity Records. If they are add them for further checking.
     *
     * @param capacityList List with the Capacity Records that are going to be deleted
     * @param productWithCapacityMap Map with the deleted Capacity Records (inside Wrapper) for further processing
     * @param capacityToIgnoreSet Set of Id's of the records that are being processed. Used in query to ignore them since they will be deleted
     */
    private void verifyDeletedDefaultCapacities(
        List<COMM_Capacity__c> capacityList,
        Map<Id, ProcessCapacityWrapper> productWithCapacityMap,
        Set<Id> capacityToIgnoreSet
    ) {
        //Check if record to be deleted is an Active Default Capacity
        for (COMM_Capacity__c capacity : capacityList) {
            if (capacity.COMM_IsDefaultCapacity__c && capacity.COMM_Active__c) {
                if (productWithCapacityMap.containsKey(capacity.COMM_Product__c)) {
                    ProcessCapacityWrapper wrapper = productWithCapacityMap.get(capacity.COMM_Product__c);
                    wrapper.capacityList.add(capacity);
                } else {
                    ProcessCapacityWrapper wrapper = new ProcessCapacityWrapper();
                    wrapper.isDefault = true;
                    wrapper.capacityList = new List<COMM_Capacity__c>{ capacity };
                    productWithCapacityMap.put(capacity.COMM_Product__c, wrapper);
                }
                capacityToIgnoreSet.add(capacity.Id);
            }
        }

        //Verify if an Active Product exists associated with the Deleted Active Default Capacity. If exists prevent deletion.
        for (Product2 activeProduct : productRep.getActiveProductsByIds(productWithCapacityMap.keySet())) {
            for (COMM_Capacity__c deletedRecord : productWithCapacityMap.get(activeProduct.Id).capacityList) {
                deletedRecord.addError(System.Label.COMM_CAPACITY_DEFAULT_REQUIRED);
            }
            productWithCapacityMap.remove(activeProduct.Id);
        }
    }

    /**
     * @description Check if among the Capacity Records set for insertion/update are multiple Default Capacity Records for a given Product.
     * If there are, accept first in list and set remaining with error message.
     *
     * @param capacityList List with the Capacity Records that are going to be inserted/updated in New Context
     * @param productWithCapacityMap Map with the inserted/updated Capacity Records (inside Wrapper) for further processing
     * @param capacityToIgnoreSet Set of Id's of the records that are being processed. Used in query to ignore them since they will be changed (UPDATE LOGIC)
     * @param capacityOldMap Map with old Values of the Capacity Record before update to check for lookup changes
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void verifyInsertedOrUpdatedCapacities(
        List<COMM_Capacity__c> capacityList,
        Map<Id, ProcessCapacityWrapper> productWithCapacityMap,
        Set<Id> capacityToIgnoreSet,
        Map<Id, COMM_Capacity__c> capacityOldMap
    ) {
        oldProductsMap = new Map<Id, COMM_Capacity__c>();
        for (COMM_Capacity__c newCapacity : capacityList) {
            //If Product Lookup Changed, then store old Product Id.
            //To verify if Product is Active and update would cause it to not have a Default Capacity
            if (
                capacityOldMap != null &&
                COMM_GEN_Utility.isChangedField(newCapacity, capacityOldMap, COMM_Capacity__c.COMM_Product__c) &&
                newCapacity.COMM_IsDefaultCapacity__c
            ) {
                oldProductsMap.put(capacityOldMap.get(newCapacity.Id).COMM_Product__c, newCapacity);
            }

            //Store Capacities in Wrapper for later Processing
            if (productWithCapacityMap.containsKey(newCapacity.COMM_Product__c)) {
                ProcessCapacityWrapper wrapper = productWithCapacityMap.get(newCapacity.COMM_Product__c);
                if (!wrapper.isDefault && newCapacity.COMM_IsDefaultCapacity__c) {
                    wrapper.isDefault = true;
                }
                wrapper.capacityList.add(newCapacity);
            } else {
                ProcessCapacityWrapper wrapper = new ProcessCapacityWrapper();
                wrapper.isDefault = newCapacity.COMM_IsDefaultCapacity__c;
                wrapper.capacityList = new List<COMM_Capacity__c>{ newCapacity };
                productWithCapacityMap.put(newCapacity.COMM_Product__c, wrapper);
            }
            capacityToIgnoreSet.add(newCapacity.Id);
        }
    }

    /**
     * @description Verify if Capacity Records change comply with the Default Capacity Rule. Adds error message to records that are not compliant.
     *
     * @param productWithCapacityMap Map with the Process Capacity Wrapper to check
     * @param capacityToIgnoreSet Set of Id's of the records that are being processed. Used in query to ignore them since they will be deleted
     * @param isDelete Controller to inform if process is delete or insert/update
     */
    private void addErrorOnDefaultCapacities(Map<Id, ProcessCapacityWrapper> productWithCapacityMap, Set<Id> capacityToIgnoreSet, Boolean isDelete) {
        //If Delete then check for Non-Default Active Capacity Records. If Insert/Update then check for Default Active Capacity Records
        for (
            COMM_Capacity__c existingCapacity : isDelete
                ? capacityRep.getCountNonDefaultCapacityByProductIds(productWithCapacityMap.keySet(), capacityToIgnoreSet)
                : capacityRep.getCountDefaultCapacityByProductIds(productWithCapacityMap.keySet(), capacityToIgnoreSet)
        ) {
            //For Delete, add error Message to all the records on the list since Default would be missing
            //For Insert/Update, a Default already exists so add error message to only the records that are being inserted/updated as Default
            for (COMM_Capacity__c processedCapacity : productWithCapacityMap.get(existingCapacity.COMM_Product__c).capacityList) {
                if (isDelete) {
                    processedCapacity.addError(System.Label.COMM_CAPACITY_DEFAULT_REQUIRED);
                } else if (processedCapacity.COMM_IsDefaultCapacity__c && existingCapacity.COMM_ValidTo__c > processedCapacity.COMM_ValidFrom__c) {
                    processedCapacity.addError(System.Label.COMM_CAPACITY_DEFAULT_ALREADY_EXISTS);
                }
            }
            //Remove Capacities from Map since they don't need further verification
            productWithCapacityMap.remove(existingCapacity.COMM_Product__c);
        }
        //For Insert/Update, check for further processing if there are remaining Capacity Records
        if (!isDelete && !productWithCapacityMap.isEmpty()) {
            addErrorOnNonDefaultCapacities(productWithCapacityMap);
        }
    }

    /**
     * @description In Insert/Update, for Remaining Capacities (where Default doesn't exist). Verify if a Default is being processed among
     * the new records (by checking controller). Accept the Records if there is, if not then add error message to all records (non-Default) on the list
     *
     * @param productWithCapacityMap Map with the Capacity Records to check
     */
    private void addErrorOnNonDefaultCapacities(Map<Id, ProcessCapacityWrapper> productWithCapacityMap) {
        //Verify Product Lookup changes on Update
        if (!oldProductsMap.isEmpty()) {
            addErrorOnInvalidLookupChanges(productWithCapacityMap);
        }
        //Verify for remaining Capacities if there's a Default on the List for a Product, if there aren't add error.
        for (Id productId : productWithCapacityMap.keySet()) {
            if (!productWithCapacityMap.get(productId).isDefault) {
                for (COMM_Capacity__c processedCapacity : productWithCapacityMap.get(productId).capacityList) {
                    processedCapacity.addError(System.Label.COMM_CAPACITY_DEFAULT_REQUIRED);
                }
            }
        }
    }

    /**
     * @description In Update, verify for each change to Lookup if Current Product is Active and if update would result in it not having a Default Capacity.
     * Add error if it's the case.
     *
     * @param productWithCapacityMap Map with the Capacity Records to check
     */
    private void addErrorOnInvalidLookupChanges(Map<Id, ProcessCapacityWrapper> productWithCapacityMap) {
        //Query for Active Products
        for (Product2 activeProduct : productRep.getActiveProductsByIds(oldProductsMap.keySet())) {
            //Verify if Product that lost it's current Default Capacity has a new Default Capacity from Update to replace it.
            //If not add error to all capacities for the Product that a Default is required.
            if (productWithCapacityMap.containsKey(activeProduct.Id) && !productWithCapacityMap.get(activeProduct.Id).isDefault) {
                for (COMM_Capacity__c processedCapacity : productWithCapacityMap.get(activeProduct.Id).capacityList) {
                    processedCapacity.addError(System.Label.COMM_CAPACITY_DEFAULT_REQUIRED);
                }
            }
            //Add error message to Defaut Product that changed Lookup if the update would result in an Active Product without a Default Capacity
            if (!productWithCapacityMap.containsKey(activeProduct.Id) || !productWithCapacityMap.get(activeProduct.Id).isDefault) {
                oldProductsMap.get(activeProduct.Id).addError(System.Label.COMM_CAPACITY_DEFAULT_REQUIRED);
            }
            //Remove Capacities from further Processing
            productWithCapacityMap.remove(activeProduct.Id);
        }
    }

    /**
     * @description Wrapper Class to help in Insert/Update Trigger Logic. Used to store list of Capacity Records to be inserted/updated
     * for a given Product and a Boolean indicating if among the records on the List there is one set as a Default Capacity
     */
    private class ProcessCapacityWrapper {
        private Boolean isDefault;
        private List<COMM_Capacity__c> capacityList;
    }
}