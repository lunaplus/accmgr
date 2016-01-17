function onchangeCheck(){
    var flg = (document.getElementById("chkloanflg").checked == true);

    document.getElementById("selyear").disabled = flg;
    document.getElementById("selmonth").disabled = flg;
    document.getElementById("selowner").disabled = flg;
    document.getElementById("selaccount").disabled = flg;
    document.getElementById("selexpenditure").disabled = flg;
}

function init(){
    document.getElementById("chkloanflg").onchange = onchangeCheck;
}

window.addEventListener("DOMContentLoaded", init, false);
