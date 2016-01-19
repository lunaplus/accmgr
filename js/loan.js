var CHKDONE = "chkdone"
var SELYEAR = "selyear"
var SELMONTH = "selmonth"
var HIDMAXSID = "hidMaxSid"
var LIQUIDATION = "liquidation"

function onchkChkDone(){
    var chkdone = (document.getElementById(CHKDONE).checked != true);

    document.getElementById(SELYEAR).disabled = chkdone;
    document.getElementById(SELMONTH).disabled = chkdone;
}

function onLiq(){
    return confirm('表示されている立替えを清算しますか？');
}

function init(){
    document.getElementById(CHKDONE).onchange = onchkChkDone;

    var liq = document.getElementById(LIQUIDATION);
    liq.disabled =
	(document.getElementById(HIDMAXSID).value == 0);
    liq.onclick = onLiq;

    onchkChkDone();
}

window.addEventListener("DOMContentLoaded", init, false);
