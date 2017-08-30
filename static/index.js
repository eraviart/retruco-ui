
// pull in desired CSS/SASS files
// Note: index.scss is already imported by bootstrap-loader (see .bootstraprc).
// require('./css/index.scss');


// User prefered language (http://stackoverflow.com/a/38150585/3548266)

var language = navigator.languages && navigator.languages[0] || // Chrome / Firefox
               navigator.language ||   // All browsers
               navigator.userLanguage; // IE <= 10


// Authentication

var authenticationStr = window.localStorage.getItem('authentication');
var authentication = authenticationStr ? JSON.parse(authenticationStr) : null;


// inject bundled Elm app into div#main

var Elm = require('../src/Main');
var flags = {
    authentication: authentication,
    language: language
};
var main = Elm.Main.embed(document.getElementById('main'), flags);



// Ports


// From https://www.paramander.com/blog/using-ports-to-deal-with-files-in-elm-0-17
main.ports.fileSelected.subscribe(function (id) {
    var node = document.getElementById(id);
    if (node === null) {
        return;
    }

    // If your file upload field allows multiple files, you might
    // want to consider turning this into a `for` loop.
    var file = node.files[0];
    var reader = new FileReader();

    // FileReader API is event based. Once a file is selected
    // it fires events. We hook into the `onload` event for our reader.
    reader.onload = (function (event) {
        // The event carries the `target`. The `target` is the file
        // that was selected. The result is base64 encoded contents of the file.
        var base64encoded = event.target.result;
        // We build up the `ImagePortData` object here that will be passed to our Elm
        // runtime through the `fileContentRead` subscription.
        var portData = {
            contents: base64encoded,
            filename: file.name
        };

        // We call the `fileContentRead` port with the file data
        // which will be sent to our Elm runtime via Subscriptions.
        main.ports.fileContentRead.send(portData);
    });

    // Connect our FileReader with the file that was selected in our `input` node.
    reader.readAsDataURL(file);
});


main.ports.setDocumentMetatags.subscribe(function (metatags) {
    if (metatags.hasOwnProperty('description')) {
        var element = document.head.querySelector('meta[property="og:description"]');
        if (element) {
            element.setAttribute('content', metatags.description);
        }
    }

    if (metatags.hasOwnProperty('imageUrl')) {
        var element = document.head.querySelector('meta[property="og:image"]');
        if (element) {
            element.setAttribute('content', metatags.imageUrl);
        }
    }

    if (metatags.hasOwnProperty('title')) {
        var element = document.head.querySelector('meta[property="og:title"]');
        if (element) {
            element.setAttribute('content', metatags.title);
        }

        var elements = document.head.getElementsByTagName('title');
        if (elements.length) {
            var element = elements[0];
            element.innerText = metatags.title;
        }
    }

    var element = document.head.querySelector('meta[property="og:url"]');
    if (element) {
        element.setAttribute('content', window.location.href);
    }

    if (metatags.hasOwnProperty('twitterName')) {
        var element = document.head.querySelector('meta[property="twitter:site"]');
        if (element) {
            element.setAttribute('content', metatags.twitterName);
        }
    }
});


main.ports.shareOnFacebook.subscribe(function (url) {
    var height = 350,
        width = 520,
        winHeight = screen.height,
        winWidth = screen.width;
    var left = Math.round((winWidth / 2) - (width / 2)),
        top = 0;
    if (winHeight > height) {
        top = Math.round((winHeight / 2) - (height / 2));
    }
    window.open(url, 'facebook', 'status=no,toolbar=no,resizable=yes,scrollbars=yes,width=' + width +
        ',height=' + height + ',left=' + left + ',top=' + top);
});


main.ports.shareOnGooglePlus.subscribe(function (url) {
    var height = 600,
        width = 600,
        winHeight = screen.height,
        winWidth = screen.width;
    var left = Math.round((winWidth / 2) - (width / 2)),
        top = 0;
    if (winHeight > height) {
        top = Math.round((winHeight / 2) - (height / 2));
    }
    window.open(url, 'google+', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,width=' + width +
        ',height=' + height + ',left=' + left + ',top=' + top);
});


main.ports.shareOnLinkedIn.subscribe(function (url) {
    var height = 570,
        width = 520,
        winHeight = screen.height,
        winWidth = screen.width;
    var left = Math.round((winWidth / 2) - (width / 2)),
        top = 0;
    if (winHeight > height) {
        top = Math.round((winHeight / 2) - (height / 2));
    }
    window.open(url, 'linkedin', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,width=' + width +
        ',height=' + height + ',left=' + left + ',top=' + top);
});

main.ports.shareOnTwitter.subscribe(function (url) {
    var height = 420,
        width = 550,
        winHeight = screen.height,
        winWidth = screen.width;
    var left = Math.round((winWidth / 2) - (width / 2)),
        top = 0;
    if (winHeight > height) {
        top = Math.round((winHeight / 2) - (height / 2));
    }
    window.open(url, 'twitter', 'scrollbars=yes,resizable=yes,toolbar=no,location=yes,width=' + width +
        ',height=' + height + ',left=' + left + ',top=' + top);
});


main.ports.storeAuthentication.subscribe(function (authentication) {
    if (authentication) {
        window.localStorage.setItem('authentication', JSON.stringify(authentication, null, 2));
    } else {
        window.localStorage.removeItem('authentication');
    }
});
