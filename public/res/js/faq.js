$('h4.faq-question > a').click(function(e) {
    e.preventDefault();
    var self = $(this);
    var faq_answer = self.parent().parent().children('.faq-answer');
    if (faq_answer.length > 0) {
        if (faq_answer.is(':visible')) {
            faq_answer.hide();
        } else {
            faq_answer.show();
            window.location.href = '#' + this.id
        }
    } else {
        getFAQFromServer(self[0].id.slice(4), function(d) {
            if (!d.error) {
                var answer = $('<p>', { 'class': 'faq-answer', 'html': d.answer });
                answer.insertAfter(self.parent());
                window.location.href = '#' + self[0].id
            }
        });
    }
});

function getFAQFromServer(answer_id, cb) {
    if (cb) {
        $.getJSON('/api/faq', { answer_id: answer_id }).done(function(d) {
            cb(d);
        });
    }
}