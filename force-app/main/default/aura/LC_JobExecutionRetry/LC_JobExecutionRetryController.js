({
    init: function (component, event, helper) {
        helper.fetchErrors(component, event, helper);
    },

    openRecord: function (_component, event) {
        var row = event.getParam('row');
        var navEvt = $A.get('e.force:navigateToSObject');
        navEvt.setParams({
            recordId: row.Id,
            slideDevName: 'detail'
        });
        navEvt.fire();
    },

    createJobs: function (component, event, helper) {
        helper.createJobs(component, event, helper);
    }
});