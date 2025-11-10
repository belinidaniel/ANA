/**
 * @author Daniel Lascas
 * @description Class with generic utility methods
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024     Original version
 * Luis Oliveira    28/02/2024     Add log error method
 * Carlos Fusco     08/03/2024     Add method to get Sobject field describe
 * Ricardo Dias     28/02/2024     Add strings
 * Miguel Freire    23/03/2024     Add method getTokenValueFromPageReference
 * Rui Salgado      05/04/2024     Add method convertListToMap
 * Carlos Fusco     08/04/2024     Add methods for identifier encryption and dynamic url handling on email templates
 * Diogo Gonçalves  08/04/2024     Add method getTextFieldValues and generateQRCodeImage
 * Daniel Reto      22/04/2024     Add method getMonthValueToAdd
 * Daniel Reto      13/05/2024     Add methods generateHrefSiteEmailTemplate, generateHrefEmailTemplate and getEmailsFromQueue
 * Daniel Reto      29/05/2024     PDM warning messages fix
 * Daniel Reto      20/06/2024     Add method generateDateTimeDataType
 **/
public inherited sharing class COMM_GEN_Utility {
    //Format used by Datetime when converting to String (for use on Queries)
    public static final String TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ssZ';
    private static final String QRCODE_DATE_FORMAT = 'yyyyMMdd';
    public static final String TIMEZONE_DATETIME_FORMAT = 'yyyy-MM-dd HH:mm:ssXXX';
    public static final String PARKING = 'Parking';
    public static final String START_DATE = 'startDate';
    public static final String END_DATE = 'endDate';
    public static final String PRODUCT = 'product';
    public static final String TYPE_PUBLIC = 'Public';
    public static final String TYPE_RESELLER = 'Reseller';
    private static final String PNG_FILE_TYPE = 'img/png';
    private static final String QR_CODE = 'QR_CODE';
    private static final String CRYPTO_CODE = 'AES128';
    public static final String SUBSCRIPTION_KEY_NAME = 'COMM_SubscriptionKey__c';
    public static final String USER_KEY_NAME = 'COMM_UserKey__c';
    private static final String PT_COUNTRY_CODE = 'PT';
    private static final String SUBSCRIPTION_PORTAL_NETWORK_NAME = 'Subscriptions Portal';
    private static final String CHILD_STRING_UPPERCASE = 'CHILD';
    private static final String LOUNGE_QRCODE_CHARACTER_CHILD = 'C';
    private static final String LOUNGE_QRCODE_CHARACTER_ADULT = 'A';

    /**
     *  @description Method to check if a field was changed during trigger execution
     *
     *  @param newSobj SObject record from trigger in New Context
     *  @param oldSobjMap Map from trigger with all Records in Old Context
     *  @param fieldName The SObjectField to check if it was changed
     *  @return True if field was changed, false otherwise
     **/
    public static Boolean isChangedField(SObject newSobj, Map<Id, SObject> oldSobjMap, SObjectField fieldName) {
        return isChangedField(newSobj, oldSobjMap?.get(newSobj.Id), String.valueOf(fieldName));
    }

    /**
     *  @description Method to check if a field was changed
     *
     *  @param newSobj SObject record from trigger in New Context
     *  @param oldSobj SObject record from trigger in Old Context
     *  @param fieldName The SObjectField to check if it was changed
     *  @return True if field was changed, false otherwise
     **/
    public static Boolean isChangedField(SObject newSobj, SObject oldSobj, String fieldName) {
        return (oldSobj == null && newSobj.get(fieldName) != null) || (oldSobj != null && newSobj.get(fieldName) != oldSobj.get(fieldName));
    }

    /**
     * @description Log the error.
     *
     * @param errorMsg - The error message.
     * @param e - The current exception.
     * @param origin - Origin of the error.
     */
    public static void logError(Exception e, String errorMsg, String origin) {
        FW_ErrorAndMonitoringLog errorLog = new FW_ErrorAndMonitoringLog.ErrorDetailsBuilder()
            .setErrorMessage(errorMsg + Datetime.now() + ' | ' + e.getStackTraceString() + ' | ' + e.getMessage())
            .setOrigin(origin)
            .setCategory(FW_ErrorAndMonitoringLog.categoryType.Apex_Class)
            .setActorId(UserInfo.getUserId())
            .build();
        new FW_SystemNotificationPublr(errorLog);
    }

    /**
     * @description Get a field describe result of a specified field name
     *
     * @param sObjectName Api name of Sobject to process
     * @param sObjecField Api name of Sobject field to process
     * @return SObjectField describe of field name passed as argument
     */
    public static SObjectField getSobjectFieldName(String sObjectName, String sObjecField) {
        return Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(sObjecField);
    }

    /**
     * @description Method to obtain the record type's Id by it's Developer Name
     *
     * @param sobj The Sobject the record type is associated with
     * @param devName Developer Name of the Record Type to retrieve the Id
     * @return Id of the Record Type
     **/
    public static Id getRecordTypeIdByDevName(SObjectType sobj, String devName) {
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = sobj.getDescribe().getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo recTypeInfo = recordTypeInfoMap.get(devName);
        return recTypeInfo.getRecordTypeId();
    }

    /**
     * @description Method to convert a string value to the type of the field for a SObject
     *
     * @param sObjectName API Name of the SObject
     * @param fieldName API Name of the SObject's Field
     * @param fieldValue The Field Value as a String to be converted
     * @return The Field Value converted into the field type
     */
    public static Object getValueForFieldType(String sObjectName, String fieldName, String fieldValue) {
        Object convertedValue;

        Schema.DisplayType fieldType = Schema.getGlobalDescribe()
            .get(sObjectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe()
            .getType();

        //Verify Field Type and Convert Value from String to expected Type
        switch on fieldType {
            when BOOLEAN {
                convertedValue = Boolean.valueOf(fieldValue);
            }
            when CURRENCY {
                convertedValue = Decimal.valueOf(fieldValue);
            }
            when DOUBLE {
                convertedValue = Double.valueOf(fieldValue);
            }
            when DATE {
                convertedValue = Date.valueOf(fieldValue);
            }
            when DATETIME {
                convertedValue = DateTime.valueOf(fieldValue);
            }
            when else {
                //If field is remaining types then no convertion is made
                convertedValue = fieldValue;
            }
        }

        return convertedValue;
    }

    /**
     *  @description Method to convert a given string into base 64
     *
     * @param textToConvert Text to Convert into Base64 encoding
     * @return Converted String in Base64
     **/
    public static String convertToBase64(String textToConvert) {
        // Convert the input string to a Blob
        Blob binaryData = Blob.valueOf(textToConvert);
        // Encode the Blob as a Base64 string
        String base64String = EncodingUtil.base64Encode(binaryData);
        return base64String;
    }

    /**
     *  @description Method to decode a given string in base 64
     *
     * @param token Text in Base64 to decode
     * @return Decoded String
     **/
    public static String decodeBase64(String token) {
        // Decode base64
        Blob blobContent = EncodingUtil.base64Decode(token);
        // Blob to string
        String decodeBase64String = blobContent.toString();
        return decodeBase64String;
    }

    /**
     * @description Extracts unique string values from a specified text field across a list of SObjects.
     *
     * @param sObjects   List of SObjects to extract values from.
     * @param fieldName  Name of the text field to extract values from.
     * @return           List of unique string values extracted from the specified field.
     */
    public static List<String> getTextFieldValues(List<SObject> sObjects, String fieldName) {
        Set<String> values = new Set<String>();
        for (SObject sobj : sObjects) {
            if (sobj.get(fieldName) != null) {
                values.add((String) sobj.get(fieldName));
            }
        }
        return new List<String>(values);
    }

    /**  @description Method to return a map of picklist values and labels.
     *
     * @param picklistField Schema details of specified picklist field
     * @param usePicklistLabelAsKey Flag to define if the key of the map to return should be picklist entry label.
     * @return A map of picklist value by label / label by value
     **/
    public static Map<String, String> getPicklistMap(Schema.SObjectField picklistField, Boolean usePicklistLabelAsKey) {
        Map<String, String> picklistMap = new Map<String, String>();
        List<Schema.PicklistEntry> pickListFielEntries = picklistField.getDescribe().getPickListValues();

        for (Schema.PicklistEntry objPickList : pickListFielEntries) {
            if (usePicklistLabelAsKey) {
                picklistMap.put(objPickList.getLabel(), objPickList.getValue());
            } else {
                picklistMap.put(objPickList.getValue(), objPickList.getLabel());
            }
        }

        return picklistMap;
    }

    /**
     *  @description Method to get the token value from a String
     *
     * @param stringValue String value to get te token from
     * @return Token Value
     **/
    @SuppressWarnings('PMD.ApexOpenRedirect')
    public static String getTokenValueFromPageReference(String stringValue) {
        // Create a PageReference object
        PageReference pageReference = new PageReference(stringValue);
        // Get the query parameters from the String
        Map<String, String> queryParameters = pageReference.getParameters();
        // Access Token Parameters
        String tokenParameter = queryParameters.get(COMM_DO_Email.ENCODED_USERID_BASE64);
        // return token vale
        return tokenParameter;
    }

    /**
     *  @description Method to encrypt a record identifier
     *
     * @param recordIdentifier Record identifier.
     * @param keyName Name of the Key to be used when encrypting record identifier.
     * @return String with encrypted record identifier
     **/
    @SuppressWarnings('PMD.ApexBadCrypto')
    public static String encryptRecordIdentifier(String recordIdentifier, String keyName) {
        Blob encryptionKey = Blob.valueOf((String) COMM_EmailTemplatesEncryptionSettings__c.getInstance().get(keyName));
        Blob data = Blob.valueOf(recordIdentifier);
        Blob encrypted = Crypto.encrypt(CRYPTO_CODE, encryptionKey, encryptionKey, data);

        return EncodingUtil.base64Encode(encrypted);
    }

    /**
     *  @description Method to decrypt a record identifier
     *
     * @param recordEncryptedIdentifier Encrypted record identifier.
     * @param keyName Name of the Key used to encrypt record identifier.
     * @return String with decrypted record identifier
     **/
    @SuppressWarnings('PMD.ApexBadCrypto')
    public static String decryptRecordIdentifier(String recordEncryptedIdentifier, String keyName) {
        Blob encryptionKey = Blob.valueOf((String) COMM_EmailTemplatesEncryptionSettings__c.getInstance().get(keyName));
        Blob data = EncodingUtil.base64Decode(recordEncryptedIdentifier);
        Blob decrypted = Crypto.decrypt(CRYPTO_CODE, encryptionKey, encryptionKey, data);

        return decrypted.toString();
    }

    /**
     *  @description Method to get experience site URL
     *
     * @return String with experience site base URL
     **/
    public static string getExperiencrSiteUrl() {
        COMM_IREP_EmailTemplate emailTemplateREP = new COMM_REP_EmailTemplate();
        Id communityId = emailTemplateREP.getEmailTemplateNetworkSite().get(0).Id;
        String baseUrl = Network.getLoginUrl(communityId);
        Integer siteEndIndex = baseUrl.indexOf('.com/') + 4;
        baseUrl = baseUrl.left(siteEndIndex);
        return baseUrl;
    }

    /**
     *  @description Method to get Subscription Portal Cmmunity URL
     *
     * @return String with subscription experience site base URL
     **/
    public static string getSubscriptionPortalUrl() {
        Id communityId = new COMM_REP_EmailTemplate().getNetworkSiteByName(new Set<String>{ SUBSCRIPTION_PORTAL_NETWORK_NAME })?.get(0).Id;
        String baseUrl = Network.getLoginUrl(communityId);
        Integer siteEndIndex = baseUrl.indexOf('/login');
        baseUrl = baseUrl.left(siteEndIndex);
        return baseUrl;
    }

    /**
     * @description Convert a List to a Map indexed by values on fieldName
     * @param recordsList List of Sobjects to index
     * @param fieldName Field of Sobject to use as key
     * @return Map<String, SObject>
     */
    public static Map<String, SObject> convertListToMap(List<SObject> recordsList, String fieldName) {
        Map<String, SObject> mapRecords = new Map<String, SObject>();
        for (SObject record : recordsList) {
            String fieldValue = String.valueOf(record.get(fieldName));
            mapRecords.put(fieldValue, record);
        }
        return mapRecords;
    }

    /**
     * @description Generates the QR Code image and return html to be store on a rich text field
     *              NOTE: Performs a callout to Barcode Generation API
     * @param qrCodeValue String of the value to be stored on the QR Code
     * @return String of the html with the img tag to display the generated QR Code image
     */
    public static String generateQRCodeImage(String qrCodeValue) {
        COMM_SL_BarcodeResponse qrCodeData = COMM_SL_BarCodeGeneration.getBarCodeBase64(qrCodeValue, QR_CODE);
        if (qrCodeData == null) {
            return null;
        }
        if (String.isBlank(qrCodeData.content)) {
            return null;
        }
        if (qrCodeData.fileType != PNG_FILE_TYPE) {
            return null;
        }
        String src = 'data:image/png;base64,' + qrCodeData.content;
        String className = 'qr-code';
        return '<img class="' + className + '" src="' + src + '"/>';
    }

    /**
     * @description Get periodicity number of months to add on a Date or DateTime field
     * @param periodicity Periodicity string
     * @return Integer
     */
    public static Integer getMonthValueToAdd(String periodicity) {
        Integer returnValue = 0;
        if (periodicity == COMM_DO_Subscription.PERIODICITY_MONTHLY) {
            returnValue = 1;
        } else if (periodicity == COMM_DO_Subscription.PERIODICITY_QUARTERLY) {
            returnValue = 3;
        } else if (periodicity == COMM_DO_Subscription.PERIODICITY_HALF_YEARLY) {
            returnValue = 6;
        } else if (periodicity == COMM_DO_Subscription.PERIODICITY_YEARLY) {
            returnValue = 12;
        }
        return returnValue;
    }

    /**
     * @description Get Ids of a given SObject type from an Id List
     * @param {list<Id>} ids
     * @return {list<String>}
     */
    public static List<String> getIdsOfGivenSObjectType(List<String> ids, SObjectType sobjectType) {
        List<String> orderSummaryIds = new List<String>();
        for (Id objId : ids) {
            if (objId != null && objId.getSObjectType() == sobjectType) {
                orderSummaryIds.add(objId);
            }
        }
        return orderSummaryIds;
    }

    /**
     * @description Helper Method to create a href with the Record Label, already prepared to be used on the HTML Body of a Email Template.
     *
     * @param recordId Record identifier
     * @param recordLabel Record label
     * @return String already set to be a URL Link on a Lightning Email Template
     */
    public static String generateHrefSiteEmailTemplate(Id recordId, String recordLabel, String experiencrSiteUrl) {
        return '<li><a href="' + experiencrSiteUrl + '/detail/' + recordId + '">' + recordLabel + '</a></li>';
    }

    /**
     * @description Helper Method to create a href with the Record Label, already prepared to be used on the HTML Body of a Email Template.
     *
     * @param recordId Record identifier
     * @param recordLabel Record label
     * @return String already set to be a URL Link on a Lightning Email Template
     */
    public static String generateHrefEmailTemplate(Id recordId, String recordLabel) {
        return '<li><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + recordId + '">' + recordLabel + '</a></li>';
    }

    /**
     * @description Helper Method to catch all User Emails from a Queue.
     *
     * @param queueName Queue name
     * @return String List with all user group Memeber Emails in the specified queue
     */
    public static List<String> getEmailsFromQueue(String queueName) {
        List<String> emails = new List<String>();
        // Query to retrieve UserIds of users in the specified queue
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :queueName];
        Set<Id> userIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            userIds.add(member.UserOrGroupId);
        }
        // Query Users to retrieve emails
        List<User> users = [SELECT Id, Email FROM User WHERE Id IN :userIds];
        for (User user : users) {
            if (user.Email != null) {
                emails.add(user.Email);
            }
        }
        return emails;
    }

    /**
     * @description Helper method to generate a new DateTime data type based on a Date.
     *
     * @param dt Context Date value to convert
     * @return DateTime value converted with the same year, month and day as the param dt
     */
    public static DateTime generateDateTimeDataType(Date dt) {
        return DateTime.newInstance(dt.year(), dt.month(), dt.day());
    }

    /**
     * @description Method to validate if a provided VAT Number is valid.
     * An empty VAT Value is considered valid.
     * Validation is skipped for non-Portuguese VAT Numbers.
     *
     * @return True if VAT is Valid, false otherwise
     */
    @AuraEnabled
    public static Boolean validateVAT(String vatToValidate, String countryCode) {
        return (String.isNotBlank(countryCode) && !PT_COUNTRY_CODE.equals(countryCode)) ||
            COMM_DO_VATNumberValidation.getInstance().isValid(countryCode, vatToValidate, true);
    }

    /**
     * @description Generates random number based on length
     * @param stringLength Length of the string
     * @return Random number as string
     */
    public static String getRandomNumber(integer stringLength) {
        Integer max = integer.valueOf(Math.pow(10, stringLength) - 1);
        return String.valueOf(Math.Round(Math.Random() * MAX)).leftPad(stringLength, '0');
    }

    /**
     * @description Method to generate a QR code value
     *              Example: GWPOPO0123456789ABCDEF20240408
     * @param {String} subCategory
     * @param {String} airportCode
     * @param {Datetime} reservationDate
     * @return {String}
     */
    public static String generateQRCodeValue(
        String family,
        String subCategory,
        String airportCode,
        Datetime reservationDate,
        String timeZoneByAirport
    ) {
        COMM_IREP_QRCodePrefixMdt prefixMdtRep = new COMM_REP_QRCodePrefixMdt();
        COMM_QRCodePrefix__mdt qrCodePrefix = prefixMdtRep.getQRCodePrefix(subCategory?.replace(' ', '_'));
        if (qrCodePrefix == null || String.isBlank(airportCode) || reservationDate == null) {
            return null;
        }

        String randomHash = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 16).toUpperCase();

        // Replace 29th character for lounges
        String finalQRString = qrCodePrefix.COMM_Prefix__c + airportCode + randomHash + reservationDate.format(QRCODE_DATE_FORMAT, timeZoneByAirport);
        String loungeCharacter;
        if (family == COMM_DO_Product2.CATEGORY_LOUNGE) {
            loungeCharacter = subCategory.toUpperCase().contains(CHILD_STRING_UPPERCASE)
                ? LOUNGE_QRCODE_CHARACTER_CHILD
                : LOUNGE_QRCODE_CHARACTER_ADULT;
            finalQRString = finalQRString.substring(0, 28) + loungeCharacter + finalQRString.substring(29);
        }
        return finalQRString;
    }

    /**
     * @description Method to decrypt a string that was encrypted with an AES Crypto Key.
     *
     * @param stringValue Encrypted Value.
     * @param secretKey Encoded AES Crypto Key to be used in decryption.
     * @return Decryped Value.
     */
    public static String decryptStringWithAES(String stringValue, String secretKey) {
        // Decrypt the value
        Blob encryptedBlob = EncodingUtil.base64Decode(stringValue);
        Blob keyBlob = EncodingUtil.base64Decode(secretKey);
        Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', keyBlob, encryptedBlob);
        return decryptedBlob.toString();
    }
}