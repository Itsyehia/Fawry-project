$(function() {
	$('#btnSignUp').click(function() {
		$.ajax({
			url: FLASK_URLS.signUp,
			data: $('form').serialize(),
			type: 'POST',
			success: function(response) {
				console.log(response);
				var responseObj = JSON.parse(response);
				if (responseObj.message) {
					alert('Success: ' + responseObj.message);
					// Redirect to sign in page
					window.location.href = FLASK_URLS.showSignIn || '/showSignIn';
				} else if (responseObj.error) {
					alert('Error: ' + responseObj.error);
				}
			},
			error: function(error) {
				console.log(error);
				alert('An error occurred during sign up. Please try again.');
			}
		});
	});
});