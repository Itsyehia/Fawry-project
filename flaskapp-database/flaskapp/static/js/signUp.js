$(function() {
    $('#btnSignUp').click(function() {
        $.ajax({
            url: FLASK_URLS.signUp,
            type: 'POST',
            data: $('form').serialize(),
            success: function(response) {
                console.log(response);
                try {
                    var responseObj = JSON.parse(response);
                    if (responseObj.message) {
                        alert('Success: ' + responseObj.message);
                        window.location.href = FLASK_URLS.showSignIn;
                    } else if (responseObj.error) {
                        alert('Error: ' + responseObj.error);
                    }
                } catch (e) {
                    console.error('Failed to parse response:', e);
                    alert('Unexpected response from server.');
                }
            },
            error: function(error) {
                console.log(error);
                alert('An error occurred during sign up. Please try again.');
            }
        });
    });
});
