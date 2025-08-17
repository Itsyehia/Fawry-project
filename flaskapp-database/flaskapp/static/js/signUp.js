$(function() {
    $('#btnSignUp').click(function() {
        $.ajax({
            url: FLASK_URLS.signUp,
            type: 'POST',
            data: $('#signupForm').serialize(),
            success: function(response) {
                var res = JSON.parse(response);
                if (res.message) {
                    alert(res.message);
                    window.location.href = FLASK_URLS.showSignIn;
                } else {
                    alert(res.error);
                }
            },
            error: function(error) {
                console.error(error);
                alert('Signup failed, try again.');
            }
        });
    });
});
