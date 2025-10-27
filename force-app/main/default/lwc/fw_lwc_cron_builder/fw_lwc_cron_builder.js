/**
 * @author         Nuno Costa
 * @description    LWC that allows user to build a cron expression to be used by
 *                 the Batch Definition Scheduler.
 *                 Uses Custom Labels to allow label translation, the used labels are
 *                 under the "Batch Framework Scheduler" Category
 *
 * Modification Log
 * -------------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -------------------------------------------------------------------------------------------
 * Nuno Costa   	01/08/2023      Original version
 * Daniel Lascas    04/08/2023      Changed labels to use Custom Labels
 **/
import { LightningElement, api } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

import { labels } from "./fw_lwc_cron_builder_labels";

const ALL = "*";
export default class fw_lwc_cron_builder extends LightningElement {
	//CRON ELEMENTS
	cronSecond = "0";
	cronMinute = "0";
	cronHour = "0";
	cronDayMonth = "?";
	cronMonth = ALL;
	cronDayWeek = ALL;
	cronYear = ALL;

	label = labels;

	cronSecondDescription = "";
	cronMinuteDescription = "";
	cronHourDescription = this.label.Every_Hour;
	cronDayDescription = this.label.Every_Day;
	cronMonthDescription = this.label.Every_Month;
	cronYearDescription = this.label.Every_Year;

	connectedCallback() {
		this.updateCronExpression();
	}

	handleSecondsChange(evt) {
		this.cronSecond = evt.target.value;
		this.cronSecondDescription = this.cronSecond !== "0" ? this.label.Seconds_after_Minute.replace("{0}", this.cronSecond) + "," : "";

		this.updateCronExpression();
	}

	handleMinutesChange(evt) {
		this.cronMinute = evt.target.value;
		this.cronMinuteDescription = this.cronMinute !== "0" ? this.label.Minutes_after_Hour.replace("{0}", this.cronMinute) + "," : "";
		this.updateCronExpression();
	}

	handleHourChange(evt) {
		this.cronHour = evt.detail.value;
		this.cronHourDescription = evt.detail.label;
		this.updateCronExpression();
	}

	handleDayWeekChange(evt) {
		this.cronDayWeek = evt.detail.value;
		this.cronDayDescription = evt.detail.label;
		this.updateCronExpression();
	}

	handleDayMonthChange(evt) {
		this.cronDayMonth = evt.detail.value;
		this.cronDayDescription = evt.detail.label;
		this.updateCronExpression();
	}

	handleMonthChange(evt) {
		this.cronMonth = evt.detail.value;
		this.cronMonthDescription = evt.detail.label;
		this.updateCronExpression();
	}

	handleYearChange(evt) {
		this.cronYear = evt.detail.value;
		this.cronYearDescription = evt.detail.label;
		this.updateCronExpression();
	}

	updateCronExpression() {
		this.dispatchEvent(new FlowAttributeChangeEvent("cronExpression", this.cronExpression));
		this.dispatchEvent(new FlowAttributeChangeEvent("cronDescription", this.cronDescription));
	}

	//GETTERS
	@api
	get cronExpression() {
		return (
			this.cronSecond +
			" " +
			this.cronMinute +
			" " +
			this.cronHour +
			" " +
			this.cronDayMonth +
			" " +
			this.cronMonth +
			" " +
			this.cronDayWeek +
			" " +
			this.cronYear
		);
	}

	@api
	get cronDescription() {
		return (
			this.cronHourDescription +
			", " +
			this.cronMinuteDescription +
			this.cronSecondDescription +
			this.cronDayDescription +
			", " +
			this.cronMonthDescription +
			", " +
			this.cronYearDescription
		);
	}

	get timeOptions() {
		return [
			{ label: "0", value: "0" },
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
			{ label: "59", value: "59" }
		];
	}
}