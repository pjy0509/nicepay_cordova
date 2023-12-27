var exec = require('cordova/exec')

window.Nicepay = {
	SYSTEM: "@SYSTEM",

	PayMethod: {
		Card: "CARD",
		VirtualBank: "VBANK",
		CellPhone: "CELLPHONE",
		SSGBank: "SSG_BANK",
		GiftSSG: "GIFT_SSG",
		GiftCulture: "GIFT_CULT",
		CMSBank: "CMS_BANK",
		ALL_PAY_METHOD: "CARD,VBANK,CELLPHONE,SSG_BANK,GIFT_SSG,GIFT_CULT,CMS_BANK"
	},

	NpLang: {
		English: "EN",
		Korean: "KO",
		Chinese: "CN",
		SYSTEM: "@SYSTEM"
	},

	CurrencyCode: {
		ChineseYuan: "CNY",
		KoreanWon: "KRW",
		UnitedStatesDollar: "USD",
		SYSTEM: "@SYSTEM"
	},

	SkinType: {
		Red: "red",
		Green: "green",
		Purple: "purple",
		Gray: "gray",
		Dark: "dark"
	},

	Color: ((r, g, b) => (new Color__(r, g, b)))
}

class Color__ {
	constructor(red, green, blue) {
		this.red = red
		this.green = green
		this.blue = blue
	}

	get hex() {
		return `#${Object.values(Object.assign({}, this)).map(val => val.toString(16).padStart(2, '0')).join('')}`
	}
}

const colorProcess = (c, defaultValue) => {
	if (c instanceof Color__)
		return c.hex
	if (typeof c === 'string')
		switch (c) {
			case Nicepay.SkinType.Red:
				return "#a61001"
			case Nicepay.SkinType.Green:
				return "#015811"
			case Nicepay.SkinType.Purple:
				return "#4e3789"
			case Nicepay.SkinType.Dark:
			case Nicepay.SkinType.Gray:
				return "#0054a6"
			default:
				return c
		}
	if (c instanceof Object && new Color__(c.red, c.green, c.blue) instanceof Color__)
		return new Color__(c.red, c.green, c.blue).hex
	return defaultValue
}

var requestPayment = function (data, options, onSuccess, onFail) {

	var successCallback = function (message) {
		if (onSuccess instanceof Function) {
			onSuccess(JSON.parse(message))
		}
	}

	var failureCallback = function (message) {
		if (onSuccess instanceof Function) {
			onFail(JSON.parse(message))
		}
	}

	exec(
		successCallback,
		failureCallback,
		'NicepayCordova',
		'setup',
		[data, options]
	)
}

exports.payment = function (params) {
	let data = params.data || {}
	let options = params.options || {}

	data.PayMethod = data.PayMethod ? (Array.isArray(data.PayMethod) ? data.PayMethod.join(",") : String(data.PayMethod)) : "CARD"
	data.QuotaInterest = data.QuotaInterest ? (typeof data.QuotaInterest === 'object' ? Object.keys(data.QuotaInterest).map(key => key + ":" + data.QuotaInterest[key].map(value => value.toString().padStart(2, "0")).join(",")).join("|") : data.QuotaInterest) : undefined
	data.CharSet = (data.CharSet || "utf-8").toLowerCase()
	data.NpLang =  (data.NpLang || "KO").toUpperCase()
	data.CurrencyCode = (data.CurrencyCode || "KRW").toUpperCase()

	options.buttonColor = colorProcess(options.buttonColor, new Color__(0, 0, 0).hex)
	options.titleColor = colorProcess(options.titleColor, new Color__(0, 0, 0).hex)
	options.backgroundColor = colorProcess(options.backgroundColor, new Color__(255, 255, 255).hex)

	requestPayment(data, options, params.onSuccess, params.onFail)
}