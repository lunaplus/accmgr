window.addEventListener("DOMContentLoaded", () => {
    var _UA = navigator.userAgent;
    var s = document.createElement("script");
    s.type = "text/javascript";
    if (_UA.search('iPhone') > -1){
	s.src = "../js/main_legacy.js?v=" + Date.now();
    } else {
	s.src = "../js/main_edge.js?v=" + Date.now();
    }

    document.getElementsByTagName("head")[0].appendChild(s);
}, false);
