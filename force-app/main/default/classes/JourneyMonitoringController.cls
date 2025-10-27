public with sharing class JourneyMonitoringController {

    @AuraEnabled(cacheable=true)
    public static List<JourneyWrapper> fetchData() {
        COMM_IREP_OrderSummary orderSummaryRep = new COMM_REP_OrderSummary();
        Map<Id,JourneyWrapper> dataMap = new Map<Id,JourneyWrapper>();

        for(OrderSummary os : orderSummaryRep.getForJourneyMonitoringOrderProdSumFilter()){
            if (dataMap.containsKey(os.Id)) {
                continue;
            }
            
            dataMap.put(os.Id, new JourneyWrapper(os));
        }

        System.debug('[JourneyMonitoringController] data: ' + dataMap.values());

        return dataMap.values();
    }

    public class JourneyWrapper{

        public String name {get;set;}
        public String type {get;set;}
        public String orderSummary {get;set;}
        public Datetime orderDate {get;set;}
        public Datetime startDate {get;set;}
        public Datetime endDate {get;set;}
        public Boolean isPaid {get;set;}
        public String qrCode {get;set;}
        public String invoice {get;set;}
        public Date invoiceDate {get;set;}
        public String cpmsReservationId {get;set;}
        public Datetime realStartDate {get;set;}

        public JourneyWrapper(OrderSummary os){
            this.name = os.Account.Name;
            this.type = os.Account.IsPersonAccount ? 'B2C' : 'B2B';
            this.orderSummary = os.OrderNumber;
            this.orderDate = os.OrderedDate;
            this.isPaid = true;
            if(!os.OrderItemSummaries.isEmpty()) {
                this.startDate = os.OrderItemSummaries[0].COMM_ReservationStart__c;
                this.endDate = os.OrderItemSummaries[0].COMM_ReservationEnd__c;
                this.qrCode = os.OrderItemSummaries[0].Product2.Family == 'Parking' ? os.OrderItemSummaries[0].COMM_Barcode__c : os.OrderItemSummaries[0].COMM_QRCode__c;
                this.cpmsReservationId = os.OrderItemSummaries[0].COMM_ReservationIdCPMS__c;
                this.realStartDate = os.OrderItemSummaries[0].COMM_ReservationActualStart__c;
            }
            if(!os.Invoices.isEmpty()) {
                this.invoice = os.Invoices[0].DocumentNumber;
                this.invoiceDate = os.Invoices[0].InvoiceDate;
            }
        }
    }
}