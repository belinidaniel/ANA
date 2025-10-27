/**
 * @author         Nuno Costa
 * @description    LWC that allows user to build a cron expression to be used by
 *                 the Batch Definition Scheduler. This component is responsable
 *                 for day selection.
 *
 * Modification Log
 * -------------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -------------------------------------------------------------------------------------------
 * Nuno Costa   	01/08/2023      Original version
 * Daniel Lascas    04/08/2023      Changed labels to use Custom Labels (to allow translation)
 **/
import { LightningElement } from "lwc";

import { labels } from "./fw_lwc_cron_builder_day_labels";

const ALL = "*";
const NO_SPECIFIC_VALUE = "?";

export default class fw_lwc_cron_builder_day extends LightningElement {
	label = labels;

	cronDayMonth = NO_SPECIFIC_VALUE;
	cronDayWeek = ALL;
	cronDescription = this.label.Every_Day;

	dayOfWeekFrequencyOption = "1";
	startDayOfWeekOption = "1";
	specificDayOfWeekOption = ["SUN"];
	lastDayOfWeekOfMonthOption = "1";
	dayOfMonthFrequencyOption = "1";
	startDayOfMonthOption = "1";
	specificDayOfMonthOption = ["1"];
	lastDaysBeforeEndMonthOption = "1";
	nearestWeekDayOption = "1";
	indexOfWeekDayOption = "1";
	indexOfWeekNameOption = "1";

	//FLAGS
	isEveryDayWeekChecked = false;
	isStartingAtDayOfWeekChecked = false;
	isSpecificDayOfWeekChecked = false;
	isStartingAtDayOfMonthChecked = false;
	isSpecificDayOfMonthChecked = false;
	isLastDayOfMonthChecked = false;
	isLastWeekDayOfMonthChecked = false;
	isLastDayOfWeekOfMonthChecked = false;
	isLastDaysBeforeEndMonthChecked = false;
	isNearestWeekDayChecked = false;
	isIndexOfWeekDayChecked = false;

	dayRadioOption = "everyDay";

	//HANDLERS
	handleDayRadioGroupChange(evt) {
		this.dayRadioOption = evt.target.value;
		this.isEveryDayWeekChecked = this.dayRadioOption === "everyDay";
		this.isStartingAtDayOfWeekChecked = this.dayRadioOption === "startingAtDayOfWeek";
		this.isStartingAtDayOfMonthChecked = this.dayRadioOption === "startingAtDayOfMonth";
		this.isSpecificDayOfWeekChecked = this.dayRadioOption === "specificDayOfWeek";
		this.isSpecificDayOfMonthChecked = this.dayRadioOption === "specificDayOfMonth";
		this.isLastDayOfMonthChecked = this.dayRadioOption === "lastDayOfMonth";
		this.isLastWeekDayOfMonthChecked = this.dayRadioOption === "lastWeekDayOfMonth";
		this.isLastDayOfWeekOfMonthChecked = this.dayRadioOption === "lastDayOfWeekOfMonth";
		this.isLastDaysBeforeEndMonthChecked = this.dayRadioOption === "lastDaysBeforeEndMonth";
		this.isNearestWeekDayChecked = this.dayRadioOption === "nearestWeekDay";
		this.isIndexOfWeekDayChecked = this.dayRadioOption === "indexOfWeekDay";
		this.updateDayCron();
	}

	handleValueChange(evt) {
		switch (evt.target.name) {
			case "dayOfWeekFrequency":
				this.dayOfWeekFrequencyOption = evt.target.value;
				break;
			case "startDayOfWeek":
				this.startDayOfWeekOption = evt.target.value;
				break;
			case "dayOfMonthFrequency":
				this.dayOfMonthFrequencyOption = evt.target.value;
				break;
			case "startDayOfMonth":
				this.startDayOfMonthOption = evt.target.value;
				break;
			case "specificDayOfWeek":
				this.specificDayOfWeekOption = evt.target.value;
				break;
			case "specificDayOfMonth":
				this.specificDayOfMonthOption = evt.target.value;
				break;
			case "lastDayOfWeekOfMonth":
				this.lastDayOfWeekOfMonthOption = evt.target.value;
				break;
			case "lastDaysBeforeEndMonth":
				this.lastDaysBeforeEndMonthOption = evt.target.value;
				break;
			case "nearestWeekDay":
				this.nearestWeekDayOption = evt.target.value;
				break;
			case "indexOfWeekDay":
				this.indexOfWeekDayOption = evt.target.value;
				break;
			case "indexOfWeekName":
				this.indexOfWeekNameOption = evt.target.value;
				break;
			default:
				break;
		}

		this.updateDayCron();
	}

