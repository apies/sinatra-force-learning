class AuthView extends Backbone.View

	el: '#auth_form'
	tagName: 'form'

	initialize: ->
		@

	authTest: (event) ->
		event.preventDefault()
		console.log 'auth test!!!'
		username = $('#username').val()
		password = $('#password').val()
		console.log "#{username}:#{password}"
	salesforceAuth: () ->
		
	events:
		'click #go_button' : 'authTest'
		'click #salesforce_auth' : 'salesforceAuth'


$(document).ready ->
	@app = window.app ? {}
	@app.authView = new AuthView()

	