function calculateRemains(){
    wfcur = parseInt(document.getElementById("wfremamount")
		     .innerText.replace(/,/g, ''));
    ptcur = parseInt(document.getElementById("ptremamount")
		     .innerText.replace(/,/g, ''));
    amount_str = document.getElementById("amounts").value
	             .replace(/,/g, '');
    points_str = document.getElementById("points").value
	             .replace(/,/g, '');

    if (amount_str == '') amount_str = '0';
    if (points_str == '') points_str = '0';

    amount = parseInt(amount_str);
    points = parseInt(points_str);

    if ( !isNaN(amount) && !isNaN(points) ){
	if ( !isNaN(wfcur) ){ // calc wfamountafter
	    wfafter = wfcur + amount - points;
	    document.getElementById("wfamountafter").innerHTML =
		String(wfafter).replace(/[^\d-]/g, '')
		  .replace(/(\d)(?=(\d{3})+$)/g, '$1,');
	}
	if ( !isNaN(ptcur) ){ // calc ptamountafter
	    ptafter = ptcur - amount + points;
	    document.getElementById("ptamountafter").innerHTML =
		String(ptafter).replace(/[^\d-]/g, '')
		  .replace(/(\d)(?=(\d{3})+$)/g, '$1,');
	}
    }
}

function onfocusAmounts(){
    document.getElementById("amounts").value =
        document.getElementById("amounts").value.replace(/,/g, '');
}

function onblurAmounts(){
    amounts = document.getElementById("amounts").value;
    document.getElementById("amounts").value =
        amounts.replace(/[^\d-]/g, '').replace(/(\d)(?=(\d{3})+$)/g, '$1,');

    calculateRemains();
}

function onfocusPoints(){
    document.getElementById("points").value =
        document.getElementById("points").value.replace(/,/g, '');
}

function onblurPoints(){
    points = document.getElementById("points").value;
    document.getElementById("points").value =
        points.replace(/[^\d-]/g, '').replace(/(\d)(?=(\d{3})+$)/g, '$1,');

    calculateRemains();
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
    document.getElementById("paccrem").style.display =
	(wpkw.checked == true || wpkt.checked == true ?
	 "inline" : "none");

    document.getElementById("wacc").style.display =
	(wpkp.checked == true || wpkt.checked == true ?
	 "inline" : "none");
    document.getElementById("waccrem").style.display =
	(wpkp.checked == true || wpkt.checked == true ?
	 "inline" : "none");
}

function onChangeWFrom(){
    var aid = this.options[this.selectedIndex].value;
    refreshRemAmount(aid, "wfremamount");
}

function onChangePTo(){
    var aid = this.options[this.selectedIndex].value;
    refreshRemAmount(aid, "ptremamount");
}

function refreshRemAmount(aid, rem_elm_id){

    var apiUrl = document.getElementById("apiUrl").value;
    var data = { 'aid': aid };
    fetch(apiUrl, {
	method: "put",
	body: Object.keys(data).map((key)=>key+"="+
				    encodeURIComponent(data[key])).join("&")
    }).then(
	res => res.json()
    ).then(
	json => -json.amount
    ).then(
        amount => document.getElementById(rem_elm_id).innerHTML =
	    String(amount).replace(/[^\d-]/g,
				   '').replace(/(\d)(?=(\d{3})+$)/g,
					       '$1,')
    );
}

function init(){
    document.getElementById("wpkw").onchange = onchgKinds;
    document.getElementById("wpkp").onchange = onchgKinds;
    document.getElementById("wpkt").onchange = onchgKinds;

    document.getElementById("amounts").onfocus = onfocusAmounts;
    document.getElementById("amounts").onblur = onblurAmounts;
    document.getElementById("points").onfocus = onfocusPoints;
    document.getElementById("points").onblur = onblurPoints;

    document.getElementById("withdrawFrom").onchange = onChangeWFrom;
    document.getElementById("paymentTo").onchange = onChangePTo;

    document.getElementById("wpkp").checked = true;
    onchgKinds();
}

init();