	updateDayCron() {
		if (this.isEveryDayWeekChecked) {
			this.cronDayWeek = ALL;
			this.cronDayMonth = NO_SPECIFIC_VALUE;
		} else if (this.isStartingAtDayOfWeekChecked) {
			this.cronDayWeek = this.startDayOfWeekOption + "/" + this.dayOfWeekFrequencyOption;
			this.cronDayMonth = NO_SPECIFIC_VALUE;
		} else if (this.isStartingAtDayOfMonthChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = this.startDayOfMonthOption + "/" + this.dayOfMonthFrequencyOption;
		} else if (this.isSpecificDayOfWeekChecked) {
			this.cronDayWeek = this.specificDayOfWeekOption;
			this.cronDayMonth = NO_SPECIFIC_VALUE;
		} else if (this.isSpecificDayOfMonthChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = this.specificDayOfMonthOption;
		} else if (this.isLastDayOfMonthChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = "L";
		} else if (this.isLastWeekDayOfMonthChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = "LW";
		} else if (this.isLastDayOfWeekOfMonthChecked) {
			this.cronDayWeek = this.lastDayOfWeekOfMonthOption + "L";
			this.cronDayMonth = NO_SPECIFIC_VALUE;
		} else if (this.isLastDaysBeforeEndMonthChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = "L-" + this.lastDaysBeforeEndMonthOption;
		} else if (this.isNearestWeekDayChecked) {
			this.cronDayWeek = NO_SPECIFIC_VALUE;
			this.cronDayMonth = this.nearestWeekDayOption + "W";
		} else if (this.isIndexOfWeekDayChecked) {
			this.cronDayWeek = this.indexOfWeekNameOption + "#" + this.indexOfWeekDayOption;
			this.cronDayMonth = NO_SPECIFIC_VALUE;
		}

		this.dayRadioOptions.forEach((option) => {
			if (option.value === this.dayRadioOption && this.isSpecificDayOfWeekChecked) {
				let dayOfWeekList = [];
				this.specificDayOfWeekOption.forEach((dayOfWeek) => {
					dayOfWeekList.push(this.daysOfWeekShortObj[dayOfWeek]);
				});
				this.cronDescription = this.label.On_every + " " + dayOfWeekList;
			} else if (option.value === this.dayRadioOption && this.isSpecificDayOfMonthChecked) {
				let dayOfMonthList = [];
				this.specificDayOfMonthOption.forEach((dayOfMonth) => {
					dayOfMonthList.push(this.indexDaysOfMonthObj[dayOfMonth]);
				});
				this.cronDescription = this.label.On_the + " " + dayOfMonthList.sort() + " " + this.label.Day;
			} else if (option.value === this.dayRadioOption) {
				this.cronDescription = option.label;
			}

			/* if(option.value == this.dayRadioOption){
				this.cronDescription = option.label;
			} */
		});

		this.dispatchEvent(
			new CustomEvent("dayweekchange", {
				detail: { value: this.cronDayWeek, label: this.cronDescription }
			})
		);

		this.dispatchEvent(
			new CustomEvent("daymonthchange", {
				detail: { value: this.cronDayMonth, label: this.cronDescription }
			})
		);
	}

