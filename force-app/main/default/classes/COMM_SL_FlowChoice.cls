/**
 * @author Carlos Fusco
 * @description Service Layer class to handle flow available field choices
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco   21/03/2024       Original version
 **/
public inherited sharing class COMM_SL_FlowChoice {
    @AuraEnabled
    @InvocableVariable
    public String label;

    @AuraEnabled
    @InvocableVariable
    public String value;

    @AuraEnabled
    @InvocableVariable
    public Decimal price;

    @AuraEnabled
    @InvocableVariable
    public String name;

    @AuraEnabled
    @InvocableVariable
    public String periodicity;

    @AuraEnabled
    @InvocableVariable
    public String capacity;

    @AuraEnabled
    @InvocableVariable
    public String tax;

    @AuraEnabled
    @InvocableVariable
    public String productCode;

    @AuraEnabled
    @InvocableVariable
    public Integer productAvailability;

    /**
     * @description Empty class constructor
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public COMM_SL_FlowChoice() {
    }

    /**
     * @description Class Constructor to initiate label and respective value
     *
     * @param label Value to assign on choice label
     * @param value value to assing on choice value
     */
    public COMM_SL_FlowChoice(String label, String value) {
        this.label = label;
        this.value = value;
    }

    /**
     * @description Class Constructor to initiate label, respective value and additional parameters related on
     * new subscription request process
     *
     * @param id Product Code identifier
     * @param name Product Nnme
     * @param price Product price
     * @param periodicity Product Subscription periodicity
     * @param tax Product Subscription capacity
     * @param productCode Product Code
     * @param productAvailability Product availability quantity
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public COMM_SL_FlowChoice(
        String id,
        String name,
        Decimal price,
        String periodicity,
        String tax,
        String productCode,
        Integer productAvailability
    ) {
        this.label = name + ' - €' + price;
        this.value = id;
        this.name = name;
        this.price = price;
        this.periodicity = periodicity;
        this.tax = tax;
        this.productCode = productCode;
        this.productAvailability = productAvailability;
    }

    /**
     * @description Class Constructor to initiate label, respective value and additional parameters related on
     * new subscription request process
     *
     * @param id Product Code identifier
     * @param name Product Nnme
     * @param price Product price
     * @param periodicity Product Subscription periodicity
     * @param tax Product Subscription capacity
     * @param productCode Product Code
     * @param productAvailability Product availability quantity
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public COMM_SL_FlowChoice(
        String id,
        String name,
        Decimal price,
        String periodicity,
        String periodicityLabel
    ) {
        this.label = periodicityLabel + ' - ' + name;
        this.value = id;
        this.name = name;
        this.price = price;
        this.periodicity = periodicity;
    }
}