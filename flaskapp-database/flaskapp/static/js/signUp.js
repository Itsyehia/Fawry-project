$(function() {
    $('#btnSignUp').click(function(e) {
        e.preventDefault(); // prevent normal form submit

        $.ajax({
            url: SIGNUP_URL,   // dynamically injected from template
            data: $('form').serialize(),
            type: 'POST',
            success: function(response) {
                console.log(response);
            },
            error: function(error) {
                console.log(error);
            }
        });
    });
});
