({
    /* Loads parameters from the flow, and uses them to navigate to either a record page or a list view
     *
     * @param {recordId} string - the id of the record to navigate to. If emtpy, tries to navigate to list view
     * @param {objectApiName} string - the API name of the object to navigate to
     * @param {listName} string - the name of the list view to navigate to, as per URL in Salesforce
     **/
    invoke: function (cmp, event) {
        var navService = cmp.find('navService');
        var recordId = cmp.get('v.recordId');
        var objectApiName = cmp.get('v.objectApiName');
        var listName = cmp.get('v.listName');

        var pageReference = null;

        if (recordId != null) {
            // Sets the route to /lightning/r/objectApiName/recordId/view
            pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: objectApiName, //eg. Case
                    actionName: 'view',
                    recordId: recordId
                }
            };
        } else if (listName != null) {
            // Sets the route to /lightning/o/objectApiName/list?filterName=listName
            pageReference = {
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: listName //eg. Recent
                }
            };
        }

        // Set the URL on the link or use the default if there's an error
        var defaultUrl = '#';
        navService.generateUrl(pageReference).then(
            $A.getCallback(function (url) {
                cmp.set('v.url', url ? url : defaultUrl);
            }),
            $A.getCallback(function () {
                cmp.set('v.url', defaultUrl);
            })
        );

        event.preventDefault();
        navService.navigate(pageReference, true);
    }
});