	//OPTIONS
	get dayRadioOptions() {
		let startingAtDayOfWeekLabel = this.label.Days_starting_on.replace("{0}", this.dayOfWeekFrequencyOption).replace(
			"{1}",
			this.daysOfWeekObj[this.startDayOfWeekOption]
		);
		let startingAtDayOfMonthLabel = this.label.Days_starting_on_the.replace("{0}", this.dayOfMonthFrequencyOption).replace(
			"{1}",
			this.indexDaysOfMonthObj[this.startDayOfMonthOption]
		);
		let lastDayOfWeekOfMonthLabel = this.label.On_the_last + " " + this.daysOfWeekObj[this.lastDayOfWeekOfMonthOption] + " " + this.label.Of_the_month;
		let lastDaysBeforeEndMonthLabel = this.label.On_the_last + " " + this.lastDaysBeforeEndMonthOption + " " + this.label.Days_before_Monthend;
		let nearestWeekDayLabel = this.label.Nearest_weekday + " " + this.indexDaysOfMonthObj[this.nearestWeekDayOption] + " " + this.label.Of_the_month;
		let indexOfWeekDayLabel =
			this.label.On_the +
			" " +
			this.indexDaysOfMonthObj[this.indexOfWeekDayOption] +
			" " +
			this.daysOfWeekObj[this.indexOfWeekNameOption] +
			" " +
			this.label.Of_the_month;

		return [
			{ label: this.label.Every_Day, value: "everyDay" },
			{ label: startingAtDayOfWeekLabel, value: "startingAtDayOfWeek" },
			{ label: startingAtDayOfMonthLabel, value: "startingAtDayOfMonth" },
			{ label: this.label.Specific_Weekday, value: "specificDayOfWeek" },
			{ label: this.label.Specific_Monthday, value: "specificDayOfMonth" },
			{ label: this.label.Lastday_Month, value: "lastDayOfMonth" },
			{ label: this.label.Lastweekday_Month, value: "lastWeekDayOfMonth" },
			{ label: lastDayOfWeekOfMonthLabel, value: "lastDayOfWeekOfMonth" },
			{ label: lastDaysBeforeEndMonthLabel, value: "lastDaysBeforeEndMonth" },
			{ label: nearestWeekDayLabel, value: "nearestWeekDay" },
			{ label: indexOfWeekDayLabel, value: "indexOfWeekDay" }
		];
	}

	get dayOfWeekNumberOptions() {
		return [
			{ label: "1", value: "1" },
			{ label: "2", value: "2" },
			{ label: "3", value: "3" },
			{ label: "4", value: "4" },
			{ label: "5", value: "5" },
			{ label: "6", value: "6" },
			{ label: "7", value: "7" }
		];
	}

	get dayOfWeekNameOptions() {
		return [
			{ label: this.label.Sunday, value: "1" },
			{ label: this.label.Monday, value: "2" },
			{ label: this.label.Tuesday, value: "3" },
			{ label: this.label.Wednesday, value: "4" },
			{ label: this.label.Thursday, value: "5" },
			{ label: this.label.Friday, value: "6" },
			{ label: this.label.Saturday, value: "7" }
		];
	}

	get dayOfWeekShortOptions() {
		return [
			{ label: this.label.Sunday, value: "SUN" },
			{ label: this.label.Monday, value: "MON" },
			{ label: this.label.Tuesday, value: "TUE" },
			{ label: this.label.Wednesday, value: "WED" },
			{ label: this.label.Thursday, value: "THU" },
			{ label: this.label.Friday, value: "FRI" },
			{ label: this.label.Saturday, value: "SAT" }
		];
	}

	get dayOfMonthOptions() {
		return [
			{ label: "1", value: "1" },
			{ label: "2", value: "2" },
			{ label: "3", value: "3" },
			{ label: "4", value: "4" },
			{ label: "5", value: "5" },
			{ label: "6", value: "6" },
			{ label: "7", value: "7" },
			{ label: "8", value: "8" },
			{ label: "9", value: "9" },
			{ label: "10", value: "10" },
			{ label: "11", value: "11" },
			{ label: "12", value: "12" },
			{ label: "13", value: "13" },
			{ label: "14", value: "14" },
			{ label: "15", value: "15" },
			{ label: "16", value: "16" },
			{ label: "17", value: "17" },
			{ label: "18", value: "18" },
			{ label: "19", value: "19" },
			{ label: "20", value: "20" },
			{ label: "21", value: "21" },
			{ label: "22", value: "22" },
			{ label: "23", value: "23" },
			{ label: "24", value: "24" },
			{ label: "25", value: "25" },
			{ label: "26", value: "26" },
			{ label: "27", value: "27" },
			{ label: "28", value: "28" },
			{ label: "29", value: "29" },
			{ label: "30", value: "30" },
			{ label: "31", value: "31" }
		];
	}

