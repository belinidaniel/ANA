({
    doInit: function () {
        var skipLinksActivated = false;

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Tab') {
                var skipLinks = document.querySelectorAll('.skip-link');
                var firstSkipLink = skipLinks[0];
                var secondSkipLink = skipLinks[1];

                if (!skipLinksActivated) {
                    event.preventDefault();

                    if (document.activeElement === firstSkipLink) {
                        firstSkipLink.classList.remove('show');
                        secondSkipLink.classList.add('show');
                        secondSkipLink.focus();
                    } else if (document.activeElement === secondSkipLink) {
                        secondSkipLink.classList.remove('show');
                        firstSkipLink.classList.remove('show');
                        skipLinksActivated = true;
                    } else {
                        firstSkipLink.classList.add('show');
                        firstSkipLink.focus();
                    }
                }
            }
        });

        document.addEventListener('click', function () {
            var skipLinks = document.querySelectorAll('.skip-link');
            skipLinks.forEach(function (link) {
                link.classList.remove('show');
            });

            skipLinksActivated = false;
        });
    }
});