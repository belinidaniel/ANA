/**
 * @author Ricardo Dias
 * @descriptionp Pricing Webservice service layer class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024       Original version
 * Ricardo Dias    11/05/2024       Update parking hour calculation
 **/
public inherited sharing class COMM_SL_PricingCalculation {
    /**
     * @description Retrieves the cheapest pricing options for a list of pricebook entries within a specific date range
     *
     * @param pricebookEntriesList A list of PricebookEntry objects to find pricing for
     * @param startDate The starting date for the pricing period
     * @param endDate The ending date for the pricing period
     * @return A map where each PricebookEntry is associated with its cheapest price over the given date range
     */
    public Map<PricebookEntry, Decimal> getPriceByPBE(List<PricebookEntry> pricebookEntriesList, Datetime startDate, Datetime endDate) {
        List<PricebookEntry> pricebookEntries = getPriceBookEntries(pricebookEntriesList);
        Map<PricebookEntry, Decimal> cheapestEntriesMap = getCheapestPricebookEntries(pricebookEntries, startDate, endDate);
        return cheapestEntriesMap;
    }

    /**
     * @description Identifies and returns the cheapest pricebook entries for given products within a specific date range
     *
     * @param pricebookEntries A list of PricebookEntry objects to evaluate
     * @param startDateTime The start date of the date range for the pricing evaluation
     * @param endDateTime The end date of the date range for the pricing evaluation
     * @return A map associating the cheapest PricebookEntry for each product with its calculated cost over the specified date range
     */
    private Map<PricebookEntry, Decimal> getCheapestPricebookEntries(
        List<PricebookEntry> pricebookEntries,
        Datetime startDateTime,
        Datetime endDateTime
    ) {
        Map<String, PricebookEntry> productCodeToCheapestEntry = new Map<String, PricebookEntry>();
        Map<PricebookEntry, Decimal> cheapestPricebookEntriesMap = new Map<PricebookEntry, Decimal>();

        for (PricebookEntry pricebookEntry : pricebookEntries) {
            Decimal currentPrice = calculateCost(pricebookEntry, startDateTime, endDateTime);

            if (
                !productCodeToCheapestEntry.containsKey(pricebookEntry.ProductCode) ||
                cheapestPricebookEntriesMap.get(productCodeToCheapestEntry.get(pricebookEntry.ProductCode)) > currentPrice
            ) {
                // Update the cheapest entry for this product code
                productCodeToCheapestEntry.put(pricebookEntry.ProductCode, pricebookEntry);
                cheapestPricebookEntriesMap.put(pricebookEntry, currentPrice);
            }
        }

        // Clean up the map to only contain the cheapest entries
        cheapestPricebookEntriesMap.keySet().retainAll(productCodeToCheapestEntry.values());

        return cheapestPricebookEntriesMap;
    }

    /**
     * @description Calculates the total cost based on the product's pricebook type and the specified start and end dates
     *
     * @param pricebookEntry The PricebookEntry object containing  the pricing period definitions and rates
     * @param startDateTime The start date and time for the duration
     * @param endDateTime The end date and time for the duration
     * @return The total calculated cost as a Decimal. Returns null if an error occurs during calculation
     */
    private Decimal calculateCost(PricebookEntry pricebookEntry, DateTime startDateTime, DateTime endDateTime) {
        Decimal currentPrice = pricebookEntry.UnitPrice;

        //If the product is parking it needs to be calculated
        if (pricebookEntry.Product2.Family == COMM_GEN_Utility.PARKING) {
            currentPrice = calculateParkingCost(pricebookEntry, startDateTime, endDateTime);
        }
        return currentPrice;
    }

    /**
     * @description Calculates the total parking cost based on the product's pricing periods and the specified start and end dates
     *
     * @param pbEntry The PricebookEntry object containing the pricing period definitions and rates
     * @param startDateTime The start date and time for the parking duration
     * @param endDateTime The end date and time for the parking duration
     * @return The total calculated parking cost as a Decimal. Returns null if an error occurs during calculation
     */
    private Decimal calculateParkingCost(PricebookEntry pbEntry, DateTime startDateTime, DateTime endDateTime) {
        Decimal totalCost = 0.0;

        // Calculate milliseconds difference
        Long diffInMillis = endDateTime.getTime() - startDateTime.getTime();

        // Convert milliseconds to hours, round, and cast to Integer
        Integer hoursDifference = (Integer) Math.ceil((Decimal.valueOf(diffInMillis) / (1000 * 60 * 60)).setScale(2, System.RoundingMode.HALF_UP));

        // Convert hours to days
        Integer daysDifference = Math.ceil(Decimal.valueOf(hoursDifference) / 24).intValue();

        // Calculate the modulus of hours by 24 to find remaining hours
        Integer remainingMins = Math.mod((Integer) (diffInMillis / (1000 * 60)), 24 * 60);

        List<PeriodWrapper> periodsList = constructPeriodList(pbEntry);

        for (Integer currentDay = 1; currentDay <= daysDifference; currentDay++) {
            PeriodWrapper matchedPeriod = findMatchingPeriod(periodsList, currentDay);
            try {
                if (
                    currentDay == daysDifference &&
                    currentDay != COMM_PricingCalculationSetting__mdt.getInstance(COMM_GEN_Utility.PARKING).COMM_MinimumChargedDays__c
                ) {
                    totalCost += calculateParkingCostLastDay(pbEntry, remainingMins, matchedPeriod);
                } else {
                    totalCost += matchedPeriod.dailyMax;
                }
            } catch (Exception e) {
                COMM_GEN_Utility.logError(e, 'Pricing Calculation calculateParkingCostLastDay Error', 'COMM_SL_PricingCalculation');
                return null;
            }
        }
        return totalCost;
    }

    /**
     * @description Calculates the cost for the last day of parking usage based on a given Minutes and compares it to a daily maximum
     *
     * @param pbEntry The PricebookEntry representing the product
     * @param remainingMinutes The remaining Minutes to calculate
     * @param period The PeriodWrapper object containing the daily maximum cost
     * @return Decimal The calculated cost for the last day, respecting the daily maximum limit
     */
    private Decimal calculateParkingCostLastDay(PricebookEntry pbEntry, Integer remainingMinutes, PeriodWrapper period) {
        //If remaining minutes are 0 it should add a daily maximum of 1 day
        Decimal lastDayPrice = remainingMinutes == 0 ? period.dailyMax : calculateParkingMinutesPrice(pbEntry, remainingMinutes);
        // Adjust the last day's price if it exceeds the daily maximum.
        lastDayPrice = Math.min(lastDayPrice, period.dailyMax);
        return lastDayPrice;
    }

    /**
     * @description Calculates the parking price based on remaning minutes of usage, using different rates for each 15-minute interval
     *
     * @param pbEntry The PricebookEntry representing the product with interval pricing
     * @param remainingMinutes The remaning minutes of usage
     * @return Decimal The total price calculated based on the usage
     */
    private Decimal calculateParkingMinutesPrice(PricebookEntry pbEntry, Integer remainingMinutes) {
        // Calculate the total number of 15-minute intervals
        // List of specific minutes to check against
        Integer totalIntervals = (Integer) Math.ceil((Decimal) remainingMinutes / 15);
        // Initialize the total price
        Decimal totalPrice = 0.0;

        // Prices for the first three intervals and subsequent intervals
        Decimal[] intervalPrices = new List<Decimal>{
            pbEntry.COMM_First15MinuteUnit__c,
            pbEntry.COMM_Second15MinuteUnit__c,
            pbEntry.COMM_Third15MinuteUnit__c,
            pbEntry.COMM_Remaining15MinuteUnit__c
        };

        // Calculate the price based on the intervals
        for (Integer i = 0; i < totalIntervals; i++) {
            // Select the appropriate price for the current interval
            Decimal currentIntervalPrice = (i < 3) ? intervalPrices[i] : intervalPrices[3];
            totalPrice += currentIntervalPrice;
        }
        return totalPrice;
    }

    /**
     * @description Selects appropriate PricebookEntry records for products based on standard and non-standard classifications. Get all the non-standard pricebooks for each product and the standard one if no other exists
     *
     * @param pbeList A list of PricebookEntry objects representing the pricebook entries to be processed
     * @return A list of PricebookEntry objects that have been selected based on the presence of standard and non-standard entries, prioritizing non-standard entries where applicable
     */
    private List<PricebookEntry> getPriceBookEntries(List<PricebookEntry> pbeList) {
        Map<String, PricebookEntry> standardEntries = new Map<String, PricebookEntry>();
        Map<String, List<PricebookEntry>> nonStandardEntriesMap = new Map<String, List<PricebookEntry>>();
        Set<String> processedProductCodes = new Set<String>();
        List<PricebookEntry> resultEntries = new List<PricebookEntry>();

        // Categorize entries into standard and non-standard
        for (PricebookEntry entry : pbeList) {
            if (entry.Pricebook2.IsStandard) {
                standardEntries.put(entry.ProductCode, entry);
            } else {
                if (!nonStandardEntriesMap.containsKey(entry.ProductCode)) {
                    nonStandardEntriesMap.put(entry.ProductCode, new List<PricebookEntry>());
                }
                nonStandardEntriesMap.get(entry.ProductCode).add(entry);
            }
        }

        // Determine which entries to add to the result based on the logic
        for (String productCode : nonStandardEntriesMap.keySet()) {
            List<PricebookEntry> nonStandards = nonStandardEntriesMap.get(productCode);
            if (nonStandards.size() > 0) {
                // If there are non-standard entries, add them
                resultEntries.addAll(nonStandards);
                processedProductCodes.add(productCode);
            }
        }

        // Add standard entries if no non-standard entries were processed for the product code
        for (String productCode : standardEntries.keySet()) {
            if (!processedProductCodes.contains(productCode)) {
                resultEntries.add(standardEntries.get(productCode));
            }
        }

        return resultEntries;
    }

    /**
     * @description construct a list of PeriodWrapper objects from a product
     * @param pbEntry The PricebookEntry object containing the period data
     * @return List<PeriodWrapper> A list of initialized PeriodWrapper objects
     */
    private List<PeriodWrapper> constructPeriodList(PricebookEntry pbEntry) {
        List<PeriodWrapper> periodsList = new List<PeriodWrapper>{
            new PeriodWrapper(
                Integer.valueOf(pbEntry.COMM_FirstPeriodStartDay__c),
                Integer.valueOf(pbEntry.COMM_FirstPeriodEndDay__c),
                pbEntry.COMM_FirstPeriodDailyMaximum__c
            ),
            new PeriodWrapper(
                Integer.valueOf(pbEntry.COMM_SecondPeriodStartDay__c),
                Integer.valueOf(pbEntry.COMM_SecondPeriodEndDay__c),
                pbEntry.COMM_SecondPeriodDailyMaximum__c
            ),
            new PeriodWrapper(
                Integer.valueOf(pbEntry.COMM_ThirdPeriodStartDay__c),
                Integer.valueOf(pbEntry.COMM_ThirdPeriodEndDay__c),
                pbEntry.COMM_ThirdPeriodDailyMaximum__c
            ),
            new PeriodWrapper(
                Integer.valueOf(pbEntry.COMM_FourthPeriodStartDay__c),
                Integer.valueOf(pbEntry.COMM_FourthPeriodEndDay__c),
                pbEntry.COMM_FourthPeriodDailyMaximum__c
            )
        };
        return periodsList;
    }

    /**
     * @description Return a matching period from a list of period wrappers based on the specified day number
     *
     * @param periodsList A list of PeriodWrapper objects, each representing a period with start and end day properties
     * @param currentDay The day number to find a matching period for. It is compared against the startDay and endDay properties of each PeriodWrapper in the list
     * @return The first PeriodWrapper from the list for which the specified day number falls within the period's range
     */
    private PeriodWrapper findMatchingPeriod(List<PeriodWrapper> periodsList, Integer currentDay) {
        for (PeriodWrapper period : periodsList) {
            if (currentDay >= period.startDay && currentDay <= period.endDay) {
                return period;
            }
        }
        return null; // No matching period found
    }

    /**
     * @description Define a time period with start and end days and a daily maximum value
     *
     * @param startDay The start day of the period
     * @param endDay The end day of the period
     * @param dailyMax The daily maximum value for the period, as a Decimal
     */
    private class PeriodWrapper {
        Integer startDay;
        Integer endDay;
        Decimal dailyMax;

        /**
         * Constructs a PeriodWrapper with specified start day, end day, and daily maximum
         */
        PeriodWrapper(Integer startDay, Integer endDay, Decimal dailyMax) {
            this.startDay = startDay;
            this.endDay = endDay;
            this.dailyMax = dailyMax;
        }
    }
}