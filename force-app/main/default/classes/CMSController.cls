/**
 * @description Manages the content from Salesforce CMS.
 *
 */
@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class CMSController {
    /**
     * The size per page
     */
    static final Integer PAGE_SIZE = 250;

    /**
     * @description Get the managed content by content keys.
     *
     * @param contentKeys list of content management keys
     * @param data the community id, language and managed content type value.
     * @return list of mananged content versions
     */
    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getContentByContentKeys(List<String> contentKeys, Map<Object, String> data) {
        try {
            String language = data.get('language');
            String communityId = data.get('communityId');
            String managedContentType = data.get('managedContentType');

            // Replaces first dash character by underscore character
            String lang = language.replaceFirst('-', '_');

            ConnectApi.ManagedContentVersionCollection contentVersionCollection = ConnectApi.ManagedContent.getManagedContentByContentKeys(
                communityId,
                contentKeys,
                null,
                PAGE_SIZE,
                lang,
                managedContentType,
                true
            );

            if (Test.isRunningTest()) {
                return null;
            }

            List<ConnectApi.ManagedContentVersion> results = contentVersionCollection.items;

            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This method is used to get all the managed content by content type.
     *
     * @param language This parameter represents the language.
     * @param managedContentType This parameter represents the managed content type, e.g. cms_image.
     * @param storeName This parameter represents the store name, e.g. Sumol Compal Store.
     * @return List of mananged content versions.
     */
    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getAllManagedContentByContentType(
        String language,
        String managedContentType,
        string storeName
    ) {
        try {
            string networkName = String.escapeSingleQuotes(storeName);
            String id = [SELECT id FROM Network WHERE Name = :networkName].id;

            // Replaces first dash character by underscore character
            String lang = language.replaceFirst('-', '_');

            ConnectApi.ManagedContentVersionCollection contentVersionCollection = ConnectApi.ManagedContent.getAllManagedContent(
                id,
                null,
                PAGE_SIZE,
                lang,
                managedContentType,
                true
            );

            List<ConnectApi.ManagedContentVersion> results = contentVersionCollection.items;
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Get content type given the content key.
     *
     * @param contentKey - The content key identifier.
     * @param communityId - The community identifier.
     * @param language - The selected language to get the translated content.
     * @param managedContentType - The managed content type.
     * @return The managed content version if exists.
     */
    @AuraEnabled(cacheable=true)
    public static ConnectApi.ManagedContentVersion getContentByContentKey(
        String contentKey,
        String communityId,
        String language,
        String managedContentType
    ) {
        try {
            // Replaces first dash character by underscore character
            String lang = language.replaceFirst('-', '_');
            List<String> contentKeys = new List<String>();
            contentKeys.add(contentKey);

            ConnectApi.ManagedContentVersionCollection contentVersionCollection = ConnectApi.ManagedContent.getManagedContentByContentKeys(
                communityId,
                contentKeys,
                null,
                PAGE_SIZE,
                lang,
                managedContentType,
                true
            );

            ConnectApi.ManagedContentVersion results = contentVersionCollection.items[0];

            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This method is used to get all the managed content by content type.
     *
     * @param language This parameter represents the language.
     * @param managedContentType This parameter represents the managed content type, e.g. cms_image.
     * @param storeName This parameter represents the store name, e.g. Sumol Compal Store.
     * @param pageSize - The number of publications per page.
     * @param pageParam - The current page.
     * @return List of mananged content versions.
     */
    @AuraEnabled(cacheable=true)
    public static ConnectApi.ManagedContentVersionCollection getAllManagedContentByPage(
        String language,
        String managedContentType,
        String storeName,
        Integer pageSize,
        Integer pageParam
    ) {
        try {
            string networkName = String.escapeSingleQuotes(storeName);
            String id = [SELECT id FROM Network WHERE Name = :networkName].id;

            // Replaces first dash character by underscore character
            String lang = language.replaceFirst('-', '_');

            return ConnectApi.ManagedContent.getAllManagedContent(id, pageParam, pageSize, lang, managedContentType, true);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This method is used to get the managed content by content keys.
     *
     * @param contentKeys This parameter represents the list of content keys of the content management
     * @param data This parameter represents an object with the community id, language and managed content type value
     * @param pageSize - The number of publications per page.
     * @param pageParam - The current page.
     * @return list of mananged content versions
     */
    @AuraEnabled(cacheable=true)
    public static ConnectApi.ManagedContentVersionCollection getContentByContentKeysByPage(
        List<String> contentKeys,
        Map<Object, String> data,
        Integer pageSize,
        Integer pageParam
    ) {
        try {
            String language = data.get('language');
            String communityId = data.get('communityId');
            String managedContentType = data.get('managedContentType');

            // Replaces first dash character by underscore character
            String lang = language.replaceFirst('-', '_');

            return ConnectApi.ManagedContent.getManagedContentByContentKeys(
                communityId,
                contentKeys,
                pageParam,
                pageSize,
                lang,
                managedContentType,
                true
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}