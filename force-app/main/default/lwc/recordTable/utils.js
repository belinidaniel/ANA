/**
 * @file Manage the data types for the lightning data table.
 */
const uiApiToDatatabletypes = {
    Boolean: 'boolean',
    Currency: 'currency',
    Date: 'date-local',
    DateTime: 'date',
    Double: 'number',
    Email: 'email',
    Int: 'number',
    Location: 'location',
    Percent: 'percent',
    Phone: 'phone',
    Url: 'url'
};

/**
 * Converts the data type.
 *
 * @param {string} type - The data type.
 * @returns {string} The converted data type.
 */
export function convertType(type) {
    return uiApiToDatatabletypes[type] || 'text';
}