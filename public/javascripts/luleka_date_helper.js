if(typeof(Luleka) == "undefined")
	throw "Luleka.DateHelper requires Luleka to be loaded.";

Luleka.DateHelper = {
	
	timeAgoInWords: function(from, includeSeconds) {
		return this.distanceOfTimeInWords(from, new Date().getTime(), includeSeconds);
	},
	
	distanceOfTimeInWords: function(from, to, includeSeconds) {
		var secondsAgo = Math.floor(Math.abs(to - from) / 1000);
		var minutesAgo = Math.abs(Math.floor(secondsAgo / 60));
		var hoursAgo  = Math.round(minutesAgo / 60);
		var daysAgo  = Math.round(minutesAgo / 1440);
		var monthsAgo  = Math.round(minutesAgo / 43200);
		var yearsAgo  = Math.round(minutesAgo / 525960);
		var tiw = ''
		
		if (includeSeconds && secondsAgo >= 0 && secondsAgo <= 19) {
			tiw = Luleka.I18n.translations.get('less_than_x_seconds')[1].gsub(/%d/, secondsAgo);
		} else if(includeSeconds && secondsAgo >= 20 && secondsAgo <= 39) {
			tiw = Luleka.I18n.translations.get('half_a_minute');
		} else if(includeSeconds && secondsAgo >= 40 && secondsAgo <= 59) {
			tiw = Luleka.I18n.translations.get('less_than_x_minutes')[0].gsub(/%d/, '1');
		} else if(minutesAgo == 0) {
			tiw = Luleka.I18n.translations.get('less_than_x_minutes')[0].gsub(/%d/, '1');
		}	else if(minutesAgo == 1) {
			tiw = "1 " + Luleka.I18n.translations.get('minute')[0];
		}	else if(minutesAgo < 45) {
			tiw = minutesAgo + ' ' + Luleka.I18n.translations.get('minute')[1];
		} else if(minutesAgo < 90) {
			tiw = Luleka.I18n.translations.get('about_x_hours')[0].gsub(/%d/, '1');
		} else if(minutesAgo < 1440) {
			tiw = Luleka.I18n.translations.get('about_x_hours')[1].gsub(/%d/, hoursAgo);
		} else if(minutesAgo < 2880) {
			tiw = "1 " + Luleka.I18n.translations.get('day')[0];
		} else if(minutesAgo < 43200) {
			tiw = daysAgo + ' ' + Luleka.I18n.translations.get('day')[1];
	  } else if(minutesAgo < 86400) {
			tiw = Luleka.I18n.translations.get('about_x_months')[0].gsub(/%d/, '1');
		}	else if(minutesAgo < 525960) {
			tiw = monthsAgo + ' ' + Luleka.I18n.translations.get('month')[1];
		} else if(minutesAgo < 1051920) {
			tiw = Luleka.I18n.translations.get('about_x_years')[0].gsub(/%d/, '1');
		}	else {
			tiw = Luleka.I18n.translations.get('over_x_years')[1].gsub(/%d/, yearsAgo);
		} 
		return tiw;
	},
	
	countdownInWords: function(id, ends) {
		if (ends > new Date().getTime()) {
			if ($(id)) {
				$(id).innerHTML = Luleka.DateHelper.timeAgoInWords(ends, 1);
			}
			setTimeout("Luleka.DateHelper.countdownInWords('" + id + "', " + ends + ")", 1000);
		} else {
			if ($(id)) {
				$(id).innerHTML = Luleka.I18n.translations.get('expired');
			}
		}
	}
	
}