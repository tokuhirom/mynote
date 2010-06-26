$(function () {
    $('#SearchHistory').load('/search_history');
    $('.EditBtn').live('click', function () {
        var entry_id = $(this).attr('entry_id');
        $('#EditForm' + entry_id).toggle();
        return false;
    });
});
