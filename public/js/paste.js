window.onload = function() {

    var codeIn = document.getElementById("codeIn");

    if (codeIn) {
        window.onresize = function() {
            codeIn.style.height = (window.innerHeight - 40).toString() + "px";
        };
        window.onresize();
        codeIn.onkeydown = function(e) {
            var keyCode = e.keyCode || e.which;

            if (keyCode === 9) {
                e.preventDefault();
                var start = this.selectionStart;
                var end = this.selectionEnd;

                // set textarea value to: text before caret + tab + text after caret
                this.value = this.value.substring(0, start) +
                "    " +
                this.value.substring(end);

                // put caret at right position again
                this.selectionStart = this.selectionEnd = start + 1;
            }
        };
        codeIn.focus();
    }

    //Fetch the current paste from the URL
    function currentPaste() {
        var href = window.location.href;
        return href.substr(href.lastIndexOf("/") + 1);
    }

    //Adds a click listener to the button with the given ID, only if
    //the button is not disabled
    function addClick(id, func) {
        var btn = document.getElementById(id);
        //Check button not disabled
        if (btn.classList.contains("button")) {
            btn.onclick = func;
        }
    }

    addClick("saveBtn", function() {
        var code = codeIn.value;
        if (code.length === 0) {
            return;
        }
        var req = new XMLHttpRequest();
        req.onload = function() {
            var res = req.responseText;
            if (req.status === 413) {
                alert(res);
            } else {
                console.log(res);
                window.location = "/" + res;
            }
        };
        req.open("POST", "/paste", true);
        req.send(code);
    });

    addClick("newBtn", function() {
        window.location = "/";
    });

    addClick("editBtn", function() {
        window.location = "/edit/" + currentPaste();
    });

    addClick("rawBtn", function() {
        window.location = "/raw/" + currentPaste();
    });
};
