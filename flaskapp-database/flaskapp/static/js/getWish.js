$(function() {
    $.ajax({
        url: FLASK_URLS.getWish,
        type: 'GET',
        success: function(res) {
            try {
                var wishObj = JSON.parse(res);
                var divTemplate = $('<div>')
                    .attr('class', 'list-group')
                    .append($('<a>')
                        .attr('class', 'list-group-item active')
                        .append($('<h4>').attr('class', 'list-group-item-heading'))
                        .append($('<p>').attr('class', 'list-group-item-text'))
                    );

                $.each(wishObj, function(index, value) {
                    var wish = divTemplate.clone();
                    $(wish).find('h4').text(value.Title);
                    $(wish).find('p').text(value.Description);
                    $('.jumbotron').append(wish);
                });
            } catch (e) {
                console.error('Failed to parse wishes:', e);
                alert('Failed to load wishes. Please refresh the page.');
            }
        },
        error: function(error) {
            console.log(error);
            alert('Failed to load wishes. Please refresh the page.');
        }
    });
});
