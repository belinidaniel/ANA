import { LightningElement } from 'lwc';

import { labels } from "./fw_lwc_cron_builder_hour_labels";
const ALL = '*';
export default class fw_lwc_cron_builder_hour extends LightningElement {
	label = labels;
	//CRON ELEMENTS
	cronHour = '0';
	cronDescription = this.label.Every_Hour;

	

	//OPTIONS
	hourFrequencyOption = '1';
	startingHourOption = '0';
	specificHourOption = ['0'];
	betweenHourStartOption = '0';
	betweenHourEndOption = '0';

	//FLAGS
	isEveryHourChecked = false;
	isStartingAtHourChecked = false;
	isSpecificHourChecked = false;
	isBetweenHourChecked = false;

	hourRadioOption = 'everyHour';

	//HANDLERS
	handleHourRadioGroupChange(evt){
		this.hourRadioOption = evt.target.value;
		this.isEveryHourChecked = this.hourRadioOption == 'everyHour';
		this.isStartingAtHourChecked = this.hourRadioOption == 'startingAtHour';
		this.isSpecificHourChecked = this.hourRadioOption == 'specificHour';
		this.isBetweenHourChecked = this.hourRadioOption == 'betweenHours';
		this.updateCronHour();
	}

	handleValueChange(evt){
		switch (evt.target.name) {
			case 'hourFrequency':
				this.hourFrequencyOption = evt.target.value;
				break;
			case 'startingHour':
				this.startingHourOption = evt.target.value;
				break;
			case 'specificHour':
				this.specificHourOption = evt.target.value;
				break;
			case 'betweenHourStart':
				this.betweenHourStartOption = evt.target.value;
				break;
			case 'betweenHourEnd':
				this.betweenHourEndOption = evt.target.value;
				break;
			default:
				break;
		}

		this.updateCronHour();
	}

	updateCronHour(){
		if(this.isEveryHourChecked){
			this.cronHour = ALL;
		} else if(this.isStartingAtHourChecked) {
			this.cronHour = this.startingHourOption + '/' + this.hourFrequencyOption;
		} else if(this.isSpecificHourChecked) {
			this.cronHour = this.specificHourOption;
		} else if(this.isBetweenHourChecked) {
			this.cronHour = this.betweenHourStartOption + '-' + this.betweenHourEndOption;
		}

		this.hourRadioOptions.forEach(option => {
			if(option.value == this.hourRadioOption && this.isSpecificHourChecked){
				let hourList = [];
				this.specificHourOption.forEach(hour => {
					hourList.push(this.hourOptionsObj[hour]);
				});
				this.cronDescription = this.label.At +" " + hourList.sort();
			} else if(option.value == this.hourRadioOption){
				this.cronDescription = option.label;
			}
		});

		this.dispatchEvent(new CustomEvent('hourchange', {
			detail: {value: this.cronHour, label: this.cronDescription}
		}));
	}

	//OPTIONS
	get hourRadioOptions(){
		let startingAtHourLabel = this.label.Every + ' ' + this.hourFrequencyOption + ' ' + this.label.Hours_Sarting_At + ' ' + this.hourOptionsObj[this.startingHourOption];
		let betweenHourLabel = this.label.Every_Hour_From + ' '  + this.hourOptionsObj[this.betweenHourStartOption] + ' ' + this.label.To + ' ' + this.hourOptionsObj[this.betweenHourEndOption];
		return [
			{label: this.label.Every_Hour, value:'everyHour'},
			{label: startingAtHourLabel, value:'startingAtHour'},
			{label: this.label.At_Specific_Hours, value:'specificHour'},
			{label: betweenHourLabel, value:'betweenHours'}
		]
	}

	get hourOptions() {
        return [
			{ label: '00:00', value: '0' },
            { label: '01:00', value: '1' },
            { label: '02:00', value: '2' },
            { label: '03:00', value: '3' },
            { label: '04:00', value: '4' },
            { label: '05:00', value: '5' },
            { label: '06:00', value: '6' },
            { label: '07:00', value: '7' },
            { label: '08:00', value: '8' },
            { label: '09:00', value: '9' },
            { label: '10:00', value: '10' },
            { label: '11:00', value: '11' },
            { label: '12:00', value: '12' },
            { label: '13:00', value: '13' },
            { label: '14:00', value: '14' },
            { label: '15:00', value: '15' },
            { label: '16:00', value: '16' },
            { label: '17:00', value: '17' },
            { label: '18:00', value: '18' },
            { label: '19:00', value: '19' },
            { label: '20:00', value: '20' },
            { label: '21:00', value: '21' },
            { label: '22:00', value: '22' },
            { label: '23:00', value: '23' }
        ];
    }

	get hourFrequencyOptions() {
        return [
            { label: '1 Hour', value: '1' },
            { label: '2 Hours', value: '2' },
            { label: '3 Hours', value: '3' },
            { label: '4 Hours', value: '4' },
            { label: '5 Hours', value: '5' },
            { label: '6 Hours', value: '6' },
            { label: '7 Hours', value: '7' },
            { label: '8 Hours', value: '8' },
            { label: '9 Hours', value: '9' },
            { label: '10 Hours', value: '10' },
            { label: '11 Hours', value: '11' },
            { label: '12 Hours', value: '12' },
            { label: '13 Hours', value: '13' },
            { label: '14 Hours', value: '14' },
            { label: '15 Hours', value: '15' },
            { label: '16 Hours', value: '16' },
            { label: '17 Hours', value: '17' },
            { label: '18 Hours', value: '18' },
            { label: '19 Hours', value: '19' },
            { label: '20 Hours', value: '20' },
            { label: '21 Hours', value: '21' },
            { label: '22 Hours', value: '22' },
            { label: '23 Hours', value: '23' }
        ];
    }

	hourOptionsObj = {
        0: '00:00',
		1: '01:00',
		2: '02:00',
		3: '03:00',
		4: '04:00',
		5: '05:00',
		6: '06:00',
		7: '07:00',
		8: '08:00',
		9: '09:00',
		10: '10:00',
		11: '11:00',
		12: '12:00',
		13: '13:00',
		14: '14:00',
		15: '15:00',
		16: '16:00',
		17: '17:00',
		18: '18:00',
		19: '19:00',
		20: '20:00',
		21: '21:00',
		22: '22:00',
		23: '23:00'
    };
}