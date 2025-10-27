/**
 * @description Class to generate test records
 **/
@isTest
public class COMM_TestDataFactory {
    /**
     * @description Creates a list of SObject records dynamically.
     *
     * @param numberOfRecords - The number of records to create.
     * @param doInsert - Controls if the generated records should be inserted.
     * @param sObjectType - SObject API Name.
     * @param fieldsMap - Map with fields and values to generated the record.
     * @return The list of records.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<Object> insertRecords(Integer numberOfRecords, Boolean doInsert, String sObjectType, Map<String, Object> fieldsMap) {
        List<sObject> objList = new List<sObject>();

        for (Integer i = 0; i < numberOfRecords; i++) {
            sObject sObj = Schema.getGlobalDescribe().get(sObjectType).newSObject();

            for (String fielAPIName : fieldsMap.keySet()) {
                if (fielAPIName == 'Name') {
                    sObj.put(fielAPIName, fieldsMap.get(fielAPIName) + String.valueOf(i));
                } else {
                    sObj.put(fielAPIName, fieldsMap.get(fielAPIName));
                }
            }
            objList.add(sObj);
        }

        if (doInsert && !objList.isEmpty()) {
            insert objList;
        }

        return objList;
    }

    /**
     * @description Method to add a value to a SObject field (to be used to set read only fields)
     *
     * @param sObj SObject to be modified
     * @param fieldMap Map with the Fields to be added/changed in the SObject
     * @return SObject with the fields on the Map
     **/
    public static SObject setField(SObject sObj, Map<String, Object> fieldMap) {
        String jsonString = JSON.serialize(sObj);

        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        dataMap.putAll(fieldMap);
        jsonString = JSON.serialize(dataMap);

        return (SObject) JSON.deserialize(jsonString, SObject.class);
    }

    /**
     * @description Creates a list of SObject records dynamically.
     *
     * @param numberOfRecords - The number of records to create.
     * @param doInsert - Controls if the generated records should be inserted.
     * @param sObjectType - SObject API Name.
     * @param fieldsMap - Map with fields and values to generated the record.
     * @return The list of records.
     */
    public static List<sObject> updateRecords(List<Id> recordIds, String sObjectType, Map<String, Object> fieldsMap) {
        List<SObject> objList = new List<SObject>();

        // Construct the dynamic SOQL query string
        String query = 'SELECT Id';
        for (String fieldName : fieldsMap.keySet()) {
            query += ', ' + fieldName;
        }
        query += ' FROM ' + sObjectType + ' WHERE Id IN :recordIds';

        // Perform the query without explicit typecasting
        List<SObject> existingRecords = Database.query(query);

        // Update the records based on the fieldsMap
        for (SObject record : existingRecords) {
            for (String fieldAPIName : fieldsMap.keySet()) {
                record.put(fieldAPIName, fieldsMap.get(fieldAPIName));
            }
            objList.add(record);
        }

        if (!objList.isEmpty()) {
            update objList;
        }

        return objList;
    }

    /**
     * @description Method to return an COMM_EncryptionSetting__mdt metadata record for testing encryption.
     *
     * @return Instance of a COMM_EncryptionSetting__mdt metadata record.
     */
    public static COMM_EncryptionSetting__mdt getTestEncryptionSetting() {
        return new COMM_EncryptionSetting__mdt(COMM_Buffer__c = 30, COMM_Value__c = '/zYmGP+6AX0VUx3kjO0zl4sWnOGRGsqTPEYuQ5pQR9w=');
    }
}