/**
 * @author         Nuno Costa
 * @description    LWC that allows user to build a cron expression to be used by
 *                 the Batch Definition Scheduler. This component is responsable
 *                 for month selection.
 *
 * Modification Log
 * -------------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -------------------------------------------------------------------------------------------
 * Nuno Costa   	01/08/2023      Original version
 * Daniel Lascas    04/08/2023      Changed labels to use Custom Labels (to allow translation)
 **/
import { LightningElement } from "lwc";
const ALL = "*";

import { labels } from "./fw_lwc_cron_builder_month_labels";

export default class fw_lwc_cron_builder_month extends LightningElement {
	label = labels;

	//CRON ELEMENT
	cronMonth = ALL;
	cronDescription = this.label.Every_Month;

	//OPTIONS
	monthFrequencyOption = "1";
	startingMonthOption = "1";
	specificMonthOption = ["JAN"];
	betweenMonthStartOption = "1";
	betweenMonthEndOption = "1";

	//FLAGS
	isEveryMonthChecked = false;
	isStartingAtMonthChecked = false;
	isSpecificMonthChecked = false;
	isBetweenMonthChecked = false;

	monthRadioOption = "everyMonth";

	//HANDLERS
	handleMonthRadioGroupChange(evt) {
		this.monthRadioOption = evt.target.value;
		this.isEveryMonthChecked = this.monthRadioOption === "everyMonth";
		this.isStartingAtMonthChecked = this.monthRadioOption === "startingAtMonth";
		this.isSpecificMonthChecked = this.monthRadioOption === "specificMonth";
		this.isBetweenMonthChecked = this.monthRadioOption === "betweenMonths";
		this.updateCronMonth();
	}

	handleValueChange(evt) {
		switch (evt.target.name) {
			case "monthFrequency":
				this.monthFrequencyOption = evt.target.value;
				break;
			case "startingMonth":
				this.startingMonthOption = evt.target.value;
				break;
			case "specificMonth":
				this.specificMonthOption = evt.target.value;
				break;
			case "betweenMonthStart":
				this.betweenMonthStartOption = evt.target.value;
				break;
			case "betweenMonthEnd":
				this.betweenMonthEndOption = evt.target.value;
				break;
			default:
				break;
		}

		this.updateCronMonth();
	}

	updateCronMonth() {
		if (this.isEveryMonthChecked) {
			this.cronMonth = ALL;
		} else if (this.isStartingAtMonthChecked) {
			this.cronMonth = this.startingMonthOption + "/" + this.monthFrequencyOption;
		} else if (this.isSpecificMonthChecked) {
			this.cronMonth = this.specificMonthOption;
		} else if (this.isBetweenMonthChecked) {
			this.cronMonth = this.betweenMonthStartOption + "-" + this.betweenMonthEndOption;
		}

		this.monthRadioOptions.forEach((option) => {
			if (option.value === this.monthRadioOption && this.isSpecificMonthChecked) {
				let monthList = [];
				this.specificMonthOption.forEach((month) => {
					monthList.push(this.monthsShortObj[month]);
				});
				this.cronDescription = this.label.In + " " + monthList;
			} else if (option.value === this.monthRadioOption) {
				this.cronDescription = option.label;
			}
		});

		this.dispatchEvent(
			new CustomEvent("monthchange", {
				detail: { value: this.cronMonth, label: this.cronDescription }
			})
		);
	}

	//OPTIONS
	get monthRadioOptions() {
		let startingAtMonthLabel = this.label.Months_Starting_in.replace("{0}", this.monthFrequencyOption).replace(
			"{1}",
			this.monthsObj[this.startingMonthOption]
		);
		let betweenMonthLabel = this.label.Every_Month_from.replace("{0}", this.monthsObj[this.betweenMonthStartOption]).replace(
			"{1}",
			this.monthsObj[this.betweenMonthEndOption]
		);
		return [
			{ label: this.label.Every_Month, value: "everyMonth" },
			{ label: startingAtMonthLabel, value: "startingAtMonth" },
			{ label: this.label.Specific_Months, value: "specificMonth" },
			{ label: betweenMonthLabel, value: "betweenMonths" }
		];
	}

	get monthOptions() {
		return [
			{ label: this.label.January, value: "1" },
			{ label: this.label.February, value: "2" },
			{ label: this.label.March, value: "3" },
			{ label: this.label.April, value: "4" },
			{ label: this.label.May, value: "5" },
			{ label: this.label.June, value: "6" },
			{ label: this.label.July, value: "7" },
			{ label: this.label.August, value: "8" },
			{ label: this.label.September, value: "9" },
			{ label: this.label.October, value: "10" },
			{ label: this.label.November, value: "11" },
			{ label: this.label.December, value: "12" }
		];
	}

	get monthShortOptions() {
		return [
			{ label: this.label.January, value: "JAN" },
			{ label: this.label.February, value: "FEB" },
			{ label: this.label.March, value: "MAR" },
			{ label: this.label.April, value: "APR" },
			{ label: this.label.May, value: "MAY" },
			{ label: this.label.June, value: "JUN" },
			{ label: this.label.July, value: "JUL" },
			{ label: this.label.August, value: "AUG" },
			{ label: this.label.September, value: "SEP" },
			{ label: this.label.October, value: "OCT" },
			{ label: this.label.November, value: "NOV" },
			{ label: this.label.December, value: "DEC" }
		];
	}

	get monthFrequencyOptions() {
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
			{ label: "12", value: "12" }
		];
	}

	monthsObj = {
		1: this.label.January,
		2: this.label.February,
		3: this.label.March,
		4: this.label.April,
		5: this.label.May,
		6: this.label.June,
		7: this.label.July,
		8: this.label.August,
		9: this.label.September,
		10: this.label.October,
		11: this.label.November,
		12: this.label.December
	};

	monthsShortObj = {
		JAN: this.label.January,
		FEB: this.label.February,
		MAR: this.label.March,
		APR: this.label.April,
		MAY: this.label.May,
		JUN: this.label.June,
		JUL: this.label.July,
		AUG: this.label.August,
		SEP: this.label.September,
		OCT: this.label.October,
		NOV: this.label.November,
		DEC: this.label.December
	};
}