	get indexOfMonthOptions() {
		return [
			{ label: this.label.First, value: "1" },
			{ label: this.label.Second, value: "2" },
			{ label: this.label.Third, value: "3" },
			{ label: this.label.Fourth, value: "4" },
			{ label: this.label.Fifth, value: "5" },
			{ label: this.label.Sixth, value: "6" },
			{ label: this.label.Seventh, value: "7" },
			{ label: this.label.Eighth, value: "8" },
			{ label: this.label.Ninth, value: "9" },
			{ label: this.label.Tenth, value: "10" },
			{ label: this.label.Eleventh, value: "11" },
			{ label: this.label.Twelfth, value: "12" },
			{ label: this.label.Thirteenth, value: "13" },
			{ label: this.label.Fourteenth, value: "14" },
			{ label: this.label.Fifteenth, value: "15" },
			{ label: this.label.Sixteenth, value: "16" },
			{ label: this.label.Seventeenth, value: "17" },
			{ label: this.label.Eighteenth, value: "18" },
			{ label: this.label.Nineteenth, value: "19" },
			{ label: this.label.Twentieth, value: "20" },
			{ label: this.label.Twenty_First, value: "21" },
			{ label: this.label.Twenty_Second, value: "22" },
			{ label: this.label.Twenty_Third, value: "23" },
			{ label: this.label.Twenty_Fourth, value: "24" },
			{ label: this.label.Twenty_Fifth, value: "25" },
			{ label: this.label.Twenty_Sixth, value: "26" },
			{ label: this.label.Twenty_Seventh, value: "27" },
			{ label: this.label.Twenty_Eighth, value: "28" },
			{ label: this.label.Twenty_Ninth, value: "29" },
			{ label: this.label.Thirtieth, value: "30" },
			{ label: this.label.Thirty_First, value: "31" }
		];
	}

	get indexOfWeekDayOptions() {
		return [
			{ label: this.label.First, value: "1" },
			{ label: this.label.Second, value: "2" },
			{ label: this.label.Third, value: "3" },
			{ label: this.label.Fourth, value: "4" },
			{ label: this.label.Fifth, value: "5" }
		];
	}

	daysOfWeekObj = {
		1: this.label.Sunday,
		2: this.label.Monday,
		3: this.label.Tuesday,
		4: this.label.Wednesday,
		5: this.label.Thursday,
		6: this.label.Friday,
		7: this.label.Saturday
	};

	daysOfWeekShortObj = {
		SUN: this.label.Sunday,
		MON: this.label.Monday,
		TUE: this.label.Tuesday,
		WED: this.label.Wednesday,
		THU: this.label.Thursday,
		FRI: this.label.Friday,
		SAT: this.label.Saturday
	};

	indexDaysOfMonthObj = {
		1: this.label.First,
		2: this.label.Second,
		3: this.label.Third,
		4: this.label.Fourth,
		5: this.label.Fifth,
		6: this.label.Sixth,
		7: this.label.Seventh,
		8: this.label.Eighth,
		9: this.label.Ninth,
		10: this.label.Tenth,
		11: this.label.Eleventh,
		12: this.label.Twelfth,
		13: this.label.Thirteenth,
		14: this.label.Fourteenth,
		15: this.label.Fifteenth,
		16: this.label.Sixteenth,
		17: this.label.Seventeenth,
		18: this.label.Eighteenth,
		19: this.label.Nineteenth,
		20: this.label.Twentieth,
		21: this.label.Twenty_First,
		22: this.label.Twenty_Second,
		23: this.label.Twenty_Third,
		24: this.label.Twenty_Fourth,
		25: this.label.Twenty_Fifth,
		26: this.label.Twenty_Sixth,
		27: this.label.Twenty_Seventh,
		28: this.label.Twenty_Eighth,
		29: this.label.Twenty_Ninth,
		30: this.label.Thirtieth,
		31: this.label.Thirty_First
	};
}