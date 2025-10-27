/**
 * @author         Nuno Costa
 * @description    LWC that allows user to build a cron expression to be used by
 *                 the Batch Definition Scheduler. This component is responsable
 *                 for year selection.
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

import { labels } from "./fw_lwc_cron_builder_year_labels";

export default class fw_lwc_cron_builder_year extends LightningElement {
	label = labels;

	//CRON ELEMENT
	cronYear = ALL;
	cronDescription = this.label.Every_Year;

	//OPTIONS
	yearFrequencyOption = "1";
	startingYearOption;
	specificYearOption;
	betweenYearStartOption;
	betweenYearEndOption;

	//FLAGS
	isEveryYearChecked = false;
	isStartingAtYearChecked = false;
	isSpecificYearChecked = false;
	isBetweenYearChecked = false;

	yearRadioOption = "everyYear";
	yearOptions;

	connectedCallback() {
		//Retrieves current Year
		var currentYear = new Date().getFullYear();
		var yearOptionsFromNow = [];

		//Set Default Options as current Year
		this.startingYearOption = currentYear.toString();
		this.specificYearOption = [currentYear.toString()];
		this.betweenYearStartOption = currentYear.toString();
		this.betweenYearEndOption = currentYear.toString();

		//Create Year options between current year to 100 years from now
		for (let index = currentYear; index < currentYear + 100; index++) {
			let newOption = { label: index.toString(), value: index.toString() };
			yearOptionsFromNow.push(newOption);
		}
		this.yearOptions = yearOptionsFromNow;
	}

	//HANDLERS
	handleYearRadioGroupChange(evt) {
		this.yearRadioOption = evt.target.value;
		this.isEveryYearChecked = this.yearRadioOption === "everyYear";
		this.isStartingAtYearChecked = this.yearRadioOption === "startingAtYear";
		this.isSpecificYearChecked = this.yearRadioOption === "specificYear";
		this.isBetweenYearChecked = this.yearRadioOption === "betweenYears";
		this.updateCronYear();
	}

	handleValueChange(evt) {
		switch (evt.target.name) {
			case "yearFrequency":
				this.yearFrequencyOption = evt.target.value;
				break;
			case "startingYear":
				this.startingYearOption = evt.target.value;
				break;
			case "specificYear":
				this.specificYearOption = evt.target.value;
				break;
			case "betweenYearStart":
				this.betweenYearStartOption = evt.target.value;
				break;
			case "betweenYearEnd":
				this.betweenYearEndOption = evt.target.value;
				break;
			default:
				break;
		}

		this.updateCronYear();
	}

	updateCronYear() {
		if (this.isEveryYearChecked) {
			this.cronYear = ALL;
		} else if (this.isStartingAtYearChecked) {
			this.cronYear = this.startingYearOption + "/" + this.yearFrequencyOption;
		} else if (this.isSpecificYearChecked) {
			this.cronYear = this.specificYearOption;
		} else if (this.isBetweenYearChecked) {
			this.cronYear = this.betweenYearStartOption + "-" + this.betweenYearEndOption;
		}

		this.yearRadioOptions.forEach((option) => {
			if (option.value === this.yearRadioOption && this.isSpecificYearChecked) {
				this.cronDescription = this.label.In + " " + this.specificYearOption;
			} else if (option.value === this.yearRadioOption) {
				this.cronDescription = option.label;
			}
		});

		this.dispatchEvent(
			new CustomEvent("yearchange", {
				detail: { value: this.cronYear, label: this.cronDescription }
			})
		);
	}

	//OPTIONS
	get yearRadioOptions() {
		let startingAtYearLabel = this.label.Years_Starting_in.replace("{0}", this.yearFrequencyOption).replace("{1}", this.startingYearOption);
		let betweenYearLabel = this.label.Every_Year_from.replace("{0}", this.betweenYearStartOption).replace("{1}", this.betweenYearEndOption);
		return [
			{ label: this.label.Every_Year, value: "everyYear" },
			{ label: startingAtYearLabel, value: "startingAtYear" },
			{ label: this.label.Specific_Years, value: "specificYear" },
			{ label: betweenYearLabel, value: "betweenYears" }
		];
	}

	get yearFrequencyOptions() {
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
			{ label: "31", value: "31" },
			{ label: "32", value: "32" },
			{ label: "33", value: "33" },
			{ label: "34", value: "34" },
			{ label: "35", value: "35" },
			{ label: "36", value: "36" },
			{ label: "37", value: "37" },
			{ label: "38", value: "38" },
			{ label: "39", value: "39" },
			{ label: "40", value: "40" },
			{ label: "41", value: "41" },
			{ label: "42", value: "42" },
			{ label: "43", value: "43" },
			{ label: "44", value: "44" },
			{ label: "45", value: "45" },
			{ label: "46", value: "46" },
			{ label: "47", value: "47" },
			{ label: "48", value: "48" },
			{ label: "49", value: "49" },
			{ label: "50", value: "50" },
			{ label: "51", value: "51" },
			{ label: "52", value: "52" },
			{ label: "53", value: "53" },
			{ label: "54", value: "54" },
			{ label: "55", value: "55" },
			{ label: "56", value: "56" },
			{ label: "57", value: "57" },
			{ label: "58", value: "58" },
			{ label: "59", value: "59" },
			{ label: "60", value: "60" },
			{ label: "61", value: "61" },
			{ label: "62", value: "62" },
			{ label: "63", value: "63" },
			{ label: "64", value: "64" },
			{ label: "65", value: "65" },
			{ label: "66", value: "66" },
			{ label: "67", value: "67" },
			{ label: "68", value: "68" },
			{ label: "69", value: "69" },
			{ label: "70", value: "70" },
			{ label: "71", value: "71" },
			{ label: "72", value: "72" },
			{ label: "73", value: "73" },
			{ label: "74", value: "74" },
			{ label: "75", value: "75" },
			{ label: "76", value: "76" },
			{ label: "77", value: "77" },
			{ label: "78", value: "78" },
			{ label: "79", value: "79" },
			{ label: "80", value: "80" },
			{ label: "81", value: "81" },
			{ label: "82", value: "82" },
			{ label: "83", value: "83" },
			{ label: "84", value: "84" },
			{ label: "85", value: "85" },
			{ label: "86", value: "86" },
			{ label: "87", value: "87" },
			{ label: "88", value: "88" },
			{ label: "89", value: "89" },
			{ label: "90", value: "90" },
			{ label: "91", value: "91" },
			{ label: "92", value: "92" },
			{ label: "93", value: "93" },
			{ label: "94", value: "94" },
			{ label: "95", value: "95" },
			{ label: "96", value: "96" },
			{ label: "97", value: "97" },
			{ label: "98", value: "98" },
			{ label: "99", value: "99" },
			{ label: "100", value: "100" }
		];
	}
}