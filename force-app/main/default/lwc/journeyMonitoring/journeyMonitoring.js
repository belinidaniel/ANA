import { LightningElement, wire } from 'lwc';
import fetchData from '@salesforce/apex/JourneyMonitoringController.fetchData';

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Type', fieldName: 'type' },
    { label: 'Order Summary', fieldName: 'orderSummary' },
    { label: 'Order Date', fieldName: 'orderDate', type: 'date' },
    { label: 'Start Date', fieldName: 'startDate', type: 'date' },
    { label: 'End Date', fieldName: 'endDate', type: 'date' },
    { label: 'Paid', fieldName: 'isPaid', type: 'boolean' },
    { label: 'QR Code', fieldName: 'qrCode' },
    { label: 'Invoice', fieldName: 'invoice' },
	{ label: 'Invoice Date', fieldName: 'invoiceDate', type: 'date' },
	{ label: 'CPMS Reservation Id', fieldName: 'cpmsReservationId' },
	{ label: 'Real Start Date', fieldName: 'realStartDate', type: 'date' },
];

export default class JourneyMonitoring extends LightningElement {
    error;
    columns = columns;

    @wire(fetchData)
    data;
}