define('./a', ['backbone'], function (require) {
	console.log('a')
	console.log('require backbone for a' + require('backbone'))
})