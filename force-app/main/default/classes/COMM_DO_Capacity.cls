/**
 * @author           Daniel Reto
 * @description      Capacity SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      11/04/2024       ECOMM-204: Original version
 **/
public inherited sharing class COMM_DO_Capacity implements COMM_IDO_Capacity {
    //Subscription Status Picklist Values
    public final static string PROCESS_STATUS_COMPLETED = 'COMPLETED';
    public final static string PROCESS_STATUS_PENDING = 'PENDING';
}