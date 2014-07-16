if(typeof(Luleka) == "undefined")
	throw "Luleka.I18n requires Luleka namespace to be loaded.";

Luleka.I18n = {
	translations: $H({
		'less_than': 'less than',
		'about': 'about',
		'over': 'over',
		'expired': 'expired',
		'half_a_minute': 'half a minute',
		'year': ['year','years'],
		'day': ['day','days'],
		'month': ['month','months'],
		'hour': ['hour','hours'],
		'minute': ['minute','minutes'],
		'second': ['second','seconds']
	})
}