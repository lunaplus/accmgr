function onfocusAmounts(){
    document.getElementById("amounts").value =
        document.getElementById("amounts").value.replace(/,/g, '');
}

function onblurAmounts(){
    document.getElementById("amounts").value =
        document.getElementById("amounts").value
          .replace(/[^\d-]/g, '')
          .replace(/(\d)(?=(\d{3})+$)/g, '$1,');
}

function onchgKinds(){
    var wpkw = document.getElementById("wpkw")
    var wpkp = document.getElementById("wpkp")
    var wpkt = document.getElementById("wpkt")

    // Expenditure
    document.getElementById("expin").style.display =
	(wpkw.checked == true ? "inline" : "none");
    document.getElementById("expout").style.display =
	(wpkp.checked == true ? "inline" : "none");
    document.getElementById("expmv").style.display =
	(wpkt.checked == true ? "inline" : "none");

    // withdraw-payment Accounts
    document.getElementById("pacc").style.display =
	(wpkw.checked == true || wpkt.checked == true ?
	 "inline" : "none");
    document.getElementById("wacc").style.display =
	(wpkp.checked == true || wpkt.checked == true ?
	 "inline" : "none");

    document.getElementById("paccrem").style.display = "none";
    document.getElementById("waccrem").style.display = "none";
}

function init(){
    document.getElementById("wpkw").onchange = onchgKinds;
    document.getElementById("wpkp").onchange = onchgKinds;
    document.getElementById("wpkt").onchange = onchgKinds;

    document.getElementById("amounts").onfocus = onfocusAmounts;
    document.getElementById("amounts").onblur = onblurAmounts;

    document.getElementById("wpkp").checked = true;
    onchgKinds();
}

init();
